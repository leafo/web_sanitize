
import scan_html from require "web_sanitize.query.scan_html"
import parse_query from require "web_sanitize.query.parse_query"

-- TODO: lowercase attribute keys

match_query = (stack, query) ->
  return false if #query > #stack
  stack_idx = #stack

  for i, element in ipairs query
    stack_el = stack[stack_idx - i + 1]
    local el_classes

    for {t, expected} in *element
      switch t
        when "class"
          unless el_classes
            return false unless stack_el.attr and stack_el.attr.class
            el_classes = {cls, true for cls in stack_el.attr.class\gmatch "[^%s]+"}

          return false unless el_classes[expected]
        when "id"
          id = stack_el.attr and stack_el.attr.id
          return false unless id == expected
        when "tag"
          return false unless expected\lower! == stack_el.tag\lower!
        else
          error "unknown selector type: #{t}"

  true


q = parse_query ".dogworld"
scan_html "<div><pre class='dogworld'>hello</pre></div><span><div class='dogubt'>yeah yeah <span class='dogworld'></span></div></span>", (stack) ->
  if match_query stack, q
    print "MATCH"
    require("moon").p stack[#stack]


