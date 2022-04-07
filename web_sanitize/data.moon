
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

-- tag stack will be closed if one of these appears nested inside itself
unnestable_tags = {
  "td", "tr", "li"
}

{ :void_tags, :unnestable_tags, :raw_text_tags}
