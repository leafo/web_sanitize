-- self closing

import p, dump from require "moon"
import insert, concat from table

lpeg = require "lpeg"

url_value = (value) -> value\match("^https?://") and true
mailto_value = (value) -> value\match("^mailto://") and true

-- Adapted from https://github.com/rgrove/sanitize/blob/master/lib/sanitize/config/basic.rb
whitelist = {
  { -- any tag
    title: true, dir: true, lang: true
  }

  a: {
    href: (v) -> url_value(v) or mailto_value(v)
    name: true
  }

  abbr: { title: true }
  b: true
  blockquote: { cite: true }
  br: true
  cite: true
  code: true
  dd: true
  dfn: { title: true }
  dl: true
  dt: true
  em: true
  h1: true
  h2: true
  h3: true
  h4: true
  h5: true
  h6: true
  i: true
  img: {
    align: true
    alt: true
    height: true
    src: url_value
    width: true
  }
  kbd: true
  li: true
  mark: true
  ol: true
  p: true
  pre: true
  q: { cite: true }
  s: true
  samp: true
  small: true
  strike: true
  strong: true
  sub: true
  sup: true
  table: { summary: true, width: true}
  tr: true
  td: { colspan: true, rowspan: true, width: true }
  th: { colspan: true, rowspan: true, width: true }
  time: { datetime: true, pubdate: true }
  u: true
  ul: true
  var: true
}

-- set default as metatable for
if default = whitelist[1]
  mt = { __index: default }
  for k,v in pairs(whitelist)
    continue unless type(k) == "string"
    if type(v) == "table"
      setmetatable v, mt
    else
      whitelist[k] = default

add_attributes = {
  a: {
    rel: "nofollow"
  }
}

tag_stack = {}

check_tag = (str, pos, tag) ->
  lower_tag = tag\lower!
  allowed = whitelist[lower_tag]
  return false unless allowed
  insert tag_stack, lower_tag
  true, tag

check_close_tag = (str, pos, tag) ->
  lower_tag = tag\lower!
  top_tag = tag_stack[#tag_stack]
  if top_tag == lower_tag
    tag_stack[#tag_stack] = nil
    true, tag
  else
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

open_tag = C(P"<" * white) * Cmt(word, check_tag) * Cmt(Cp! * white * attribute, check_attribute)^0 * Cmt("", inject_attributes) * C">"
close_tag = C(P"<" * white * P"/" * white) * Cmt(word, check_close_tag) * C(white * P">")

html = Ct (open_tag + close_tag + escaped_char + text)^0 * -1

t = {
  '<a href="hello"></a>'
  '<a href="http://leafo.net"></a>'
  '<a href="https://leafo.net"></a>'
  'what is going on <a href = world anus="dayz"> yeah <b> okay'
  'hello <script dad="world"><b>yes</b></b>'
  '<something/>'
  "<IMG color='red'></IMG>"
  [[<IMG """><SCRIPT>alert("XSS")</SCRIPT>">]]
  [[<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>]]
}

sanitize = (str) ->
  tag_stack = {}
  buffer = html\match str
  for i=#tag_stack,1,-1
    insert buffer, "</#{tag_stack[i]}>"
  concat buffer

for test in *t
  print "", sanitize test

