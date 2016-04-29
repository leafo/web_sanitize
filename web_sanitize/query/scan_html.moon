
import void_tags from require "web_sanitize.data"

local unescape_text, void_tags_set

class NodeStack
  current: =>
    @[#@]

  is: (query) =>
    import parse_query from require "web_sanitize.query.parse_query"
    import match_query from require "web_sanitize.query"
    q = assert parse_query query
    match_query @, q

  select: (query) =>
    import parse_query from require "web_sanitize.query.parse_query"
    import match_query from require "web_sanitize.query"

    q = assert parse_query query

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

    seen_attrs = {}

    -- add ordered attributes first
    for name in *attrs
      lower = name\lower!
      continue if seen_attrs[lower]
      value = attrs[lower]
      continue unless value
      push_attr name, value
      seen_attrs[lower] = true

    -- add the rest
    for k,v in pairs attrs
      continue unless type(k) == "string"
      continue unless v
      continue if seen_attrs[k]
      push_attr k,v

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

import R, S, V, P from require "lpeg"
import C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp from require "lpeg"

void_tags_set = {t, true for t in *void_tags}

-- this is far from comprehensive
unescape_char = P"&gt;" / ">" +
  P"&lt;" / "<" +
  P"&amp;" / "&" +
  P"&nbsp;" / " " +
  P"&#x27;" / "'" +
  P"&#x2F;" / "/" +
  P"&quot;" / '"'

unescape_text = Cs (unescape_char + 1)^1

alphanum = R "az", "AZ", "09"
num = R "09"
hex = R "09", "af", "AF"

valid_char = P"&" * (alphanum^1 + P"#" * (num^1 + S"xX" * hex^1)) + P";"

white = S" \t\n"^0
word = (alphanum + S"._-")^1

value = C(word) +
  P'"' * C((1 - P'"')^0) * P'"' +
  P"'" * C((1 - P"'")^0) * P"'"

attribute = C(word) * (white * P"=" * white * value)^-1

scan_html = (html_text, callback) ->
  assert callback, "missing callback to scan_html"
  changes = {}

  class BufferHTMLNode extends HTMLNode
    changes: changes
    buffer: html_text

  root_node = {}
  tag_stack = NodeStack!

  fail_tag = ->
    tag_stack[#tag_stack] = nil

  check_tag = (str, _, pos, tag) ->
    top = tag_stack[#tag_stack] or root_node
    top.num_children = (top.num_children or 0) + 1

    node = {
      tag: tag\lower!
      :pos
      num: top.num_children
    }

    setmetatable node, BufferHTMLNode.__base
    table.insert tag_stack, node
    true

  check_close_tag = (str, end_pos, end_inner_pos, tag) ->
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

  -- check for non-self-closing void tags
  check_void_tag = (str, pos) ->
    top = tag_stack[#tag_stack]

    if void_tags_set[top.tag]
      top.end_pos = pos
      callback tag_stack
      table.remove tag_stack
      true
    else
      false

  pop_void_tag = (str, pos, ...) ->
    top = tag_stack[#tag_stack]
    top.end_pos = pos

    callback tag_stack

    table.remove tag_stack
    true

  check_attribute = (str, pos, name, val) ->
    top = tag_stack[#tag_stack]
    top.attr or= {}

    top.attr[name\lower!] = if val
      unescape_text\match(val) or val
    else
      true

    table.insert top.attr, name
    true

  save_pos = (field) ->
    (str, pos) ->
      top = tag_stack[#tag_stack]
      top[field] = pos
      true

  open_tag = Cmt(Cp! * P"<" * white * C(word), check_tag) *
    (
      Cmt(white * attribute, check_attribute)^0 * white * (
        Cmt("/" * white * P">", pop_void_tag) +
        P">" * (
         Cmt("", check_void_tag) +
         Cmt("", save_pos "inner_pos")
       )
      ) +
      Cmt("", fail_tag)
    )

  close_tag = Cmt(Cp! * P"<" * white * P"/" * white * C(word) * white * P">", check_close_tag)

  html = (open_tag + close_tag + P"<" + P(1 - P"<")^1)^0 * -1 * Cmt(Cp!, check_dangling_tags)
  res, err = html\match html_text

  res

replace_html = (html_text, _callback) ->
  changes = {}

  callback = (tags, ...) ->
    current = tags[#tags]
    current.__class.__base.changes = changes
    _callback tags, ...

  scan_html html_text, callback

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
