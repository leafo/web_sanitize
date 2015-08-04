
import scan_html from require "web_sanitize.query.scan_html"

scan_html "<div><pre>hello</pre></div>", (stack) ->
  require("moon").p stack

