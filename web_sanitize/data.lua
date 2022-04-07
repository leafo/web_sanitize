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
  option = true,
  optgroup = true,
  tr = true,
  td = true,
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
