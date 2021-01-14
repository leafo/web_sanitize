
obj_to_lua = (obj) ->
  compile = require "moonscript.compile"

  encode_value = (v) ->
    switch type(v)
      when "number"
        {"number", v}
      when "table"
        current_idx = 1

        items = for k,v in pairs v
          if k == current_idx
            current_idx += 1
            {encode_value v}
          else
            str = tostring k
            key_node = if str\match "^[a-zA-Z_][a-zA-Z0-9_]+$"
              {"key_literal", str}
            else
              encode_value str

            {key_node, encode_value(v)}

        {"table", items}
      else
        v = tostring v
        if v\match("'") or v\match '"'
          {"string", '[==[', v}
        else
          {"string", '"', v}

  (compile.tree {
    {"return", encode_value obj}
  })


blob = assert assert(io.open("entities.json"))\read "*a"

json = require "cjson"

entities = json.decode blob

mapping = {}

for name, char in pairs entities
  name = name\lower!
  mapping[name] = char.characters

-- create a table to be serialized into lua by moonscript

print obj_to_lua mapping





