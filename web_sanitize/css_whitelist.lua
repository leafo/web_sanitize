local Number
Number = require("web_sanitize.css_types").Number
local properties = {
  ["margin-top"] = Number,
  ["margin-right"] = Number,
  ["margin-bottom"] = Number,
  ["margin-left"] = Number,
  ["margin"] = #Number * Number ^ -4
}
return {
  properties = properties
}
