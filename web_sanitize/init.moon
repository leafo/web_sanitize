import insert, concat from table
import whitelist, add_attributes from require "web_sanitize.whitelist"

lpeg = require "lpeg"

tag_stack = {}

check_tag = (str, pos, tag) ->
  lower_tag = tag\lower!
  allowed = whitelist[lower_tag]
  return false unless allowed
  insert tag_stack, lower_tag
  true, tag

check_close_tag = (str, pos, tag, ...) ->
  lower_tag = tag\lower!
  top_tag = tag_stack[#tag_stack]
  if top_tag == lower_tag
    tag_stack[#tag_stack] = nil
    true, tag, ...
  else
    false

pop_tag = (str, pos, ...)->
  tag_stack[#tag_stack] = nil
  true, ...

fail_tag = ->
  tag_stack[#tag_stack] = nil
  false

check_attribute = (str, pos_end, pos_start, name, value) ->
  tag = tag_stack[#tag_stack]
  allowed_attributes = whitelist[tag]

  if type(allowed_attributes) != "table"
    return true

  attr = allowed_attributes[name]
  if type(attr) == "function"
    return true unless attr value
  else
    return true unless attr

  true, str\sub pos_start, pos_end - 1

inject_attributes = ->
  top_tag = tag_stack[#tag_stack]
  inject = add_attributes[top_tag]
  if inject
    buff = {}
    i = 1
    for k,v in pairs inject
      buff[i] = " "
      buff[i + 1] = k
      buff[i + 2] = '="'
      buff[i + 3] = v
      buff[i + 4] = '"'
      i += 5
    true, unpack buff
  else
    true

import R, S, V, P from lpeg
import C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp from lpeg

escaped_char = S"<>'&\"" / {
  ">": "&gt;"
  "<": "&lt;"
  "&": "&amp;"
  "'": "&#x27;"
  "/": "&#x2F;"
  '"': "&quot;"
}

white = S" \t\n"^0
text = C (1 - escaped_char)^1
word = (R("az", "AZ", "09") + S"._-")^1

value = C(word) + P'"' * C((1 - P'"')^0) * P'"'

attribute = C(word) * white * P"=" * white * value

open_tag = C(P"<" * white) * Cmt(word, check_tag) * (Cmt(Cp! * white * attribute, check_attribute)^0 * white * Cmt("", inject_attributes) * Cmt("/" * white, pop_tag)^-1 * C">" + Cmt("", fail_tag))
close_tag = C(P"<" * white * P"/" * white) * Cmt(C(word) * C(white * P">"), check_close_tag)

html = Ct (open_tag + close_tag + escaped_char + text)^0 * -1

sanitize_html = (str) ->
  tag_stack = {}
  buffer = html\match str
  for i=#tag_stack,1,-1
    insert buffer, "</#{tag_stack[i]}>"
  concat buffer

{ :sanitize_html }

