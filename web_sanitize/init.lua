local Sanitizer, Extractor
do
  local _obj_0 = require("web_sanitize.html")
  Sanitizer, Extractor = _obj_0.Sanitizer, _obj_0.Extractor
end
local sanitize_style
sanitize_style = require("web_sanitize.css").sanitize_style
local sanitize_html = Sanitizer()
local extract_text = Extractor()
return {
  VERSION = "0.6.0",
  sanitize_html = sanitize_html,
  extract_text = extract_text,
  sanitize_style = sanitize_style
}
