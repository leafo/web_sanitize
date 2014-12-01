
import P from require "lpeg"

short_names = {
  number: "n"
  string: "s"
  url: "u"
  ident: "u"
  hash: "h"
  function: "f"
}

to_type_string = (nodes) ->
  type_chars = for node in *nodes
    with name = short_names[node[1]]
      unless name
        error "Missing type short name for #{node[1]}"

  table.concat type_chars

check_type = (type_string, pattern) ->
  error "missing type string" unless type_string
  error "missing type pattern" unless pattern

  not not (pattern * P -1)\match type_string

Number = P short_names.number
String = P short_names.string
Url = P short_names.url
Ident = P short_names.ident
Hash = P short_names.hash
Function = P short_names.function

{
  :to_type_string
  :check_type
  :Number, :String, :Url, :Ident, :Hash, :Function
}
