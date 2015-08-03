

import R, S, V, P from require "lpeg"
import C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp from require "lpeg"

local unescape_text

tag_stack = {}

fail_tag = ->
  error "tag failed!"

check_tag = (str, _, pos, tag) ->
  table.insert tag_stack, {:tag, :pos}
  true

check_close_tag = (str, pos, tag, end_pos) ->
  top = tag_stack[#tag_stack]
  top.end_pos = end_pos
  require("moon").p tag_stack
  table.remove tag_stack
  true

pop_tag = (str, pos, ...) ->
  table.remove tag_stack

check_attribute = (str, pos, name, val) ->
  top = tag_stack[#tag_stack]
  top.attr or= {}
  top.attr[name] = unescape_text\match(val) or val
  true

--

unescape_char = P"&gt;" / ">" +
  P"&lt;" / "<" +
  P"&amp;" / "&" +
  P"&#x27;" / "'" +
  P"&#x2F;" / "/" +
  P"&quot;" / '"'

unescape_text = Cs (unescape_char + 1)^1

white = S" \t\n"^0

alphanum = R "az", "AZ", "09"
num = R "09"
hex = R "09", "af", "AF"

valid_char = P"&" * (alphanum^1 + P"#" * (num^1 + S"xX" * hex^1)) + P";"

white = S" \t\n"^0
word = (alphanum + S"._-")^1

value = C(word) +
  P'"' * C((1 - P'"')^0) * P'"' +
  P"'" * C((1 - P"'")^0) * P"'"

attribute = C(word) * (white * P"=" * white * value)^-1

open_tag = Cmt(Cp! * P"<" * white * C(word), check_tag) *
  (Cmt(white * attribute, check_attribute)^0 *
    white * Cmt("/" * white, pop_tag)^-1 * P">" + Cmt("", fail_tag))

close_tag = Cmt(P"<" * white * P"/" * white * C(word) * white * P">" * Cp!, check_close_tag)

html = (open_tag + close_tag + valid_char + P"<" + P(1 - P"<")^1)^0 * -1

html\match "<div class='wanker &quot;'>hello<pre>hello</pre></div>"
