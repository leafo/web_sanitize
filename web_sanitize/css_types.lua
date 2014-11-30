local P
P = require("lpeg").P
local short_names = {
  number = "n",
  string = "s",
  url = "u"
}
local to_type_string
to_type_string = function(nodes)
  return table.concat((function()
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #nodes do
      local node = nodes[_index_0]
      _accum_0[_len_0] = short_names[node.type]
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)())
end
local check_type
check_type = function(type_string, pattern)
  return not not (pattern * P(-1)):match(type_string)
end
local Number = P(short_names.number)
local String = P(short_names.string)
local Url = P(short_names.url)
return {
  to_type_string = to_type_string,
  check_type = check_type,
  Number = Number,
  String = String
}
