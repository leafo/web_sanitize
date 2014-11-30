
import P from require "lpeg"

short_names = {
  number: "n"
  string: "s"
  url: "u"
}

to_type_string = (nodes) ->
  table.concat [short_names[node.type] for node in *nodes]

check_type = (type_string, pattern) ->
  not not (pattern * P -1)\match type_string

Number = P short_names.number
String = P short_names.string
Url = P short_names.url

{
  :to_type_string
  :check_type
  :Number, :String
}
