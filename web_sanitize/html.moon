import insert, concat from table
unpack = unpack or table.unpack

lpeg = require "lpeg"

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

at_most = (p, n)->
  assert n > 0
  if n == 1
    p
  else
    p * p^-(n-1)

html_entity = C P"&" * (alphanum^1 + P"#" * (num^1 + S"xX" * hex^1)) * P";"^-1

white = S" \t\n"^0
text = C (1 - escaped_char)^1
word = (alphanum + S"._-:")^1

value = C(word) + P'"' * C((1 - P'"')^0) * P'"' + P"'" * C((1 - P"'")^0) * P"'"
attribute = C(word) * (white * P"=" * white * value)^-1
comment = P"<!--" * (1 - P"-->")^0 * P"-->"

-- ignored matchers don't capture anything
value_ignored = word + P'"' * (1 - P'"')^0 * P'"' + P"'" * (1 - P"'")^0 * P"'"
attribute_ignored = word * (white * P"=" * white * value_ignored)^-1
open_tag_ignored = P"<" * white * word * (white * attribute_ignored)^0 * white * (P"/" * white)^-1 * P">"
close_tag_ignored = P"<" * white * P"/" * white * word * white * P">"

escape_text = Cs (escaped_char + 1)^0 * -1

Sanitizer = (opts) ->
  {
    tags: allowed_tags, :add_attributes, :self_closing
  } = opts and opts.whitelist or require "web_sanitize.whitelist"

  tag_stack = {}
  attribute_stack = {} -- captured attributes for tags when needed

  tag_has_dynamic_add_attribute = (tag) ->
    inject = add_attributes[tag]
    return false unless inject
    for _, v in pairs inject
      return true if type(v) == "function"

    false

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
      if attribute_stack[i]
        attribute_stack[i] = nil

      continue if self_closing[next_tag]
      buffer[k] = "</"
      buffer[k + 1] = next_tag
      buffer[k + 2] = ">"
      k += 3

    tag_stack[pos] = nil
    if attribute_stack[pos]
      attribute_stack[pos] = nil

    buffer[k] = punct
    buffer[k + 1] = tag
    buffer[k + 2] = rest

    true, unpack buffer

  pop_tag = (str, pos, ...) ->
    idx = #tag_stack
    tag_stack[idx] = nil
    if attribute_stack[idx]
      attribute_stack[idx] = nil
    true, ...

  fail_tag = ->
    idx = #tag_stack
    tag_stack[idx] = nil
    if attribute_stack[idx]
      attribute_stack[idx] = nil
    false

  check_attribute = (str, pos_end, pos_start, name, value) ->
    tag_idx = #tag_stack
    tag = tag_stack[tag_idx]
    lower_name = name\lower!
    allowed_attributes = allowed_tags[tag]

    if type(allowed_attributes) != "table"
      return true

    if tag_has_dynamic_add_attribute tag
      -- record the attributes for the inject function to inspect
      attributes = attribute_stack[tag_idx]
      unless attributes
        attributes = {}
        attribute_stack[tag_idx] = attributes

      attributes[lower_name] = value
      table.insert attributes, {name, value}

    attr = allowed_attributes[lower_name]
    local new_val
    if type(attr) == "function"
      new_val = attr value, name, tag
      return true unless new_val
    else
      return true unless attr

    if type(new_val) == "string"
      true, " #{name}=\"#{assert escape_text\match new_val}\""
    else
      true, str\sub pos_start, pos_end - 1

  inject_attributes = ->
    tag_idx = #tag_stack
    top_tag = tag_stack[tag_idx]
    inject = add_attributes[top_tag]

    if inject
      buff = {}
      i = 1
      for k,v in pairs inject
        v = if type(v) == "function"
          v attribute_stack[tag_idx] or {}

        continue unless v

        buff[i] = " "
        buff[i + 1] = k
        buff[i + 2] = '="'
        buff[i + 3] = v
        buff[i + 4] = '"'
        i += 5
      true, unpack buff
    else
      true

  tag_attributes = Cmt(Cp! * white * attribute, check_attribute)^0

  open_tag = C(P"<" * white) *
    Cmt(word, check_tag) *
    (tag_attributes * C(white) * Cmt("", inject_attributes) * (Cmt("/" * white * ">", pop_tag) + C">") + Cmt("", fail_tag))

  close_tag = Cmt(C(P"<" * white * P"/" * white) * C(word) * C(white * P">"), check_close_tag)

  if opts and opts.strip_tags
    open_tag += open_tag_ignored
    close_tag += close_tag_ignored

  if opts and opts.strip_comments
    open_tag = comment + open_tag

  html = Ct (open_tag + close_tag + html_entity + escaped_char + text)^0 * -1

  (str) ->
    tag_stack = {}
    buffer = assert html\match(str), "failed to parse html"

    -- close any tags that were left unclosed at the end of the input
    k = #buffer + 1
    for i=#tag_stack,1,-1
      tag = tag_stack[i]
      continue if self_closing[tag]
      buffer[k] = "</"
      buffer[k + 1] = tag
      buffer[k + 2] = ">"
      k += 3

    concat buffer


MAX_UNICODE = 0x10FFFF

-- if we get an invalid entity then we return the text as is
translate_entity = (str, kind, value) ->
  if kind == "named"
    entities = require "web_sanitize.html_named_entities"
    return entities[str\lower!] or str

  codepoint = switch kind
    when "dec"
      tonumber value
    when "hex"
      tonumber value, 16

  import utf8_encode from require "web_sanitize.unicode"
  if codepoint and codepoint <= MAX_UNICODE
    utf8_encode codepoint
  else
    str

annoteted_html_entity = C P"&" * (Cc"named" * at_most(alphanum, 50) + P"#" * (Cc"dec" * C(at_most(num, 10)) + S"xX" * Cc"hex" * C(at_most(hex, 5)))) * P";"^-1
decode_html_entity = Cs annoteted_html_entity / translate_entity

-- parse the html, extract text between non tag items
-- https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
-- opts:
--   escape_html: set to true to ensure that the returned text is safe for html insertion (this will leave any html escape sequences alone
--   printable: set to true to return printable characters only (strip control characters, also any invalid unicode)
Extractor = (opts) ->
  escape_html = opts and opts.escape_html
  printable = opts and opts.printable

  html_text = if escape_html
    Cs (open_tag_ignored / " " + close_tag_ignored / " " + comment / "" + html_entity + escaped_char + 1)^0 * -1
  else
    Cs (open_tag_ignored / " " + close_tag_ignored / " " + comment / "" + decode_html_entity + 1)^0 * -1


  import whitespace, strip_unprintable from require "web_sanitize.unicode"

  nospace = 1 - whitespace
  trim = whitespace^0 * C (whitespace^0 * nospace^1)^0

  (str) ->
    out = assert html_text\match(str), "failed to parse html"
    if printable
      out = assert strip_unprintable out

    out = assert trim\match (out\gsub "%s+", " ")
    out

{ :Sanitizer, :Extractor, :escape_text, :decode_html_entity }

