local lpeg = require("lpeg")
local R, S, V, P
R, S, V, P = lpeg.R, lpeg.S, lpeg.V, lpeg.P
local C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp
C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp = lpeg.C, lpeg.Cs, lpeg.Ct, lpeg.Cmt, lpeg.Cg, lpeg.Cb, lpeg.Cc, lpeg.Cp
local make_string
make_string = function(delim)
  local d = P(delim)
  local inside = (P("\\" .. delim) + "\\\\" + (1 - d)) ^ 0
  return d * inside * d
end
local alphanum = R("az", "AZ", "09")
local num = R("09")
local hex = R("09", "af", "AF")
local white = S(" \t\n") ^ 0
local ident = (alphanum + S("_-")) ^ 1
local string_1 = make_string("'")
local string_2 = make_string('"')
local uri = P("url(") * white * (string_1 + string_2) * white * P(")")
local hash = P("#") * ident
local decimal = P(".") * num ^ 1
local number = decimal + num ^ 1 * (decimal) ^ -1
local dimension = num * ident
local percentage = num * P("%")
local numeric = dimension + percentage + number
local func_open = ident * P("(")
local delim = white * (P(",") * white) ^ -1
local decl_delim = white * (P(";") * white) ^ -1
local grammar = P({
  V("Root"),
  Any = numeric + string_1 + string_2 + uri + hash + V("Function") + ident,
  AnyList = V("Any") * (delim * V("Any")) ^ -1,
  Function = func_open * white * V("AnyList") * white * P(")"),
  Declaration = ident * white * P(":") * white * V("AnyList"),
  DeclarationList = V("Declaration") * (decl_delim * V("Declaration")) ^ -1 * P(";") ^ -1,
  Selector = V("AnyList"),
  RuleSet = V("Selector") * white * P("{") * white * V("DeclarationList") ^ -1 * white * P("}"),
  Root = white * V("RuleSet") * (white * V("RuleSet")) ^ 0 * white * -P(1)
})
return print(C(grammar):match([[  body {
    one: hello(one, two);
    -two: dad 10em
  }

  pre {
    color: green;
    }

  div {}
]]))
