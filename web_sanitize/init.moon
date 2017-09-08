
import Sanitizer, Extractor from require "web_sanitize.html"
import sanitize_style from require "web_sanitize.css"

sanitize_html = Sanitizer!
extract_text = Extractor!

{
  VERSION: "0.6.0"
  :sanitize_html, :extract_text, :sanitize_style
}
