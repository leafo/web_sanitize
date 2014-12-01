local sanitize_html, extract_text
do
  local _obj_0 = require("web_sanitize.html")
  sanitize_html, extract_text = _obj_0.sanitize_html, _obj_0.extract_text
end
local sanitize_style
sanitize_style = require("web_sanitize.css").sanitize_style
return {
  sanitize_html = sanitize_html,
  extract_text = extract_text,
  sanitize_style = sanitize_style
}
