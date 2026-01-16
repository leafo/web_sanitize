
import Sanitizer, Extractor from require "web_sanitize.html"
import sanitize_style from require "web_sanitize.css"
import unescape_html_text from require "web_sanitize.patterns"

sanitize_html = Sanitizer!
extract_text = Extractor {
  escape_html: true
}

unescape_html = (str) ->
  assert unescape_html_text\match str

{
  VERSION: "1.7.0"
  :sanitize_html, :extract_text, :sanitize_style, :unescape_html
}
