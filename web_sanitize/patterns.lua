local P, R, S, C, Cp, Ct, Cg, Cc
do
  local _obj_0 = require("lpeg")
  P, R, S, C, Cp, Ct, Cg, Cc = _obj_0.P, _obj_0.R, _obj_0.S, _obj_0.C, _obj_0.Cp, _obj_0.Ct, _obj_0.Cg, _obj_0.Cc
end
local alphanum = R("az", "AZ", "09")
local white = S(" \t\n") ^ 0
local word = (alphanum + S("._-")) ^ 1
local attribute_value = C(word) + P('"') * C((1 - P('"')) ^ 0) * P('"') + P("'") * C((1 - P("'")) ^ 0) * P("'")
local attribute_name = (alphanum + S("._-:")) ^ 1
local tag_attribute = Ct(C(attribute_name) * (white * P("=") * white * attribute_value) ^ -1)
local open_tag = Ct(Cg(Cp(), "pos") * P("<") * white * Cg(word, "tag") * Cg(Ct((white * tag_attribute) ^ 1), "attr") ^ -1 * white * ("/" * white * P(">") * Cg(Cc(true), "self_closing") + P(">")) * Cg(Cp(), "inner_pos"))
local close_tag = Cp() * P("<") * white * P("/") * white * C(word) * white * P(">")
local html_comment = P("<!") * ((P(1) - P(">") - P("->")) * (P(1) - P("<!--") - P("-->")) ^ 0) ^ -1 * P("-->")
return {
  open_tag = open_tag,
  close_tag = close_tag,
  html_comment = html_comment,
  tag_attribute = tag_attribute
}
