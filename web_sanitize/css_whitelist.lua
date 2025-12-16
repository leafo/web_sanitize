local Number, String, Ident, Hash, Function, Url
do
  local _obj_0 = require("web_sanitize.css_types")
  Number, String, Ident, Hash, Function, Url = _obj_0.Number, _obj_0.String, _obj_0.Ident, _obj_0.Hash, _obj_0.Function, _obj_0.Url
end
local Color = Ident + Hash + Function
local properties = {
  ["margin-top"] = Number + Ident,
  ["margin-right"] = Number + Ident,
  ["margin-bottom"] = Number + Ident,
  ["margin-left"] = Number + Ident,
  ["margin"] = (Number + Ident) ^ -4,
  ["padding-top"] = Number,
  ["padding-right"] = Number,
  ["padding-bottom"] = Number,
  ["padding-left"] = Number,
  ["padding"] = Number ^ -4,
  ["font-size"] = Number + Ident,
  ["text-align"] = Ident,
  ["color"] = Color,
  ["background-color"] = Color,
  ["background"] = Url + Ident + Hash,
  ["background-image"] = Url + Ident,
  ["opacity"] = Number,
  ["border"] = Number * (Ident * Color) ^ -1,
  ["border-width"] = Number ^ -4,
  ["border-color"] = Color,
  ["border-style"] = Ident ^ -4,
  ["width"] = Number,
  ["height"] = Number,
  ["max-width"] = Number,
  ["min-width"] = Number,
  ["max-height"] = Number,
  ["min-height"] = Number
}
return {
  properties = properties
}
