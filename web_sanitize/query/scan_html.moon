
import void_tags, optional_tags from require "web_sanitize.data"
import open_tag, close_tag, html_comment, cdata, close_follows, unescape_html_text, escape_html_text, begin_raw_text_tag, alphanum from require "web_sanitize.patterns"

import P, C, Cc, Cs, Cmt, Cp from require "lpeg"

-- any character, including a < that doesn't start a tag, followed by text up
-- to the next <, so the scan always reaches the end of the input
match_text = P(1) * P(1 - P"<")^0

void_tags_set = {t, true for t in *void_tags}

-- edits made after replace_outer_html or unwrap would land inside text that
-- was already replaced
assert_editable = (node, method) ->
  if node._tags_replaced
    error "#{method}: can't edit a node after replace_outer_html or unwrap"

class NodeStack
  new: =>
    @_tag_positions = {}

  push: (node) =>
    idx = #@ + 1
    @[idx] = node

    positions = @_tag_positions[node.tag]
    unless positions
      positions = {}
      @_tag_positions[node.tag] = positions

    positions[#positions + 1] = idx

  pop: =>
    idx = #@
    node = @[idx]
    positions = @_tag_positions[node.tag]
    positions[#positions] = nil
    @[idx] = nil
    node

  has_tag: (tag) =>
    positions = @_tag_positions[tag]
    positions != nil and positions[1] != nil

  current: =>
    @[#@]

  _parse_query: (query) =>
    if @_query_cache
      if q = @_query_cache[query]
        return q
    else
      @_query_cache = {}

    import parse_query from require "web_sanitize.query.parse_query"
    q = assert parse_query(query), "Failed to parse query: #{query}"
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

-- nodes passed to replace_html callbacks, which record edits into the changes
-- table of the subclass replace_html creates
class EditableHTMLNode extends HTMLNode
  -- merge new attributes with existing ones
  update_attributes: (attrs) =>
    assert_editable @, "update_attributes"
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
    assert_editable @, "replace_attributes"
    assert @type != "text_node", "replace_attributes: text nodes have no attributes"

    buff = {"<", @tag}
    i = #buff + 1

    push_attr = (name, value) ->
      buff[i] = " "
      buff[i + 1] = name

      -- a tuple without a value, like {"disabled"}, is a boolean attribute
      if value == true or value == nil
        i += 2
      else
        buff[i + 2] = '="'
        buff[i + 3] = escape_html_text\match value
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
    assert_editable @, "replace_inner_html"
    unless @end_inner_pos
      error "replace_inner_html: element is still open, replace its HTML from its own callback"

    table.insert @changes, {@inner_pos, @end_inner_pos, replacement}

  replace_outer_html: (replacement) =>
    unless @end_pos
      error "replace_outer_html: element is still open, replace its HTML from its own callback"

    assert_editable @, "replace_outer_html"
    @_tags_replaced = true
    table.insert @changes, {@pos, @end_pos, replacement}

  -- Removes the opening and closing tags as separate edits, so edits made to
  -- the children in their own callbacks are kept
  unwrap: =>
    if @type == "text_node"
      error "unwrap: text nodes have no tags"

    unless @end_pos
      error "unwrap: element is still open, unwrap it from its own callback"

    assert_editable @, "unwrap"
    @_tags_replaced = true

    -- the closing tag range is empty when the source has none
    table.insert @changes, {@pos, @inner_pos, ""}
    table.insert @changes, {@end_inner_pos, @end_pos, ""}

-- the optional tags that opening each tag closes, the reverse of optional_tags
closes_optional = {}
for tag, closers in pairs optional_tags
  for closer in *(closers == true and {tag} or closers)
    closes_optional[closer] or= {}
    table.insert closes_optional[closer], tag

scan = (html_text, callback, opts, NodeClass) ->
  assert callback, "missing callback to scan_html"

  class BufferHTMLNode extends NodeClass
    buffer: html_text

  root_node = {}
  tag_stack = NodeStack!

  local pop_tag, last_opened

  -- stack index where the run of consecutive optional elements ending at each
  -- index starts, false for elements that aren't optional
  optional_run_start = {}

  -- An opening tag closes the top element if it closes any optional element in
  -- the run of them at the top of the stack, since closing that one closes the
  -- ones above it
  can_auto_close = (node) ->
    start = optional_run_start[#tag_stack]
    closes = start and closes_optional[node.tag]
    return false unless closes

    for tag in *closes
      positions = tag_stack._tag_positions[tag]
      last = positions and positions[#positions]
      return true if last and last >= start

    false

  -- Cmt callback for opening tag
  push_tag = (str, pos, node) ->
    node.tag = node.tag\lower! -- normalize tag name

    -- handle automatic closing for optional tags
    -- will treat parent tag as a sibling and immediately close it before pushing new tag
    while can_auto_close node
      -- pop the top by simulating encountering closing tag
      assert pop_tag(str, node.pos, node.pos, tag_stack[#tag_stack].tag),
        "tag stack out of sync, node properties are read-only"

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
    tag_stack\push node
    last_opened = node

    idx = #tag_stack
    optional_run_start[idx] = optional_tags[node.tag] and (optional_run_start[idx - 1] or idx)

    -- handle void/self closing tags
    if void_tags_set[node.tag] or node.self_closing
      node.end_pos = node.inner_pos
      node.end_inner_pos = node.inner_pos

      callback tag_stack
      tag_stack\pop!

    true

  pop_tag = (str, end_pos, end_inner_pos, tag) ->
    tag = tag\lower!

    -- closing tag for something that isn't open, fail and let text capture it
    return false unless tag_stack\has_tag tag

    -- pop until we've consumed the tag
    for k=#tag_stack,1,-1
      popping = tag_stack[k]

      popping.end_inner_pos = end_inner_pos

      popping.end_pos = if popping.tag == tag
        end_pos
      else
        end_inner_pos

      callback tag_stack
      tag_stack\pop!
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

    -- text nodes are never an ancestor or closed by a tag, so they bypass the
    -- tag index
    idx = #tag_stack + 1
    tag_stack[idx] = text_node
    callback tag_stack
    tag_stack[idx] = nil
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
      tag_stack\pop!
      k -= 1

    true

  check_open_tag = Cmt open_tag, push_tag
  check_close_tag = Cmt close_tag, pop_tag

  text_node = match_text
  cdata_guard = close_follows "<![CDATA[", "]]>"
  cdata_node = cdata_guard * cdata

  if opts and opts.text_nodes == true
    text_node = Cmt Cp! * C(match_text), push_text_node
    cdata_node = cdata_guard * Cmt Cp! * C(cdata) * Cc("cdata"), push_text_node

  -- a raw text tag takes text as is unless there is signal for closing tag (script, style, etc.)
  raw_text_closer = P"</" * Cmt C(alphanum^1), (_, pos, tag) ->
    tag_stack[#tag_stack].tag == tag\lower!

  -- a self closing raw text tag is already closed, so what follows is parsed
  -- as markup
  raw_text_open = Cmt P(0), -> tag_stack[#tag_stack] == last_opened

  raw_text_tag = #begin_raw_text_tag * check_open_tag * (raw_text_open * (P(1) - raw_text_closer)^0 * (check_close_tag + P(-1)))^-1

  html = (html_comment + cdata_node + raw_text_tag + check_open_tag + check_close_tag + text_node)^0 * -1 * Cmt(Cp!, check_dangling_tags)
  res, _ = html\match html_text

  -- a failed match leaves elements without callbacks, and replace_html would
  -- apply only the edits made before it
  unless res
    error "scan_html: failed to scan the whole input"

  res

-- Applies the edits recorded by replace_html in order, where a later edit
-- covering earlier ones replaces them. Returns nil when an edit is inverted,
-- out of bounds, or has an endpoint inside text an earlier edit replaced
apply_changes = (buffer, changes) ->
  max_pos = #buffer + 1
  positions = {}
  for {a, b} in *changes
    return nil if a > b or a < 1 or b > max_pos
    positions[a] = true
    positions[b] = true

  sorted = [p for p in pairs positions]
  table.sort sorted

  -- the list alternates gaps with non-empty text, so distinct gaps are
  -- always at distinct offsets. Gaps are the nodes without text
  gaps = {}
  head = { text: buffer\sub 1, (sorted[1] or max_pos) - 1 }
  tail = head
  for i, p in ipairs sorted
    gap = {}
    tail.next = gap
    gaps[p] = gap
    text = { text: buffer\sub p, (sorted[i + 1] or max_pos) - 1 }
    gap.next = text
    tail = text

  find = (gap) ->
    while gap.merged
      gap.merged = gap.merged.merged or gap.merged
      gap = gap.merged
    gap

  for {a, b, sub} in *changes
    left = find gaps[a]
    right = find gaps[b]
    return nil if left.removed or right.removed

    if left == right
      continue if sub == ""
      left.next = { text: sub, next: left.next }
    else
      node = left.next
      while node != right
        node.removed = true unless node.text
        node = node.next

      if sub == ""
        -- both gaps are now the same place in the output
        right.merged = left
        left.next = right.next
      else
        left.next = { text: sub, next: right }

  buff = {}
  node = head
  while node
    buff[#buff + 1] = node.text if node.text
    node = node.next

  table.concat buff

scan_html = (html_text, callback, opts) ->
  scan html_text, callback, opts, HTMLNode

replace_html = (html_text, callback, opts) ->
  changes = {}

  class ChangesHTMLNode extends EditableHTMLNode
    changes: changes

  scan html_text, callback, opts, ChangesHTMLNode

  apply_changes(html_text, changes) or
    error "replace_html: an edit overlaps text replaced by an earlier edit, only edit the current node from its own callback"

{ :scan_html, :replace_html, _apply_changes: apply_changes }
