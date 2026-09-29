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

tree_tags = {"div", "span", "b", "em", "section", "DIV"}
tree_edits = {"unwrap", "attributes", "inner", "outer", "none"}

-- A well formed tree where each element and text node has an edit to apply.
-- Adjacent text nodes are avoided since they would parse as one.
random_tree = (depth=0, counter={n: 0}) ->
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
      table.insert children, {
        tag: pick tree_tags
        id: "n#{counter.n}"
        edit: pick tree_edits
        children: random_tree depth + 1, counter
      }

  children

render_tree = (tree) ->
  table.concat for n in *tree
    if n.text
      n.text
    else
      "<#{n.tag} id=\"#{n.id}\">#{render_tree n.children}</#{n.tag}>"

-- The output replace_html should produce after applying each node's edit. An
-- inner or outer replacement discards the edits below it, unwrap and attribute
-- edits keep them.
render_tree_edited = (tree) ->
  table.concat for n in *tree
    if n.text
      n.edit == "replace" and "T#{n.text}" or n.text
    else
      switch n.edit
        when "outer"
          "O#{n.id}"
        when "inner"
          "<#{n.tag} id=\"#{n.id}\">I#{n.id}</#{n.tag}>"
        when "unwrap"
          render_tree_edited n.children
        when "attributes"
          -- replace_attributes writes the lowercased tag name
          "<#{n.tag\lower!} data-new=\"#{n.id}\">#{render_tree_edited n.children}</#{n.tag}>"
        else
          "<#{n.tag} id=\"#{n.id}\">#{render_tree_edited n.children}</#{n.tag}>"

-- Applies each node's edit from random_tree in a replace_html callback
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
