
import void_tags from require "web_sanitize.data"
import open_tag, close_tag, html_comment, cdata from require "web_sanitize.patterns"

import P, C, Cs, Cmt, Cp from require "lpeg"

void_tags_set = {t, true for t in *void_tags}

local unescape_text

class NodeStack
  current: =>
    @[#@]

  _parse_query: (query) =>
    if @_query_cache
      if q = @_query_cache[query]
        return q
    else
      @_query_cache = {}

    import parse_query from require "web_sanitize.query.parse_query"
    q = assert parse_query query
    @_query_cache[query] = q
    q

  is: (query) =>
    import match_query from require "web_sanitize.query"
    match_query @, @_parse_query query

  select: (query) =>
    import parse_query from require "web_sanitize.query.parse_query"
    import match_query from require "web_sanitize.query"

    q = @_parse_query query

    stack = {}
    return for n in *@
      table.insert stack, n
      unless match_query stack, q
        continue
      n

class HTMLNode
  outer_html: =>
    assert @buffer, "missing buffer"
    assert @pos, "missing pos"
    assert @end_pos, "missing end_pos"
    @buffer\sub @pos, @end_pos - 1

  inner_html: =>
    assert @buffer, "missing buffer"
    assert @inner_pos, "missing inner_pos"
    assert @end_inner_pos, "missing end_inner_pos"
    @buffer\sub @inner_pos, @end_inner_pos - 1

  inner_text: =>
    import extract_text from require "web_sanitize"
    text = extract_text @inner_html!
    unescape_text\match(text) or text

  -- merge new attributes with existing ones
  update_attributes: (attrs) =>
    if @attr
      provided_attributes = {}

      for k, v in pairs attrs
        if type(v) == "table"
          provided_attributes[v[1]\lower!] = true
        elseif type(k) == "string"
          provided_attributes[k\lower!] = true

      update = {}
      -- copy existing ones
      for idx, tuple in ipairs @attr
        continue if provided_attributes[tuple[1]\lower!]
        table.insert update, tuple

      -- add new ones
      for k,v in pairs attrs
        if type(v) == "table"
          table.insert update, v
        elseif type(k) == "string"
          update[k] = v

      @replace_attributes update
    else
      @replace_attributes attrs

  replace_attributes: (attrs) =>
    import escape_text from require "web_sanitize.html"

    buff = {"<", @tag}
    i = #buff + 1

    push_attr = (name, value) ->
      buff[i] = " "
      buff[i + 1] = name

      if value == true
        i += 2
      else
        buff[i + 2] = '="'
        buff[i + 3] = escape_text\match value
        buff[i + 4] = '"'
        i += 5

    -- add ordered attributes first
    for {k, v} in *attrs
      push_attr k, v

    -- add the rest
    for k,v in pairs attrs
      continue unless type(k) == "string"
      continue unless v
      push_attr k,v

    if @self_closing
      buff[i] = " />"
    else
      buff[i] = ">"

    table.insert @changes, {@pos, @inner_pos or @end_pos, table.concat buff}

  replace_inner_html: (replacement) =>
    unless @changes
      error "attempting to change buffer with no changes array"

    table.insert @changes, {@inner_pos, @end_inner_pos, replacement}

  replace_outer_html: (replacement) =>
    unless @changes
      error "attempting to change buffer with no changes array"

    table.insert @changes, {@pos, @end_pos, replacement}



-- this is far from comprehensive
-- TODO: use html_named_entities database
unescape_char = P"&gt;" / ">" +
  P"&lt;" / "<" +
  P"&amp;" / "&" +
  P"&nbsp;" / " " +
  P"&#x27;" / "'" +
  P"&#x2F;" / "/" +
  P"&quot;" / '"'

unescape_text = Cs (unescape_char + 1)^1

scan_html = (html_text, callback, opts) ->
  assert callback, "missing callback to scan_html"
  changes = {}

  class BufferHTMLNode extends HTMLNode
    changes: changes
    buffer: html_text

  root_node = {}
  tag_stack = NodeStack!

  -- Cmt callback for opening tag
  push_tag = (str, pos, node) ->
    top = tag_stack[#tag_stack] or root_node
    top.num_children = (top.num_children or 0) + 1

    node.tag = node.tag\lower! -- normalize tag name
    node.num = top.num_children -- mark the nth position

    -- format attributes:
    --  * unescape value
    --  * add normalized key value mapping
    if node.attr
      for _, tuple in ipairs node.attr
        if tuple[2]
          tuple[2] = unescape_text\match(tuple[2]) or tuple[2]

        node.attr[tuple[1]\lower!] = tuple[2] or true

    setmetatable node, BufferHTMLNode.__base
    table.insert tag_stack, node

    -- handle void/self closing tags
    if void_tags_set[node.tag] or node.self_closing
      node.end_pos = node.inner_pos
      node.end_inner_pos = node.inner_pos

      callback tag_stack
      table.remove tag_stack

    true

  pop_tag = (str, end_pos, end_inner_pos, tag) ->
    stack_size = #tag_stack

    tag = tag\lower!

    if stack_size == 0
      -- too many closes, ignore
      return true

    if tag != tag_stack[stack_size].tag
      -- tag mismatch, attempt to fix
      found_tag = false
      for k=#tag_stack - 1,1,-1
        if tag_stack[k].tag == tag
          found_tag = true

        break

      return true unless found_tag -- just skip it

    -- pop until we've consumed the tag
    for k=stack_size,1,-1
      popping = tag_stack[k]

      popping.end_inner_pos = end_inner_pos

      popping.end_pos = if popping.tag == tag
        end_pos
      else
        end_inner_pos

      callback tag_stack
      tag_stack[k] = nil
      break if popping.tag == tag

    true

  -- this clears the stack of any left over tags for when wwe've reached the
  -- end of the document
  check_dangling_tags = (str, pos) ->
    k = #tag_stack
    while k > 0
      popping = tag_stack[k]
      popping.end_pos = pos
      popping.end_inner_pos = pos
      callback tag_stack
      tag_stack[k] = nil
      k -= 1

    true


  check_open_tag = Cmt open_tag, push_tag
  check_close_tag = Cmt close_tag, pop_tag

  text = P"<" + P(1 - P"<")^1

  if opts and opts.text_nodes == true
    text = Cmt Cp! * C(text), (str, end_pos, start_pos, text_content) ->
      top = tag_stack[#tag_stack] or root_node
      top.num_children = (top.num_children or 0) + 1

      text_node = {
        type: "text_node"
        tag: ""

        pos: start_pos
        inner_pos: start_pos

        end_pos: end_pos
        end_inner_pos: end_pos

        num: top.num_children
      }

      setmetatable text_node, BufferHTMLNode.__base
      table.insert tag_stack, text_node
      callback tag_stack
      table.remove tag_stack
      true

  html = (html_comment + cdata + check_open_tag + check_close_tag + text)^0 * -1 * Cmt(Cp!, check_dangling_tags)
  res, err = html\match html_text

  res

replace_html = (html_text, _callback, opts) ->
  changes = {}

  callback = (tags, ...) ->
    current = tags[#tags]
    current.__class.__base.changes = changes
    _callback tags, ...

  scan_html html_text, callback, opts

  buffer = html_text
  for i, {min, max, sub} in ipairs changes
    continue if min > max
    buffer = buffer\sub(1, min - 1) .. sub .. buffer\sub(max)

    if #sub == max - min
      continue

    -- update all the other changes
    for k=i+1,#changes
      other_change = changes[k]
      delta = #sub - (max - min)

      if min < other_change[1]
        other_change[1] += delta

      if min < other_change[2]
        other_change[2] += delta

  buffer

{ :scan_html, :replace_html }
