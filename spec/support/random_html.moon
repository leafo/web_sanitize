-- Random input generators for spec/fuzz_spec.moon

pick = (list) -> list[math.random #list]

tags = {
  "div", "DIV", "span", "p", "P", "b", "i", "a", "A", "li", "ul", "table", "tr",
  "td", "option", "img", "br", "hr", "pre", "code", "script", "SCRIPT", "style",
  "title", "textarea", "iframe", "blink"
}

attributes = {
  ' href="http://x.example/"', " href='javascript:x'", ' class="c"',
  " class='c d'", ' id="i"', ' title="a&quot;b"', ' onclick="x()"', " disabled",
  " x=y", ' src="', " a='"
}

fragments = {
  "text", " ", "https://a.co", "&amp;", "&#x41;", "&bogus", "<", ">", "</",
  "< / >", "<!-- c -->", "<!--", "-->", "<!-->", "<![CDATA[x]]>", "<![CDATA[",
  "]]>", "<!DOCTYPE html>"
}

-- Malformed HTML: unbalanced, unclosed and stray tags, broken attributes, and
-- unterminated comments and CDATA
random_html = (size=30) ->
  out = for i=1,math.random 0, size
    r = math.random!
    if r < 0.3
      attrs = table.concat [pick attributes for _=1,math.random 0, 2]
      "<#{pick tags}#{attrs}>"
    elseif r < 0.5
      "</#{pick tags}>"
    elseif r < 0.55
      "<#{pick tags}#{math.random! < 0.5 and " " or ""}/>"
    else
      pick fragments

  table.concat out

selector_tags = {"div", "DIV", "span", "p", "b", "a", "li", "td", "pre", "code", "img"}

random_selector_part = ->
  parts = {}
  r = math.random!
  if r < 0.6
    table.insert parts, pick selector_tags
  elseif r < 0.7
    table.insert parts, "*"

  for i=1,math.random 0, 2
    table.insert parts, switch math.random 4
      when 1 then ".#{pick {"c", "d"}}"
      when 2 then "#i"
      when 3 then "[href]"
      else ":nth-child(#{math.random 1, 3})"

  if #parts == 0
    table.insert parts, pick selector_tags

  table.concat parts

random_selector = ->
  alternatives = for a=1,(math.random! < 0.2 and 2 or 1)
    table.concat [random_selector_part! for i=1,math.random 1, 4], " "

  table.concat alternatives, ", "

-- A selector built from the open elements on the stack, so that many of them
-- match. Adding a class makes the ancestor search skip elements.
random_stack_selector = (stack) ->
  parts = for idx, node in ipairs stack
    continue unless idx == #stack or math.random! < 0.4
    part = math.random! < 0.8 and node.tag or "*"
    part ..= ".c" if math.random! < 0.2
    part

  table.concat parts, " "

tree_tags = {"div", "span", "b", "em", "section", "DIV", "li"}
tree_edits = {
  "unwrap", "attributes", "inner", "outer", "none"
  "inner_attributes", "inner_twice", "inner_unwrap"
}

all_closed = (n) ->
  return true if n.text
  return false unless n.close
  for child in *n.children
    return false unless all_closed child
  true

-- A tree where each element and text node has an edit to apply. Some elements
-- leave out their closing tag where the scanner still builds the same tree: a
-- last child is closed by its parent's closing tag or the end of the input,
-- and an li by the li after it. A closing tag closes the nearest open element
-- with its name, so an element sharing a name with an ancestor keeps its
-- closing tag. Adjacent text nodes are avoided since they would parse as one.
random_tree = (depth=0, counter={n: 0}, ancestors={}, parent_is_li=false) ->
  children = {}
  for i=1,math.random 0, (depth < 5 and 4 or 0)
    counter.n += 1
    prev = children[#children]
    if math.random! < 0.4 and not (prev and prev.text)
      table.insert children, {
        text: "t#{counter.n}"
        edit: math.random! < 0.3 and "replace" or "none"
      }
    else
      tag = pick tree_tags
      -- an li opening directly inside an li closes it
      tag = "div" if parent_is_li and tag == "li"
      name = tag\lower!
      inner_ancestors = setmetatable { [name]: true }, __index: ancestors
      table.insert children, {
        :tag, :name
        id: "n#{counter.n}"
        edit: pick tree_edits
        close: true
        children: random_tree depth + 1, counter, inner_ancestors, name == "li"
      }

  for idx, n in ipairs children
    continue if n.text
    following = children[idx + 1]
    if idx == #children
      n.close = false if not ancestors[n.name] and math.random! < 0.3
    elseif n.name == "li" and following.name == "li" and not parent_is_li
      n.close = false if all_closed(n) and math.random! < 0.5

  children

closing_tag = (n) -> n.close and "</#{n.tag}>" or ""

render_tree = (tree) ->
  table.concat for n in *tree
    if n.text
      n.text
    else
      "<#{n.tag} id=\"#{n.id}\">#{render_tree n.children}#{closing_tag n}"

-- The output replace_html should produce after applying each node's edits. An
-- inner or outer replacement discards the edits below it, unwrap and attribute
-- edits keep them. replace_attributes writes the lowercased tag name.
render_tree_edited = (tree) ->
  table.concat for n in *tree
    if n.text
      n.edit == "replace" and "T#{n.text}" or n.text
    else
      open = "<#{n.tag} id=\"#{n.id}\">"
      new_open = "<#{n.name} data-new=\"#{n.id}\">"
      switch n.edit
        when "outer"
          "O#{n.id}"
        when "inner"
          "#{open}I#{n.id}#{closing_tag n}"
        when "inner_twice"
          "#{open}J#{n.id}#{closing_tag n}"
        when "inner_attributes"
          "#{new_open}I#{n.id}#{closing_tag n}"
        when "inner_unwrap"
          "I#{n.id}"
        when "unwrap"
          render_tree_edited n.children
        when "attributes"
          "#{new_open}#{render_tree_edited n.children}#{closing_tag n}"
        else
          "#{open}#{render_tree_edited n.children}#{closing_tag n}"

-- Applies each node's edits from random_tree in a replace_html callback
tree_edit_callback = (tree) ->
  by_id, by_text = {}, {}
  index = (list) ->
    for n in *list
      if n.text
        by_text[n.text] = n
      else
        by_id[n.id] = n
        index n.children

  index tree

  (stack) ->
    node = stack\current!
    if node.type == "text_node"
      n = by_text[node\outer_html!]
      node\replace_outer_html "T#{n.text}" if n and n.edit == "replace"
      return

    n = by_id[node.attr.id]
    switch n.edit
      when "unwrap"
        node\unwrap!
      when "attributes"
        node\replace_attributes { "data-new": n.id }
      when "inner"
        node\replace_inner_html "I#{n.id}"
      when "outer"
        node\replace_outer_html "O#{n.id}"
      when "inner_twice"
        node\replace_inner_html "I#{n.id}"
        node\replace_inner_html "J#{n.id}"
      when "inner_attributes"
        node\replace_inner_html "I#{n.id}"
        node\replace_attributes { "data-new": n.id }
      when "inner_unwrap"
        node\replace_inner_html "I#{n.id}"
        node\unwrap!

-- Random edits to the current node, following the rules for editing: any mix
-- of attribute and inner HTML edits, optionally ending with replace_outer_html
-- or unwrap
random_edit_callback = (stack) ->
  node = stack\current!
  is_text = node.type == "text_node"

  for i=1,math.random 0, 2
    switch math.random 3
      when 1
        node\replace_attributes { a: tostring i } unless is_text
      when 2
        node\update_attributes { u: tostring i } unless is_text
      else
        node\replace_inner_html "I#{i}"

  switch math.random 4
    when 1
      node\replace_outer_html "O"
    when 2
      node\unwrap! unless is_text

{
  :random_html, :random_selector, :random_stack_selector, :random_tree, :render_tree,
  :render_tree_edited, :tree_edit_callback, :random_edit_callback
}
