
import P, R, S, C, Cp, Ct, Cg, Cc, Cs from require "lpeg"

alphanum = R "az", "AZ", "09"
num = R "09"
hex = R "09", "af", "AF"

at_most = (p, n) ->
  assert n > 0
  if n == 1
    p
  else
    p * p^-(n-1)

white = S" \t\n"^0
word = (alphanum + S"._-")^1

attribute_value = C(word) +
  P'"' * C((1 - P'"')^0) * P'"' +
  P"'" * C((1 - P"'")^0) * P"'"

attribute_name = (alphanum + S"._-:")^1 -- TODO: this is way too strict https://dev.w3.org/html5/spec-LC/syntax.html#attributes-0
tag_attribute = Ct C(attribute_name) * (white * P"=" * white * attribute_value)^-1

-- this will parse an opening tag into a table with the following format:
-- {
--   pos: 123 -- where the openning < starts
--   inner_pos: 234 -- after the closing > (aka where the inner_html would start)
--   tag: "div"
--   attr: {
--     {name, value}
--     {name}
--   }
--   self_closing: false -- if the /> syntax is used to close the tag
-- }
open_tag = Ct Cg(Cp!, "pos") * P"<" * white * Cg(word, "tag") *
  Cg(Ct((white * tag_attribute)^1), "attr")^-1 *
  white * ("/" * white * P">" * Cg(Cc(true), "self_closing") + P">") *
  Cg(Cp!, "inner_pos")

-- this will parse a closing tag multiple captures: start_pos, tag_name
-- we don't use Ct here to avoid allocating extra table, closing position can also be obtained from the Cmt function that is used to process the closing tag
close_tag = Cp! * P"<" * white * P"/" * white * C(word) * white * P">"


-- https://html.spec.whatwg.org/multipage/syntax.html#comments
html_comment = P"<!--" * -P">" * -P"->" * (P(1) - P"<!--" - P"-->" - P"--!>")^0 * P"<!"^-1 * P"-->"

cdata = P"<![CDATA[" * (P(1) - P("]]>"))^0 * P"]]>"

-- if we get an invalid entity then we return the text as is
MAX_UNICODE = 0x10FFFF
translate_entity = (str, kind, value) ->
  if kind == "named"
    entities = require "web_sanitize.html_named_entities"
    return entities[str] or entities[str\lower!] or str

  codepoint = switch kind
    when "dec"
      tonumber value
    when "hex"
      tonumber value, 16

  import utf8_encode from require "web_sanitize.unicode"
  if codepoint and codepoint <= MAX_UNICODE
    utf8_encode codepoint
  else
    str

annoteted_html_entity = C P"&" * (Cc"named" * at_most(alphanum, 20) + P"#" * (Cc"dec" * C(at_most(num, 10)) + S"xX" * Cc"hex" * C(at_most(hex, 5)))) * P";"^-1
decode_html_entity = annoteted_html_entity / translate_entity

-- unescapes an html text string that may contain html entities
unescape_html_text = Cs (decode_html_entity + P(1))^0


{
  :tag_attribute
  :open_tag
  :close_tag
  :html_comment
  :cdata
  :unescape_html_text
}
