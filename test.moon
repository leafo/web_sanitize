import p, dump from require "moon"
import sanitize_html from require "web_sanitize.init"

t = {
  "<a color=red>hi</a wazzaup"
  '<a href="http://leafo.net"></a>'
  '<a href="https://leafo.net"></a>'
  'what is going on <a href = world anus="dayz"> yeah <b> okay'
  'hello <script dad="world"><b>yes</b></b>'
  '<something/>'
  "<IMG color='red'></IMG>"
  [[<IMG """><SCRIPT>alert("XSS")</SCRIPT>">]]
  [[<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>]]
}

for test in *t
  print "", sanitize_html test

