

lpeg = require "lpeg"

import R, S, V, P from lpeg
import C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp from lpeg

make_string = (delim) ->
  d = P delim

  inside = (P("\\" .. delim) + "\\\\" + (1 - d))^0
  d * inside * d

alphanum = R "az", "AZ", "09"
num = R "09"
hex = R "09", "af", "AF"

white = S" \t\n"^0

ident = (alphanum + S"_-")^1
string_1 = make_string "'"
string_2 = make_string '"'

-- TODO: open string
uri = P("url(") * white * (string_1 + string_2) * white * P(")")

hash = P("#") * ident

decimal = P(".") * num^1

number = decimal + num^1 * (decimal)^-1
dimension = num * ident
percentage = num * P("%")

numeric = dimension + percentage + number

func_open = ident * P("(")

delim = white * (P"," * white)^-1
decl_delim = white * (P";" * white)^-1

grammar = P {
  V"Root"

  Any: numeric + string_1 + string_2 + uri + hash + V"Function" + ident
  AnyList: V"Any" * (delim * V"Any")^-1
  Function: func_open * white * V"AnyList" * white * P(")")

  Declaration: ident * white * P":" * white * V"AnyList"
  DeclarationList: V"Declaration" * (decl_delim * V"Declaration")^-1 * P";"^-1

  Selector: V"AnyList"
  RuleSet: V"Selector" * white * P"{" * white * V"DeclarationList"^-1 * white * P"}"

  Root: white * V"RuleSet" * (white * V"RuleSet")^0 * white * -P(1)
}

print C(grammar)\match [[
  body {
    one: hello(one, two);
    -two: dad 10em
  }

  pre {
    color: green;
    }

  div {}
]]

