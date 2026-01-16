local Sanitizer, Extractor
do
  local _obj_0 = require("web_sanitize.html")
  Sanitizer, Extractor = _obj_0.Sanitizer, _obj_0.Extractor
end
local sanitize_style
sanitize_style = require("web_sanitize.css").sanitize_style
local unescape_html_text
unescape_html_text = require("web_sanitize.patterns").unescape_html_text
local sanitize_html = Sanitizer()
local extract_text = Extractor({
  escape_html = true
})
local unescape_html
unescape_html = function(str)
  return assert(unescape_html_text:match(str))
end
return {
  VERSION = "1.7.0",
  sanitize_html = sanitize_html,
  extract_text = extract_text,
  sanitize_style = sanitize_style,
  unescape_html = unescape_html
}
