
import void_tags, optional_tags  from require "web_sanitize.data"
import open_tag, close_tag, html_comment, cdata, unescape_html_text, bein_raw_text_tag, alphanum from require "web_sanitize.patterns"

import P, C, Cc, Cs, Cmt, Cp from require "lpeg"

match_text = P"<"^-1 * P(1 - P"<")^1

void_tags_set = {t, true for t in *void_tags}

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
    unescape_html_text\match(text) or text

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
    unless @changes
      error "attempting to change buffer with no changes array"

    assert @type != "text_node", "replace_attributes: text nodes have no attributes"

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

-- can we auto close the parent when visiting current
can_auto_close = (tag_stack, stack_pos, current) ->
  parent = tag_stack[stack_pos]
  return false unless parent

  -- check if adjacent is autoclosing
  if ot_type = optional_tags[parent.tag]
    if ot_type == true
      -- they are the same tag
      if current.tag == parent.tag
        return true
    else -- ot should be array of tag names that can auto close
      for t in *ot_type
        if t == current.tag
          return true

    -- detect if parent if the last item in an element that will end up
    -- autoclosing, meaning we can also close parent
    can_auto_close tag_stack, stack_pos - 1, current

scan_html = (html_text, callback, opts) ->
  assert callback, "missing callback to scan_html"
  changes = {}

  class BufferHTMLNode extends HTMLNode
    changes: changes
    buffer: html_text

  root_node = {}
  tag_stack = NodeStack!

  local pop_tag

  -- Cmt callback for opening tag
  push_tag = (str, pos, node) ->
    node.tag = node.tag\lower! -- normalize tag name

    -- handle automatic closing for optional tags
    -- will treat parent tag as a sibling and immediately close it before pushing new tag
    while can_auto_close tag_stack, #tag_stack, node
      -- pop the top by simulating encountering closing tag
      pop_tag str, node.pos, node.pos, tag_stack[#tag_stack].tag

    parent = tag_stack[#tag_stack] or root_node
    parent.num_children = (parent.num_children or 0) + 1
    node.num = parent.num_children -- mark the nth position

    -- format attributes:
    --  * unescape value
    --  * add normalized key value mapping
    if node.attr
      for _, tuple in ipairs node.attr
        if tuple[2]
          tuple[2] = unescape_html_text\match(tuple[2]) or tuple[2]

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
      -- extra closing tag, fail and let text capture it
      return false

    -- when we have a closing tag for something that isn't on the stack
    if tag != tag_stack[stack_size].tag
      -- tag mismatch, attempt to fix
      found_tag = false

      for k=#tag_stack - 1,1,-1
        if tag_stack[k].tag == tag
          found_tag = true
          break

      unless found_tag -- fail and let text capture it
        return false

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

  push_text_node = (str, end_pos, start_pos, text_content, is_cdata) ->
    top = tag_stack[#tag_stack] or root_node
    top.num_children = (top.num_children or 0) + 1

    inner_pos = if is_cdata
      start_pos + 9 -- fixed length of cdata start
    else
      start_pos

    end_inner_pos = if is_cdata
      end_pos - 3 -- fixed length of cdata close
    else
      end_pos


    text_node = {
      type: "text_node"
      tag: is_cdata or ""

      pos: start_pos
      end_pos: end_pos

      :inner_pos
      :end_inner_pos

      num: top.num_children
    }

    setmetatable text_node, BufferHTMLNode.__base
    table.insert tag_stack, text_node
    callback tag_stack
    table.remove tag_stack
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

  text_node = match_text
  cdata_node = cdata

  if opts and opts.text_nodes == true
    text_node = Cmt Cp! * C(match_text), push_text_node
    cdata_node = Cmt Cp! * C(cdata) * Cc("cdata"), push_text_node

  -- a raw text tag takes text as is unless there is signal for closing tag (script, style, etc.)
  raw_text_closer = P"</" * Cmt C(alphanum^1), (_, pos, tag) ->
    if top = tag_stack[#tag_stack]
      top.tag\lower! == tag\lower!
    else
      error "somehow have empty tag stack when checking for closing raw text"

  raw_text_tag = #bein_raw_text_tag * check_open_tag * (P(1) - raw_text_closer)^0 * (check_close_tag + P(-1))

  html = (html_comment + cdata_node + raw_text_tag + check_open_tag + check_close_tag + text_node)^0 * -1 * Cmt(Cp!, check_dangling_tags)
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
