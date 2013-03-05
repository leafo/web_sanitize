
import p, dump from require "moon"
import insert, concat from table

lpeg = require "lpeg"

whitelist = {
  a: { href: true }
  b: true
}

tag_stack = {}

compile_tag = (tag, attributes) ->
  buffer = {"<", tag}

  i = #buffer
  append = (x) ->
    i += 1
    buffer[i] = x

  if #attributes
    for {name, value} in *attributes
      append " "
      append name
      append "="
      switch type(value)
        when "table"
          append value[1]
          append value[2]
          append value[1]
        else
          append value

  insert buffer, ">"
  concat buffer

check_tag = (str, post, tag, attributes) ->
  print "checking tag:", dump {
    tag
    attributes
  }

  allowed = whitelist[tag]
  return false unless allowed
  if type(allowed) == "table"
    attributes = for tuple in *attributes
      {name, value} = tuple
      continue unless allowed[name]
      tuple
  else
    attributes = {}

  insert tag_stack, tag
  true, compile_tag tag, attributes

import R, S, V, P from lpeg
import C, Cs, Ct, Cmt, Cg, Cb, Cc from lpeg

escaped_char = S"<>'&\"" / {
  ">": "&gt;"
  "<": "&lt;"
  "&": "&amp;"
  "'": "&#039;"
  '"': "&quot;"
}

white = S" \t\n"^0
text = C (1 - S "<")^1
word = (R("az", "AZ", "09") + S"._-")^1

value = C(word) + Ct(C(P'"') * C((1 - P'"')^0) * P'"')

attribute = Ct C(word) * white * P"=" * white * value * white

open_tag = Cmt P"<" * white * C(word) * white * Ct(attribute^0) * P">", check_tag

html = (open_tag + text)^0 * -1

p {
  html\match 'what is going on <a href = world anus="dayz"> yeah <b> okay'
}

