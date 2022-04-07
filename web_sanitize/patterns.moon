
import P, R, S, C, Cp, Ct, Cg, Cc from require "lpeg"

alphanum = R "az", "AZ", "09"

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

{
  :tag_attribute
  :open_tag
  :close_tag
  :html_comment
  :cdata
}
