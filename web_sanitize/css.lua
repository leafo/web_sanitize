local allowed_properties
allowed_properties = require("web_sanitize.css_whitelist").properties
local to_type_string, check_type
do
  local _obj_0 = require("web_sanitize.css_types")
  to_type_string, check_type = _obj_0.to_type_string, _obj_0.check_type
end
local lpeg = require("lpeg")
local R, S, V, P
R, S, V, P = lpeg.R, lpeg.S, lpeg.V, lpeg.P
local C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp
C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp = lpeg.C, lpeg.Cs, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb, lpeg.Cc, lpeg.Cp
local make_string
make_string = function(delim)
  local d = P(delim)
  local inside = (P("\\" .. delim) + "\\\\" + (1 - d)) ^ 0
  return d * inside * d
end
local alphanum = R("az", "AZ", "09")
local num = R("09")
local hex = R("09", "af", "AF")
local white = S(" \t\n") ^ 0
local ident = (alphanum + S("_-")) ^ 1
local string_1 = make_string("'")
local string_2 = make_string('"')
local uri = P("url(") * white * (string_1 + string_2) * white * P(")")
local hash = P("#") * ident
local decimal = P(".") * num ^ 1
local number = decimal + num ^ 1 * (decimal) ^ -1
local dimension = num ^ 1 * ident
local percentage = num ^ 1 * P("%")
local numeric = dimension + percentage + number
local func_open = ident * P("(")
local delim = white * (P(",") * white) ^ -1
local decl_delim = white * P(";") * white
local mark
mark = function(name)
  return function(...)
    return {
      name,
      ...
    }
  end
end
local check_declaration
check_declaration = function(str, pos, chunk, prop, val)
  local type_pattern = allowed_properties[prop]
  if not (type_pattern) then
    return true, ""
  end
  local prop_types = to_type_string(val)
  if not (check_type(prop_types, type_pattern)) then
    return true, ""
  end
  return true, chunk
end
local declaration_list = P({
  V("DeclarationList"),
  Any = numeric / mark("number") + (string_1 + string_2) / mark("string") + uri / mark("url") + hash / mark("hash") + V("Function") / mark("function") + ident / mark("ident"),
  AnyList = V("Any") * (delim * V("Any")) ^ 0,
  Function = func_open * white * V("AnyList") * white * P(")"),
  Declaration = Cmt(C(C(ident) * white * P(":") * white * Ct(V("AnyList"))), check_declaration),
  DeclarationList = Ct(white * V("Declaration") * (decl_delim * V("Declaration")) ^ 0 * P(";") ^ -1)
})
local grammar = P({
  V("Root"),
  DeclarationList = declaration_list,
  Selector = ident,
  RuleSet = V("Selector") * white * P("{") * white * V("DeclarationList") ^ -1 * white * P("}"),
  Root = white * V("RuleSet") * (white * V("RuleSet")) ^ 0 * white * -P(1)
})
local style_pattern = declaration_list * P(-1)
local sanitize_style
sanitize_style = function(style)
  if style:match("^%s*$") then
    return ""
  end
  local chunks = style_pattern:match(style)
  if not (chunks) then
    return nil, "failed to parse"
  end
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #chunks do
      local chunk = chunks[_index_0]
      if chunk ~= "" then
        _accum_0[_len_0] = chunk
        _len_0 = _len_0 + 1
      end
    end
    chunks = _accum_0
  end
  return table.concat(chunks, "; ")
end
return {
  sanitize_style = sanitize_style
}
