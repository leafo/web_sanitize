local void_tags = {
  "area",
  "base",
  "br",
  "col",
  "command",
  "embed",
  "hr",
  "img",
  "input",
  "keygen",
  "link",
  "meta",
  "param",
  "source",
  "track",
  "wbr"
}
local raw_text_tags = {
  "script",
  "style",
  "textarea",
  "title"
}
local optional_tags = {
  p = {
    "p",
    "address",
    "article",
    "aside",
    "blockquote",
    "details",
    "div",
    "dl",
    "fieldset",
    "figcaption",
    "figure",
    "footer",
    "form",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "header",
    "hgroup",
    "hr",
    "main",
    "menu",
    "nav",
    "ol",
    "pre",
    "section",
    "table",
    "ul"
  },
  optgroup = true,
  option = {
    "option",
    "optgroup"
  },
  tr = true,
  td = {
    "td",
    "th"
  },
  th = {
    "td",
    "th"
  },
  li = true,
  thead = {
    "tbody",
    "tfoot"
  },
  tbody = {
    "tbody",
    "tfoot"
  },
  colgroup = {
    "caption",
    "thead",
    "tbody",
    "tfoot",
    "tr"
  },
  caption = {
    "colgroup",
    "thead",
    "tbody",
    "tfoot",
    "tr"
  }
}
return {
  void_tags = void_tags,
  optional_tags = optional_tags,
  raw_text_tags = raw_text_tags
}
