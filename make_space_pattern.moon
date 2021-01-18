
-- this script will generate the data for an optimal lpeg pattern for matching
-- space

-- unicode spaces
-- https://en.wikipedia.org/wiki/Whitespace_character#Unicode
space_codepoints = {
  9
  10
  11
  12
  13
  32
  133
  160
  5760
  8192
  8193
  8194
  8195
  8196
  8197
  8198
  8199
  8200
  8201
  8202
  8232
  8233
  8239
  8287
  12288

  -- related
  6158
  8203
  8204
  8205
  8288
  65279
}

import utf8_encode from require "web_sanitize.unicode"

bytes = (str) -> [string.byte(c) for c in str\gmatch "."]

byte_list = {}

for thing in * space_codepoints
  t = utf8_encode thing
  -- print thing, "`#{t}`"
  bs = bytes t
  table.insert byte_list, bs

tree = {}

for k, v in pairs byte_list
  top = tree
  for idx, byte in ipairs v
    if idx == #v
      if type(top[byte]) == "table"
        error "invalid nesting"

      top[byte] = true
    else
      top[byte] or= {}
      if type(top[byte]) != "table"
        error "invalid nesting"

      top = top[byte]


-- compile the pattern into the tree
-- flattinging where necessary 

import types from require "tableshape"

-- used to determine if we can collapse sub pattern
simple_sequence = types.one_of {
  types.shape {
    "P", types.table\tag "bytes"
  }
}

compile_pattern = (level) ->
  -- make pattern for all the terminal nodes
  term_bytes = for byte, v in pairs level
    continue unless v == true
    byte

  out = {}

  if next term_bytes
    if #term_bytes == 1
      table.insert out, {"P", term_bytes}
    else
      table.insert out, {"S", term_bytes}

  for byte, v in pairs level
    continue unless type(v) == "table"
    patt = compile_pattern v

    if match = simple_sequence patt
      table.insert out, {"P", {byte, unpack match.bytes}}
    else
      table.insert out, {"*", {"P", {byte}}, patt }


  if #out == 1
    out[1]
  else
    {"+", unpack out}

out = compile_pattern tree

precedences = {
  "+": 1
  "*": 2
}

node_to_lpeg = (node) ->
  node_type = node[1]
  switch node_type
    when "+", "*"
      chunks = for n in *node[2,]
        chunk, precedence = node_to_lpeg n
        if precedence and precedences[node_type] > precedence
          "(#{chunk})"
        else
          chunk

      table.concat(chunks, " #{node_type} "), precedences[node_type]
    when "S", "P"
      "#{node_type}(\"\\#{table.concat node[2], "\\"}\")"
    else
      error "unknown node type: #{node_type}: #{require("moon").dump node}"

print (node_to_lpeg out)



