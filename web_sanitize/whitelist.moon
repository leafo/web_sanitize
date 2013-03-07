
url_value = (value) -> value\match("^https?://") and true
mailto_value = (value) -> value\match("^mailto:") and true

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

{ :whitelist, :add_attributes }

