
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

query_el_tag = (query_el) ->
  for {t, expected} in *query_el
    return expected\lower! if t == "tag"

-- Used by match_query_single for each ancestor part of a selector. Stacks from
-- scan_html index open elements by tag, so a part that names a tag only tests
-- elements with that tag. Other stacks and parts walk every element
find_ancestor = (stack, stack_idx, query_el) ->
  tag_positions = stack._tag_positions
  tag = tag_positions and query_el_tag query_el

  unless tag
    for idx=stack_idx,1,-1
      return idx if test_el stack[idx], query_el
    return nil

  positions = tag_positions[tag]
  return nil unless positions

  lo, hi = 1, #positions
  last = 0
  while lo <= hi
    mid = math.floor (lo + hi) / 2
    if positions[mid] <= stack_idx
      last = mid
      lo = mid + 1
    else
      hi = mid - 1

  for k=last,1,-1
    idx = positions[k]
    return idx if test_el stack[idx], query_el

  nil

match_query_single = (stack, query) ->
  return false if #query > #stack
  stack_idx = #stack
  return false unless test_el stack[stack_idx], query[#query]

  for query_idx=#query - 1,1,-1
    idx = find_ancestor stack, stack_idx - 1, query[query_idx]
    return false unless idx
    stack_idx = idx

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
