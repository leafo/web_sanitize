local void_tags
void_tags = require("web_sanitize.data").void_tags
local unescape_text, void_tags_set
local NodeStack
do
  local _class_0
  local _base_0 = {
    current = function(self)
      return self[#self]
    end,
    is = function(self, query)
      local parse_query
      parse_query = require("web_sanitize.query.parse_query").parse_query
      local match_query
      match_query = require("web_sanitize.query").match_query
      local q = assert(parse_query(query))
      return match_query(self, q)
    end,
    select = function(self, query)
      local parse_query
      parse_query = require("web_sanitize.query.parse_query").parse_query
      local match_query
      match_query = require("web_sanitize.query").match_query
      local q = assert(parse_query(query))
      local stack = { }
      return (function()
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #self do
          local _continue_0 = false
          repeat
            local n = self[_index_0]
            table.insert(stack, n)
            if not (match_query(stack, q)) then
              _continue_0 = true
              break
            end
            local _value_0 = n
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        return _accum_0
      end)()
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "NodeStack"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  NodeStack = _class_0
end
local HTMLNode
do
  local _class_0
  local _base_0 = {
    outer_html = function(self)
      assert(self.buffer, "missing buffer")
      assert(self.pos, "missing pos")
      assert(self.end_pos, "missing end_pos")
      return self.buffer:sub(self.pos, self.end_pos - 1)
    end,
    inner_html = function(self)
      assert(self.buffer, "missing buffer")
      assert(self.inner_pos, "missing inner_pos")
      assert(self.end_inner_pos, "missing end_inner_pos")
      return self.buffer:sub(self.inner_pos, self.end_inner_pos - 1)
    end,
    inner_text = function(self)
      local extract_text
      extract_text = require("web_sanitize").extract_text
      local text = extract_text(self:inner_html())
      return unescape_text:match(text) or text
    end,
    replace_attributes = function(self, attrs)
      local escape_text
      escape_text = require("web_sanitize.html").escape_text
      local buff = {
        "<",
        self.tag
      }
      local i = #buff + 1
      local push_attr
      push_attr = function(name, value)
        buff[i] = " "
        buff[i + 1] = name
        if value == true then
          i = i + 2
        else
          buff[i + 2] = '="'
          buff[i + 3] = escape_text:match(value)
          buff[i + 4] = '"'
          i = i + 5
        end
      end
      local seen_attrs = { }
      for _index_0 = 1, #attrs do
        local _continue_0 = false
        repeat
          local name = attrs[_index_0]
          local lower = name:lower()
          if seen_attrs[lower] then
            _continue_0 = true
            break
          end
          local value = attrs[lower]
          if not (value) then
            _continue_0 = true
            break
          end
          push_attr(name, value)
          seen_attrs[lower] = true
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      for k, v in pairs(attrs) do
        local _continue_0 = false
        repeat
          if not (type(k) == "string") then
            _continue_0 = true
            break
          end
          if not (v) then
            _continue_0 = true
            break
          end
          if seen_attrs[k] then
            _continue_0 = true
            break
          end
          push_attr(k, v)
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      buff[i] = ">"
      return table.insert(self.changes, {
        self.pos,
        self.inner_pos or self.end_pos,
        table.concat(buff)
      })
    end,
    replace_inner_html = function(self, replacement)
      if not (self.changes) then
        error("attempting to change buffer with no changes array")
      end
      return table.insert(self.changes, {
        self.inner_pos,
        self.end_inner_pos,
        replacement
      })
    end,
    replace_outer_html = function(self, replacement)
      if not (self.changes) then
        error("attempting to change buffer with no changes array")
      end
      return table.insert(self.changes, {
        self.pos,
        self.end_pos,
        replacement
      })
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "HTMLNode"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  HTMLNode = _class_0
end
local R, S, V, P
do
  local _obj_0 = require("lpeg")
  R, S, V, P = _obj_0.R, _obj_0.S, _obj_0.V, _obj_0.P
end
local C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp
do
  local _obj_0 = require("lpeg")
  C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp = _obj_0.C, _obj_0.Cs, _obj_0.Ct, _obj_0.Cmt, _obj_0.Cg, _obj_0.Cb, _obj_0.Cc, _obj_0.Cp
end
do
  local _tbl_0 = { }
  for _index_0 = 1, #void_tags do
    local t = void_tags[_index_0]
    _tbl_0[t] = true
  end
  void_tags_set = _tbl_0
end
local unescape_char = P("&gt;") / ">" + P("&lt;") / "<" + P("&amp;") / "&" + P("&nbsp;") / " " + P("&#x27;") / "'" + P("&#x2F;") / "/" + P("&quot;") / '"'
unescape_text = Cs((unescape_char + 1) ^ 1)
local alphanum = R("az", "AZ", "09")
local num = R("09")
local hex = R("09", "af", "AF")
local valid_char = P("&") * (alphanum ^ 1 + P("#") * (num ^ 1 + S("xX") * hex ^ 1)) + P(";")
local white = S(" \t\n") ^ 0
local word = (alphanum + S("._-")) ^ 1
local value = C(word) + P('"') * C((1 - P('"')) ^ 0) * P('"') + P("'") * C((1 - P("'")) ^ 0) * P("'")
local attribute = C(word) * (white * P("=") * white * value) ^ -1
local scan_html
scan_html = function(html_text, callback)
  assert(callback, "missing callback to scan_html")
  local changes = { }
  local BufferHTMLNode
  do
    local _class_0
    local _parent_0 = HTMLNode
    local _base_0 = {
      changes = changes,
      buffer = html_text
    }
    _base_0.__index = _base_0
    setmetatable(_base_0, _parent_0.__base)
    _class_0 = setmetatable({
      __init = function(self, ...)
        return _class_0.__parent.__init(self, ...)
      end,
      __base = _base_0,
      __name = "BufferHTMLNode",
      __parent = _parent_0
    }, {
      __index = function(cls, name)
        local val = rawget(_base_0, name)
        if val == nil then
          local parent = rawget(cls, "__parent")
          if parent then
            return parent[name]
          end
        else
          return val
        end
      end,
      __call = function(cls, ...)
        local _self_0 = setmetatable({}, _base_0)
        cls.__init(_self_0, ...)
        return _self_0
      end
    })
    _base_0.__class = _class_0
    if _parent_0.__inherited then
      _parent_0.__inherited(_parent_0, _class_0)
    end
    BufferHTMLNode = _class_0
  end
  local root_node = { }
  local tag_stack = NodeStack()
  local fail_tag
  fail_tag = function()
    tag_stack[#tag_stack] = nil
  end
  local check_tag
  check_tag = function(str, _, pos, tag)
    local top = tag_stack[#tag_stack] or root_node
    top.num_children = (top.num_children or 0) + 1
    local node = {
      tag = tag:lower(),
      pos = pos,
      num = top.num_children
    }
    setmetatable(node, BufferHTMLNode.__base)
    table.insert(tag_stack, node)
    return true
  end
  local check_close_tag
  check_close_tag = function(str, end_pos, end_inner_pos, tag)
    local stack_size = #tag_stack
    tag = tag:lower()
    if stack_size == 0 then
      return true
    end
    if tag ~= tag_stack[stack_size].tag then
      local found_tag = false
      for k = #tag_stack - 1, 1, -1 do
        if tag_stack[k].tag == tag then
          found_tag = true
        end
        break
      end
      if not (found_tag) then
        return true
      end
    end
    for k = stack_size, 1, -1 do
      local popping = tag_stack[k]
      popping.end_inner_pos = end_inner_pos
      if popping.tag == tag then
        popping.end_pos = end_pos
      else
        popping.end_pos = end_inner_pos
      end
      callback(tag_stack)
      tag_stack[k] = nil
      if popping.tag == tag then
        break
      end
    end
    return true
  end
  local check_dangling_tags
  check_dangling_tags = function(str, pos)
    local k = #tag_stack
    while k > 0 do
      local popping = tag_stack[k]
      popping.end_pos = pos
      popping.end_inner_pos = pos
      callback(tag_stack)
      tag_stack[k] = nil
      k = k - 1
    end
    return true
  end
  local check_void_tag
  check_void_tag = function(str, pos)
    local top = tag_stack[#tag_stack]
    if void_tags_set[top.tag] then
      top.end_pos = pos
      callback(tag_stack)
      table.remove(tag_stack)
      return true
    else
      return false
    end
  end
  local pop_void_tag
  pop_void_tag = function(str, pos, ...)
    local top = tag_stack[#tag_stack]
    top.end_pos = pos
    callback(tag_stack)
    table.remove(tag_stack)
    return true
  end
  local check_attribute
  check_attribute = function(str, pos, name, val)
    local top = tag_stack[#tag_stack]
    top.attr = top.attr or { }
    if val then
      top.attr[name:lower()] = unescape_text:match(val) or val
    else
      top.attr[name:lower()] = true
    end
    table.insert(top.attr, name)
    return true
  end
  local save_pos
  save_pos = function(field)
    return function(str, pos)
      local top = tag_stack[#tag_stack]
      top[field] = pos
      return true
    end
  end
  local open_tag = Cmt(Cp() * P("<") * white * C(word), check_tag) * (Cmt(white * attribute, check_attribute) ^ 0 * white * (Cmt("/" * white * P(">"), pop_void_tag) + P(">") * (Cmt("", check_void_tag) + Cmt("", save_pos("inner_pos")))) + Cmt("", fail_tag))
  local close_tag = Cmt(Cp() * P("<") * white * P("/") * white * C(word) * white * P(">"), check_close_tag)
  local html = (open_tag + close_tag + P("<") + P(1 - P("<")) ^ 1) ^ 0 * -1 * Cmt(Cp(), check_dangling_tags)
  local res, err = html:match(html_text)
  return res
end
local replace_html
replace_html = function(html_text, _callback)
  local changes = { }
  local callback
  callback = function(tags, ...)
    local current = tags[#tags]
    current.__class.__base.changes = changes
    return _callback(tags, ...)
  end
  scan_html(html_text, callback)
  local buffer = html_text
  for i, _des_0 in ipairs(changes) do
    local _continue_0 = false
    repeat
      local min, max, sub
      min, max, sub = _des_0[1], _des_0[2], _des_0[3]
      if min > max then
        _continue_0 = true
        break
      end
      buffer = buffer:sub(1, min - 1) .. sub .. buffer:sub(max)
      if #sub == max - min then
        _continue_0 = true
        break
      end
      for k = i + 1, #changes do
        local other_change = changes[k]
        local delta = #sub - (max - min)
        if min < other_change[1] then
          other_change[1] = other_change[1] + delta
        end
        if min < other_change[2] then
          other_change[2] = other_change[2] + delta
        end
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return buffer
end
return {
  scan_html = scan_html,
  replace_html = replace_html
}
