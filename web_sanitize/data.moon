
-- Elements that have special behavior
-- https://html.spec.whatwg.org/multipage/syntax.html#elements-2

-- See also: optional tags: https://html.spec.whatwg.org/multipage/syntax.html#optional-tags


-- tags that always self close even if missign the self closing syntax />
void_tags = {
  "area"
  "base"
  "br"
  "col"
  "command"
  "embed"
  "hr"
  "img"
  "input"
  "keygen"
  "link"
  "meta"
  "param"
  "source"
  "track"
  "wbr"
}

-- https://html.spec.whatwg.org/multipage/syntax.html#cdata-rcdata-restrictions
raw_text_tags = {
  "script", "style"
  "textarea", "title" -- these are "escapable" raw text fields, that support using html entities
}

-- tag stack will be closed if an opening appears directly inside itself
-- see: https://html.spec.whatwg.org/multipage/syntax.html#optional-tags
-- mapping of "tag that can omit closing tag" -> "next adjacent tag that can cause it to happen"
-- value of true is the same as `node: {node}` (aka self reference)
optional_tags = {
  p: true

  optgroup: true
  option: {"option", "optgroup"}
  tr: true
  td: {"td", "tr", "th"}
  th: {"td", "tr", "th"}
  li: true
  thead: {"tbody", "tfoot"}
  tbody: {"tbody", "tfoot"}
}

{ :void_tags, :optional_tags, :raw_text_tags}
