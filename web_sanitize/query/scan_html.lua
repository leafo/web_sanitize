local void_tags
void_tags = require("web_sanitize.data").void_tags
local unescape_text
local HTMLNode
do
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
      extract_text = require("web_sanitize.html").extract_text
      local text = extract_text(self:inner_html())
      return unescape_text:match(text) or text
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
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
local void_tags_set
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
  local BufferHTMLNode
  do
    local _parent_0 = HTMLNode
    local _base_0 = {
      buffer = html_text
    }
    _base_0.__index = _base_0
    setmetatable(_base_0, _parent_0.__base)
    local _class_0 = setmetatable({
      __init = function(self, ...)
        return _parent_0.__init(self, ...)
      end,
      __base = _base_0,
      __name = "BufferHTMLNode",
      __parent = _parent_0
    }, {
      __index = function(cls, name)
        local val = rawget(_base_0, name)
        if val == nil then
          return _parent_0[name]
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
  local tag_stack = { }
  local fail_tag
  fail_tag = function()
    return table.insert(tag_stack, node)
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
  local html = (open_tag + close_tag + P("<") + P(1 - P("<")) ^ 1) ^ 0 * -1
  return html:match(html_text)
end
return {
  scan_html = scan_html
}
