import insert, concat from table

{ tags: allowed_tags, :add_attributes, :self_closing } = require "web_sanitize.whitelist"

lpeg = require "lpeg"

tag_stack = {}

check_tag = (str, pos, tag) ->
  lower_tag = tag\lower!
  allowed = allowed_tags[lower_tag]
  return false unless allowed
  insert tag_stack, lower_tag
  true, tag

check_close_tag = (str, pos, punct, tag, rest) ->
  lower_tag = tag\lower!
  top = #tag_stack
  pos = top -- holds position in stack where what we are closing is

  while pos >= 1
    break if tag_stack[pos] == lower_tag
    pos -= 1

  if pos == 0
    return false

  buffer = {}

  k = 1
  for i=top, pos + 1, -1
    next_tag = tag_stack[i]
    tag_stack[i] = nil
    continue if self_closing[next_tag]
    buffer[k] = "</"
    buffer[k + 1] = next_tag
    buffer[k + 2] = ">"
    k += 3

  tag_stack[pos] = nil

  buffer[k] = punct
  buffer[k + 1] = tag
  buffer[k + 2] = rest

  true, unpack buffer

pop_tag = (str, pos, ...)->
  tag_stack[#tag_stack] = nil
  true, ...

fail_tag = ->
  tag_stack[#tag_stack] = nil
  false

check_attribute = (str, pos_end, pos_start, name, value) ->
  tag = tag_stack[#tag_stack]
  allowed_attributes = allowed_tags[tag]

  if type(allowed_attributes) != "table"
    return true

  attr = allowed_attributes[name\lower!]
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

alphanum = R "az", "AZ", "09"
num = R "09"
hex = R "09", "af", "AF"

valid_char = C P"&" * (alphanum^1 + P"#" * (num^1 + S"xX" * hex^1)) + P";"

white = S" \t\n"^0
text = C (1 - escaped_char)^1
word = (alphanum + S"._-")^1

value = C(word) + P'"' * C((1 - P'"')^0) * P'"' + P"'" * C((1 - P"'")^0) * P"'"

attribute = C(word) * white * P"=" * white * value

open_tag = C(P"<" * white) * Cmt(word, check_tag) * (Cmt(Cp! * white * attribute, check_attribute)^0 * white * Cmt("", inject_attributes) * Cmt("/" * white, pop_tag)^-1 * C">" + Cmt("", fail_tag))
close_tag = Cmt(C(P"<" * white * P"/" * white) * C(word) * C(white * P">"), check_close_tag)

html = Ct (open_tag + close_tag + valid_char + escaped_char + text)^0 * -1

sanitize_html = (str) ->
  tag_stack = {}
  buffer = html\match str
  k = #buffer + 1
  for i=#tag_stack,1,-1
    tag = tag_stack[i]
    continue if self_closing[tag]
    buffer[k] = "</"
    buffer[k + 1] = tag
    buffer[k + 2] = ">"
    k += 3

  concat buffer

{ :sanitize_html }

