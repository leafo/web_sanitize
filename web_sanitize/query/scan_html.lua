local void_tags, optional_tags
do
  local _obj_0 = require("web_sanitize.data")
  void_tags, optional_tags = _obj_0.void_tags, _obj_0.optional_tags
end
local open_tag, close_tag, html_comment, cdata, close_follows, unescape_html_text, escape_html_text, begin_raw_text_tag, alphanum
do
  local _obj_0 = require("web_sanitize.patterns")
  open_tag, close_tag, html_comment, cdata, close_follows, unescape_html_text, escape_html_text, begin_raw_text_tag, alphanum = _obj_0.open_tag, _obj_0.close_tag, _obj_0.html_comment, _obj_0.cdata, _obj_0.close_follows, _obj_0.unescape_html_text, _obj_0.escape_html_text, _obj_0.begin_raw_text_tag, _obj_0.alphanum
end
local P, C, Cc, Cs, Cmt, Cp
do
  local _obj_0 = require("lpeg")
  P, C, Cc, Cs, Cmt, Cp = _obj_0.P, _obj_0.C, _obj_0.Cc, _obj_0.Cs, _obj_0.Cmt, _obj_0.Cp
end
local match_text = P("<") ^ -1 * P(1 - P("<")) ^ 1
local void_tags_set
do
  local _tbl_0 = { }
  for _index_0 = 1, #void_tags do
    local t = void_tags[_index_0]
    _tbl_0[t] = true
  end
  void_tags_set = _tbl_0
