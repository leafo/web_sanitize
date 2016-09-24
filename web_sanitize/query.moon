
import scan_html from require "web_sanitize.query.scan_html"
import parse_query from require "web_sanitize.query.parse_query"

unpack = unpack or table.unpack

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
      when "any"
        nil
      when "nth-child"
        return false unless tonumber(expected) == el.num
      when "attr"
        return false unless el.attr and el.attr[expected] != nil
      else
        error "unknown selector type: #{t}"

  true

match_query_single = (stack, query) ->
  return false if #query > #stack
  stack_idx = #stack

  first = true
  for query_idx=#query,1,-1
    query_el = query[query_idx]

    matched = false
    while stack_idx >= 1
      stack_el = stack[stack_idx]
      stack_idx -= 1
      if test_el stack_el, query_el
        matched = true
        break
      else
        return false if first

    first = false
    return false unless matched

  true

match_query = (stack, query) ->
  for q in *query
    if match_query_single stack, q
      return true

  false

query_all = (html, q) ->
  q = parse_query q
  res = {}
  scan_html html, (stack) ->
    if match_query stack, q
      table.insert res, stack[#stack]
  res

query = (...) ->
  unpack query_all ...

{ :query_all, :query, :match_query }
