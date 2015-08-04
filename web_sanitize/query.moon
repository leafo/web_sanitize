
import scan_html from require "web_sanitize.query.scan_html"
import parse_query from require "web_sanitize.query.parse_query"

test_el = (el, q) ->
  local el_classes
  for {t, expected} in *q
    switch t
      when "class"
        unless el_classes
          return false unless el.attr and el.attr.class
          el_classes = {cls, true for cls in el.attr.class\gmatch "[^%s]+"}

        return false unless el_classes[expected]
      when "id"
        id = el.attr and el.attr.id
        return false unless id == expected
      when "tag"
        return false unless expected\lower! == el.tag
      else
        error "unknown selector type: #{t}"

  true

match_query = (stack, query) ->
  return false if #query > #stack
  stack_idx = #stack

  for i, query_el in ipairs query
    stack_el = stack[stack_idx - i + 1]
    return false unless test_el stack_el, query_el
  true

q = parse_query ".dogworld"
scan_html [[
  <div>
    <pre class='dogworld'>hello</pre>
  </div>
  <span>
    <div class='dogubt'>yeah yeah <span class='dogworld'>more <span>dogs</span> &quot;</span></div>
  </span>
]], (stack) ->
  if match_query stack, q
    print "MATCH"
    node = stack[#stack]
    print node\outer_html!
    print node\inner_html!
    print node\inner_text!


