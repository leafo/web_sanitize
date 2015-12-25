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
      local _ = nil
    elseif "nth-child" == _exp_0 then
      if not (tonumber(expected) == el.num) then
        return false
      end
    else
      error("unknown selector type: " .. tostring(t))
    end
  end
  return true
end
local match_query_single
match_query_single = function(stack, query)
  if #query > #stack then
    return false
  end
  local stack_idx = #stack
  local first = true
  for query_idx = #query, 1, -1 do
    local query_el = query[query_idx]
    local matched = false
    while stack_idx >= 1 do
      local stack_el = stack[stack_idx]
      stack_idx = stack_idx - 1
      if test_el(stack_el, query_el) then
        matched = true
        break
      else
        if first then
          return false
        end
      end
    end
    first = false
    if not (matched) then
      return false
    end
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
