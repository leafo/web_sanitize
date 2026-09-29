local scan_html
scan_html = require("web_sanitize.query.scan_html").scan_html
local parse_query
parse_query = require("web_sanitize.query.parse_query").parse_query
local unpack = unpack or table.unpack
local test_el
test_el = function(el, q)
  local el_classes
  for _index_0 = 1, #q do
    local _des_0 = q[_index_0]
    local t, expected
    t, expected = _des_0[1], _des_0[2]
    local _exp_0 = t
    if "class" == _exp_0 then
      if not (el_classes) then
        if not (el.attr and el.attr.class) then
          return false
        end
        do
          local _tbl_0 = { }
          for cls in el.attr.class:gmatch("[^%s]+") do
            _tbl_0[cls] = true
          end
          el_classes = _tbl_0
        end
      end
      if not (el_classes[expected]) then
        return false
      end
    elseif "id" == _exp_0 then
      local id = el.attr and el.attr.id
      if not (id == expected) then
        return false
      end
    elseif "tag" == _exp_0 then
      if not (expected:lower() == el.tag) then
        return false
      end
    elseif "any" == _exp_0 then
      local _scrap_0 = nil
    elseif "nth-child" == _exp_0 then
      if not (tonumber(expected) == el.num) then
        return false
      end
    elseif "attr" == _exp_0 then
      if not (el.attr and el.attr[expected] ~= nil) then
        return false
      end
    else
      error("unknown selector type: " .. tostring(t))
    end
  end
  return true
end
local query_el_tag
query_el_tag = function(query_el)
  for _index_0 = 1, #query_el do
    local _des_0 = query_el[_index_0]
    local t, expected
    t, expected = _des_0[1], _des_0[2]
    if t == "tag" then
      return expected:lower()
    end
  end
end
local find_ancestor
find_ancestor = function(stack, stack_idx, query_el)
  local tag_positions = stack._tag_positions
  local tag = tag_positions and query_el_tag(query_el)
  if not (tag) then
    for idx = stack_idx, 1, -1 do
      if test_el(stack[idx], query_el) then
        return idx
      end
    end
    return nil
  end
  local positions = tag_positions[tag]
  if not (positions) then
    return nil
  end
  local lo, hi = 1, #positions
  local last = 0
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    if positions[mid] <= stack_idx then
      last = mid
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  for k = last, 1, -1 do
    local idx = positions[k]
    if test_el(stack[idx], query_el) then
      return idx
    end
  end
  return nil
end
local match_query_single
match_query_single = function(stack, query)
  if #query > #stack then
    return false
  end
  local stack_idx = #stack
  if not (test_el(stack[stack_idx], query[#query])) then
    return false
  end
  for query_idx = #query - 1, 1, -1 do
    local idx = find_ancestor(stack, stack_idx - 1, query[query_idx])
    if not (idx) then
      return false
    end
    stack_idx = idx
  end
  return true
end
local match_query
match_query = function(stack, query)
  for _index_0 = 1, #query do
    local q = query[_index_0]
    if match_query_single(stack, q) then
      return true
    end
  end
  return false
end
local query_all
query_all = function(html, q)
  q = parse_query(q)
  local res = { }
  scan_html(html, function(stack)
    if match_query(stack, q) then
      return table.insert(res, stack[#stack])
    end
  end)
  return res
end
local query
query = function(...)
  return unpack(query_all(...))
end
return {
  query_all = query_all,
  query = query,
  match_query = match_query
}
