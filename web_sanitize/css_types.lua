local P
P = require("lpeg").P
local short_names = {
  number = "n",
  string = "s",
  url = "u",
  ident = "u",
  hash = "h",
  ["function"] = "f"
}
local to_type_string
to_type_string = function(nodes)
  local type_chars
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #nodes do
      local node = nodes[_index_0]
      do
        local name = short_names[node[1]]
        if not (name) then
          error("Missing type short name for " .. tostring(node[1]))
        end
        _accum_0[_len_0] = name
      end
      _len_0 = _len_0 + 1
    end
    type_chars = _accum_0
  end
  return table.concat(type_chars)
end
local check_type
check_type = function(type_string, pattern)
  if not (type_string) then
    error("missing type string")
  end
  if not (pattern) then
    error("missing type pattern")
  end
  return not not (pattern * P(-1)):match(type_string)
end
local Number = P(short_names.number)
local String = P(short_names.string)
local Url = P(short_names.url)
local Ident = P(short_names.ident)
local Hash = P(short_names.hash)
local Function = P(short_names["function"])
return {
  to_type_string = to_type_string,
  check_type = check_type,
  Number = Number,
  String = String,
  Url = Url,
  Ident = Ident,
  Hash = Hash,
  Function = Function
}
