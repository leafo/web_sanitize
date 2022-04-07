
obj_to_lua = (obj) ->
  compile = require "moonscript.compile"

  encode_value = (v) ->
    switch type(v)
      when "number"
        {"number", v}
      when "table"
        current_idx = 1

        sorted_keys = [k for k in pairs v]
        table.sort sorted_keys, (a,b) ->
          if type(a) == type(b)
            a < b
          else
            type(a) < type(b)

        items = for key in *sorted_keys
          value = v[key]
          if key == current_idx
            current_idx += 1
            {encode_value value}
          else
            str = tostring key
            key_node = if str\match "^[a-zA-Z_][a-zA-Z0-9_]+$"
              {"key_literal", str}
            else
              encode_value str

            {key_node, encode_value value}

        {"table", items}
      else
        v = tostring v
        if v\match("'") or v\match('"') or v\match "\\"
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
  mapping[name] = char.characters

print obj_to_lua mapping





