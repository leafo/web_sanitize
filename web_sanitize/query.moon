

import R, S, V, P from require "lpeg"
import C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp from require "lpeg"


fail_tag = ->

check_tag = (str, pos, tag) ->
check_close_tag = (str, pos, punct, tag, rest) ->

pop_tag = (str, pos, ...) ->

inject_attributes = ->


check_attribute = (str, pos_end, pos_start, name, value) ->

--

white = S" \t\n"^0

alphanum = R "az", "AZ", "09"
num = R "09"
hex = R "09", "af", "AF"

white = S" \t\n"^0
text = C (1 - escaped_char)^1
word = (alphanum + S"._-")^1

value = C(word) + P'"' * C((1 - P'"')^0) * P'"' + P"'" * C((1 - P"'")^0) * P"'"

attribute = C(word) * (white * P"=" * white * value)^-1

open_tag = C(P"<" * white) *
  Cmt(word, check_tag) *
  (Cmt(Cp! * white * attribute, check_attribute)^0 * white * Cmt("", inject_attributes) * Cmt("/" * white, pop_tag)^-1 * C">" + Cmt("", fail_tag))

close_tag = Cmt(C(P"<" * white * P"/" * white) * C(word) * C(white * P">"), check_close_tag)
