
{properties: allowed_properties} = require "web_sanitize.css_whitelist"
import to_type_string, check_type from require "web_sanitize.css_types"

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
dimension = num^1 * ident
percentage = num^1 * P("%")

numeric = dimension + percentage + number

func_open = ident * P("(")

delim = white * (P"," * white)^-1
decl_delim = white * P";" * white

mark = (name) -> (...) -> {name, ...}

check_declaration = (str, pos, chunk, prop, val) ->
  type_pattern = allowed_properties[prop]
  return true, "" unless type_pattern
  prop_types = to_type_string(val)
  return true, "" unless check_type prop_types, type_pattern
  true, chunk

declaration_list = P {
  V"DeclarationList"

  Any: numeric / mark"number" + (string_1 + string_2)/ mark"string" + uri / mark"url" + hash / mark"hash" + V"Function" / mark"function" + ident/mark"ident"
  AnyList: V"Any" * (delim * V"Any")^0
  Function: func_open * white * V"AnyList" * white * P(")")

  Declaration: Cmt C(C(ident) * white * P":" * white * Ct(V"AnyList")), check_declaration
  DeclarationList: Ct white * V"Declaration" * (decl_delim * V"Declaration")^0 * P";"^-1
}

grammar = P {
  V"Root"

  DeclarationList: declaration_list

  Selector: ident
  RuleSet: V"Selector" * white * P"{" * white * V"DeclarationList"^-1 * white * P"}"

  Root: white * V"RuleSet" * (white * V"RuleSet")^0 * white * -P(1)
}

style_pattern = declaration_list * P(-1)

sanitize_style = (style) ->
  return "" if style\match "^%s*$"
  chunks = style_pattern\match style

  unless chunks
    return nil, "failed to parse"

  chunks = [chunk for chunk in *chunks when chunk != ""]
  table.concat chunks, "; "

{ :sanitize_style }
