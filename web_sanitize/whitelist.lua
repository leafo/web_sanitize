local url_value
url_value = function(value)
  return value:match("^https?://") and true
end
local mailto_value
mailto_value = function(value)
  return value:match("^mailto:") and true
end
local whitelist = {
  {
    title = true,
    dir = true,
    lang = true
  },
  a = {
    href = function(v)
      return url_value(v) or mailto_value(v)
    end,
    name = true
  },
  abbr = {
    title = true
  },
  b = true,
  blockquote = {
    cite = true
  },
  br = true,
  cite = true,
  code = true,
  dd = true,
  dfn = {
    title = true
  },
  dl = true,
  dt = true,
  em = true,
  h1 = true,
  h2 = true,
  h3 = true,
  h4 = true,
  h5 = true,
  h6 = true,
  i = true,
  img = {
    align = true,
    alt = true,
    height = true,
    src = url_value,
    width = true
  },
  kbd = true,
  li = true,
  mark = true,
  ol = true,
  p = true,
  pre = true,
  q = {
    cite = true
  },
  s = true,
  samp = true,
  small = true,
  strike = true,
  strong = true,
  sub = true,
  sup = true,
  table = {
    summary = true,
    width = true
  },
  tr = true,
  td = {
    colspan = true,
    rowspan = true,
    width = true
  },
  th = {
    colspan = true,
    rowspan = true,
    width = true
  },
  time = {
    datetime = true,
    pubdate = true
  },
  u = true,
  ul = true,
  var = true
}
do
  local default = whitelist[1]
  if default then
    local mt = {
      __index = default
    }
    for k, v in pairs(whitelist) do
      local _continue_0 = false
      repeat
        if not (type(k) == "string") then
          _continue_0 = true
          break
        end
        if type(v) == "table" then
          setmetatable(v, mt)
        else
          whitelist[k] = default
        end
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
  end
end
local add_attributes = {
  a = {
    rel = "nofollow"
  }
}
return {
  whitelist = whitelist,
  add_attributes = add_attributes
}