end
local NodeStack
do
  local _class_0
  local _base_0 = {
    push = function(self, node)
      local idx = #self + 1
      self[idx] = node
      local positions = self._tag_positions[node.tag]
      if not (positions) then
        positions = { }
        self._tag_positions[node.tag] = positions
      end
      positions[#positions + 1] = idx
    end,
    pop = function(self)
      local idx = #self
      local node = self[idx]
      local positions = self._tag_positions[node.tag]
      positions[#positions] = nil
      self[idx] = nil
      return node
    end,
    has_tag = function(self, tag)
      local positions = self._tag_positions[tag]
      return positions ~= nil and positions[1] ~= nil
    end,
    current = function(self)
      return self[#self]
    end,
    _parse_query = function(self, query)
      if self._query_cache then
        do
          local q = self._query_cache[query]
          if q then
            return q
          end
        end
      else
        self._query_cache = { }
      end
      local parse_query
      parse_query = require("web_sanitize.query.parse_query").parse_query
      local q = assert(parse_query(query), "Failed to parse query: " .. tostring(query))
      self._query_cache[query] = q
      return q
    end,
    is = function(self, query)
      local match_query
      match_query = require("web_sanitize.query").match_query
      return match_query(self, self:_parse_query(query))
    end,
    select = function(self, query)
      local parse_query
      parse_query = require("web_sanitize.query.parse_query").parse_query
      local match_query
      match_query = require("web_sanitize.query").match_query
      local q = self:_parse_query(query)
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
    __init = function(self)
      self._tag_positions = { }
    end,
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
      return unescape_html_text:match(text) or text
    end,
    update_attributes = function(self, attrs)
      if self.attr then
        local provided_attributes = { }
        for k, v in pairs(attrs) do
          if type(v) == "table" then
            provided_attributes[v[1]:lower()] = true
          elseif type(k) == "string" then
            provided_attributes[k:lower()] = true
          end
        end
        local update = { }
        for idx, tuple in ipairs(self.attr) do
          local _continue_0 = false
          repeat
            if provided_attributes[tuple[1]:lower()] then
              _continue_0 = true
              break
            end
            table.insert(update, tuple)
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        for k, v in pairs(attrs) do
          if type(v) == "table" then
            table.insert(update, v)
          elseif type(k) == "string" then
            update[k] = v
          end
        end
        return self:replace_attributes(update)
      else
        return self:replace_attributes(attrs)
      end
    end,
    replace_attributes = function(self, attrs)
      if not (self.changes) then
        error("attempting to change buffer with no changes array")
      end
      assert(self.type ~= "text_node", "replace_attributes: text nodes have no attributes")
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
          buff[i + 3] = escape_html_text:match(value)
          buff[i + 4] = '"'
          i = i + 5
        end
      end
      for _index_0 = 1, #attrs do
        local _des_0 = attrs[_index_0]
        local k, v
        k, v = _des_0[1], _des_0[2]
        push_attr(k, v)
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
          push_attr(k, v)
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      if self.self_closing then
        buff[i] = " />"
      else
        buff[i] = ">"
      end
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
      if not (self.end_inner_pos) then
        error("replace_inner_html: element is still open, replace its HTML from its own callback")
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
      if not (self.end_pos) then
        error("replace_outer_html: element is still open, replace its HTML from its own callback")
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
local can_auto_close
can_auto_close = function(tag_stack, stack_pos, current)
  local parent = tag_stack[stack_pos]
  if not (parent) then
    return false
  end
  do
    local ot_type = optional_tags[parent.tag]
    if ot_type then
      if ot_type == true then
        if current.tag == parent.tag then
          return true
        end
      else
        for _index_0 = 1, #ot_type do
          local t = ot_type[_index_0]
          if t == current.tag then
            return true
          end
        end
      end
      return can_auto_close(tag_stack, stack_pos - 1, current)
    end
  end
end
local scan_html
scan_html = function(html_text, callback, opts)
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
  local pop_tag
  local push_tag
  push_tag = function(str, pos, node)
    node.tag = node.tag:lower()
    while can_auto_close(tag_stack, #tag_stack, node) do
      assert(pop_tag(str, node.pos, node.pos, tag_stack[#tag_stack].tag), "tag stack out of sync, node properties are read-only")
    end
    local parent = tag_stack[#tag_stack] or root_node
    parent.num_children = (parent.num_children or 0) + 1
    node.num = parent.num_children
    if node.attr then
      for _, tuple in ipairs(node.attr) do
        if tuple[2] then
          tuple[2] = unescape_html_text:match(tuple[2]) or tuple[2]
        end
        node.attr[tuple[1]:lower()] = tuple[2] or true
      end
    end
    setmetatable(node, BufferHTMLNode.__base)
    tag_stack:push(node)
    if void_tags_set[node.tag] or node.self_closing then
      node.end_pos = node.inner_pos
      node.end_inner_pos = node.inner_pos
      callback(tag_stack)
      tag_stack:pop()
    end
    return true
  end
  pop_tag = function(str, end_pos, end_inner_pos, tag)
    tag = tag:lower()
    if not (tag_stack:has_tag(tag)) then
      return false
    end
    for k = #tag_stack, 1, -1 do
      local popping = tag_stack[k]
      popping.end_inner_pos = end_inner_pos
      if popping.tag == tag then
        popping.end_pos = end_pos
      else
        popping.end_pos = end_inner_pos
      end
      callback(tag_stack)
      tag_stack:pop()
      if popping.tag == tag then
        break
      end
    end
    return true
  end
  local push_text_node
  push_text_node = function(str, end_pos, start_pos, text_content, is_cdata)
    local top = tag_stack[#tag_stack] or root_node
    top.num_children = (top.num_children or 0) + 1
    local inner_pos
    if is_cdata then
      inner_pos = start_pos + 9
    else
      inner_pos = start_pos
    end
    local end_inner_pos
    if is_cdata then
      end_inner_pos = end_pos - 3
    else
      end_inner_pos = end_pos
    end
    local text_node = {
      type = "text_node",
      tag = is_cdata or "",
      pos = start_pos,
      end_pos = end_pos,
      inner_pos = inner_pos,
      end_inner_pos = end_inner_pos,
      num = top.num_children
    }
    setmetatable(text_node, BufferHTMLNode.__base)
    local idx = #tag_stack + 1
    tag_stack[idx] = text_node
    callback(tag_stack)
    tag_stack[idx] = nil
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
      tag_stack:pop()
      k = k - 1
    end
    return true
  end
  local check_open_tag = Cmt(open_tag, push_tag)
  local check_close_tag = Cmt(close_tag, pop_tag)
  local text_node = match_text
  local cdata_guard = close_follows("<![CDATA[", "]]>")
  local cdata_node = cdata_guard * cdata
  if opts and opts.text_nodes == true then
    text_node = Cmt(Cp() * C(match_text), push_text_node)
    cdata_node = cdata_guard * Cmt(Cp() * C(cdata) * Cc("cdata"), push_text_node)
  end
  local raw_text_closer = P("</") * Cmt(C(alphanum ^ 1), function(_, pos, tag)
    do
      local top = tag_stack[#tag_stack]
      if top then
        return top.tag:lower() == tag:lower()
      else
        return error("somehow have empty tag stack when checking for closing raw text")
      end
    end
  end)
  local raw_text_tag = #begin_raw_text_tag * check_open_tag * (P(1) - raw_text_closer) ^ 0 * (check_close_tag + P(-1))
  local html = (html_comment + cdata_node + raw_text_tag + check_open_tag + check_close_tag + text_node) ^ 0 * -1 * Cmt(Cp(), check_dangling_tags)
  local res, err = html:match(html_text)
  return res
end
local apply_changes_sequential
apply_changes_sequential = function(buffer, changes)
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
          local _update_0 = 1
          other_change[_update_0] = other_change[_update_0] + delta
        end
        if min < other_change[2] then
          local _update_0 = 2
          other_change[_update_0] = other_change[_update_0] + delta
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
local apply_changes_linked
apply_changes_linked = function(buffer, changes)
  local max_pos = #buffer + 1
  local positions = { }
  for _index_0 = 1, #changes do
    local _des_0 = changes[_index_0]
    local a, b
    a, b = _des_0[1], _des_0[2]
    if a > b or a < 1 or b > max_pos then
      return nil
    end
    positions[a] = true
    positions[b] = true
  end
  local sorted
  do
    local _accum_0 = { }
    local _len_0 = 1
    for p in pairs(positions) do
      _accum_0[_len_0] = p
      _len_0 = _len_0 + 1
    end
    sorted = _accum_0
  end
  table.sort(sorted)
  local gaps = { }
  local head = {
    text = buffer:sub(1, (sorted[1] or max_pos) - 1)
  }
  local tail = head
  for i, p in ipairs(sorted) do
    local gap = { }
    tail.next = gap
    gaps[p] = gap
    local text = {
      text = buffer:sub(p, (sorted[i + 1] or max_pos) - 1)
    }
    gap.next = text
    tail = text
  end
  local find
  find = function(gap)
    while gap.merged do
      gap.merged = gap.merged.merged or gap.merged
      gap = gap.merged
    end
    return gap
  end
  for _index_0 = 1, #changes do
    local _continue_0 = false
    repeat
      local _des_0 = changes[_index_0]
      local a, b, sub
      a, b, sub = _des_0[1], _des_0[2], _des_0[3]
      local left = find(gaps[a])
      local right = find(gaps[b])
      if left.removed or right.removed then
        return nil
      end
      if left == right then
        if sub == "" then
          _continue_0 = true
          break
        end
        left.next = {
          text = sub,
          next = left.next
        }
      else
        local node = left.next
        while node ~= right do
          if not (node.text) then
            node.removed = true
          end
          node = node.next
        end
        if sub == "" then
          right.merged = left
          left.next = right.next
        else
          left.next = {
            text = sub,
            next = right
          }
        end
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  local buff = { }
  local node = head
  while node do
    if node.text then
      buff[#buff + 1] = node.text
    end
    node = node.next
  end
  return table.concat(buff)
end
local replace_html
replace_html = function(html_text, _callback, opts)
  local changes = { }
  local callback
  callback = function(tags, ...)
    local current = tags[#tags]
    current.__class.__base.changes = changes
    return _callback(tags, ...)
  end
  scan_html(html_text, callback, opts)
  return apply_changes_linked(html_text, changes) or apply_changes_sequential(html_text, changes)
end
return {
  scan_html = scan_html,
  replace_html = replace_html,
  _apply_changes_linked = apply_changes_linked
}
