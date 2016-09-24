

import R, S, V, P from require "lpeg"
import C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp from require "lpeg"

alphanum = R "az", "AZ", "09"
num = R "09"
white = S" \t\n"^0
word = (alphanum + S"_-")^1

mark = (name) -> (...) -> {name, ...}

parse_query = (query) ->
  tag = word / mark "tag"
  cls = P"." * (word / mark "class")
  id = P"#" * (word / mark "id")
  any = P"*"/ mark "any"
  nth = P":nth-child(" * C(num^1) * ")" / mark "nth-child"
  attr = P"[" * C(word) * P"]" / mark "attr"

  selector = Ct (any + nth + tag + cls + id + attr)^1

  pq = Ct selector * (white * selector)^0
  pqs = Ct pq * (white * P"," * white * pq)^0
  pqs *= white * -1 -- match to end

  pqs\match query

{ :parse_query }

