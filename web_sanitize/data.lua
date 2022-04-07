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
local unnestable_tags = {
  "td",
  "tr",
  "li"
}
return {
  void_tags = void_tags,
  unnestable_tags = unnestable_tags,
  raw_text_tags = raw_text_tags
}
