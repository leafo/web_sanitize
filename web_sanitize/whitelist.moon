
url_value = (value) ->
  value and (value\match("^https?://") or value\match("^//")) and true

mailto_value = (value) -> value and value\match("^mailto:") and true

-- Adapted from https://github.com/rgrove/sanitize/blob/master/lib/sanitize/config/basic.rb
tags = {
  { -- any tag
    title: true, dir: true, lang: true
  }

  a: {
    href: (...) -> url_value(...) or mailto_value(...)
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
  div: true
  dl: true
  dt: true
  em: true
  h1: true
  h2: true
  h3: true
  h4: true
  h5: true
  h6: true
  hr: true
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
  span: true
  strike: true
  strong: true
  sub: true
  sup: true
  table: { summary: true, width: true}
  thead: true
  tbody: true
  tfoot: true
  tr: true
  td: { colspan: true, rowspan: true, width: true }
  th: { colspan: true, rowspan: true, width: true }
  time: { datetime: true, pubdate: true }
  u: true
  ul: true
  var: true
}

set_default = (tags) ->
  default = tags[1]
  return unless default

  mt = { __index: default }
  for k,v in pairs(tags)
    continue unless type(k) == "string"
    if type(v) == "table"
      setmetatable v, mt
    else
      tags[k] = setmetatable {}, mt

set_default tags

add_attributes = {
  a: {
    rel: "nofollow"
  }
}

-- tags that don't need to be automatically closed
self_closing = {
  br: true, img: true, hr: true
}

clone = (t) ->
  return t unless type(t) == "table"
  {k, clone v for k, v in pairs t}

{
  :tags, :add_attributes, :self_closing
  clone: =>
    with clone @
      set_default .tags
}

