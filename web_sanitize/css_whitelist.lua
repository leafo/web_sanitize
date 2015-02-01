local Number, String, Ident, Hash, Function, Url
do
  local _obj_0 = require("web_sanitize.css_types")
  Number, String, Ident, Hash, Function, Url = _obj_0.Number, _obj_0.String, _obj_0.Ident, _obj_0.Hash, _obj_0.Function, _obj_0.Url
end
local Color = Ident + Hash + Function
local properties = {
  ["margin-top"] = Number,
  ["margin-right"] = Number,
  ["margin-bottom"] = Number,
  ["margin-left"] = Number,
  ["margin"] = Number ^ -4,
  ["padding-top"] = Number,
  ["padding-right"] = Number,
  ["padding-bottom"] = Number,
  ["padding-left"] = Number,
  ["padding"] = Number ^ -4,
  ["font-size"] = Number + Ident,
  ["text-align"] = Ident,
  ["color"] = Color,
  ["background-color"] = Color,
  ["opacity"] = Number,
  ["border"] = Number,
  ["width"] = Number,
  ["height"] = Number
}
return {
  properties = properties
}
