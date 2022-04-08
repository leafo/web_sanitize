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
  p = true,
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
  }
}
return {
  void_tags = void_tags,
  optional_tags = optional_tags,
  raw_text_tags = raw_text_tags
}
