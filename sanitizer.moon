-- self closing

import p, dump from require "moon"
import insert, concat from table

lpeg = require "lpeg"

whitelist = {
  a: { href: true }
  b: true
}

tag_stack = {}

check_tag = (str, pos, tag) ->
  print "CHECKING TAG:", tag
  allowed = whitelist[tag]
  return false unless allowed
  insert tag_stack, tag
  true, tag

check_close_tag = (str, pos, tag) ->
  top_tag = tag_stack[#tag_stack]
  if top_tag == tag
    tag_stack[#tag_stack] = nil
    true, tag
  else
    false

check_attribute = (str, pos_end, pos_start, name, value) ->
  tag = tag_stack[#tag_stack]
  allowed_attributes = whitelist[tag]

  print "CHECK ATTRIBUTE", pos_start, pos_end, name, value
  if type(allowed_attributes) != "table"
    return true

  attr = allowed_attributes[name]
  return true unless attr

  true, str\sub pos_start, pos_end - 1

import R, S, V, P from lpeg
import C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp from lpeg

escaped_char = S"<>'&\"" / {
  ">": "&gt;"
  "<": "&lt;"
  "&": "&amp;"
  "'": "&#039;"
  '"': "&quot;"
}

white = S" \t\n"^0
text = C (1 - escaped_char)^1
word = (R("az", "AZ", "09") + S"._-")^1

value = C(word) + Ct(C(P'"') * C((1 - P'"')^0) * P'"')

attribute = C(word) * white * P"=" * white * value

open_tag = C(P"<" * white) * Cmt(word, check_tag) * Cmt(Cp! * white * attribute, check_attribute)^0 * C">"
close_tag = C(P"<" * white * P"/" * white) * Cmt(word, check_close_tag) * C(white * P">")

html = Ct (open_tag + close_tag + escaped_char + text)^0 * -1

t = {
  'what is going on <a href = world anus="dayz"> yeah <b> okay'
  'hello <script dad="world"><b>yes</b></b>'
}

sanitize = (str) ->
  tag_stack = {}
  buffer = html\match str
  for i=#tag_stack,1,-1
    insert buffer, "</#{tag_stack[i]}>"
  concat buffer

for test in *t
  print "", sanitize test

