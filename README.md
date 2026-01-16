# web\_sanitize

![test](https://github.com/leafo/web_sanitize/workflows/test/badge.svg)

A Lua library for working with HTML and CSS. It can do HTML and CSS
sanitization using a whitelist, along with general HTML parsing and
transformation. It also includes a query-selector syntax (similar to jQuery)
for scanning HTML.

**Security**: This library is used to parse and verify a large amount of
untrusted user generated content on production commercial applications. It is
actively monitored and updated for security issues. If you uncover any
vulnerabilities contact `leafot@gmail.com` with subject `web_sanitize security
vulnerability`. Do not publicly post security vulnerabilities on the issue
tracker. When in doubt, send private email.


* [HTML Sanitizer](#html-sanitizer)
* [HTML Parser/Scanner](#html-parser)

Examples:

```lua
local web_sanitize = require "web_sanitize"

-- Fix bad HTML
print(web_sanitize.sanitize_html(
  [[<h1 onload="alert('XSS')"> This HTML Stinks <ScRiPt>alert('hacked!')]]))
--  <h1> This HTML Stinks &lt;ScRiPt&gt;alert(&#x27;hacked!&#x27;)</h1>

-- Sanitize CSS properties
print(web_sanitize.sanitize_style([[border: 12px; behavior:url(script.htc);]]))
--  border: 12px

-- Extract text from HTML
print(web_sanitize.extract_text([[<div class="cool">Hello <b>world</b>!</div>]]))
-- Hello world!

```

## Install

```bash
$ luarocks install web_sanitize
```

## HTML Sanitizer

`web_sanitize` tries to preserve the structure of the input as best as possible
while sanitizing bad content. For HTML, tags that don't match a whitelist are
escaped and written as plain text. Attributes of accepted tags that don't match
the whitelist are stripped from the output. You can instruct the sanitizer to
insert your own attributes to tags as well, for example, all `a` tags will have
a `rel="nofollow"` attribute inserted by default configuration.

The sanitizer does not aim to be a complete HTML parser, but instead its goal
is to accept a strict subset of HTML and reject everything else. If you want a
more complete HTML parser you can use the [HTML Parser/Scanner](#html-parser)
described below.

Any unclosed tags that are approved will be closed at the end of the string.
This means it's safe to put sanitized HTML anywhere in an existing document
without worrying about breaking the structure.

If an outer tag is prematurely closed before the inner tags, the inner
tags will automatically be closed.

* `<li><b>Hello World` → `<li><b>Hello World</b></li>`
* `<li><b>Hello World</li>` → `<li><b>Hello World</b></li>`

## CSS Sanitizer

A whitelist is used to define an approved set of CSS properties, along with a
type specification for what kinds of parameters they can take. If a CSS
property is not in the whitelist, or does not match the type specification then
it is stripped from the output. Any valid CSS properties are preserved though.

## Function Reference

```lua
local web_sanitize = require("web_sanitize")
```

### HTML

#### `sanitize_html(unsafe_html)`

Sanitizes HTML using the whitelist located in `require "web_sanitize.whitelist"`

```lua
local safe_html = web_sanitize.sanitize_html("hi<script>alert('hi')</script>")
```

#### `extract_text(unsafe_html)`

Extracts just the textual content of unsafe HTML, returning valid HTML. No HTML
tags will be present in the output. There may be HTML escape sequences present
if the text contains any characters that might be interpreted as part of an
HTML tag (eg. a `<`).

```lua
local text = web_sanitize.extract_text("<div>hello <b>world</b></div>")
```

#### `unescape_html(text)`

Decodes HTML entities in a string. Supports:
- Named entities (`&amp;`, `&nbsp;`, `&eacute;`, etc.)
- Decimal numeric entities (`&#60;`, `&#8212;`)
- Hexadecimal numeric entities (`&#x3C;`, `&#x2014;`)

Unlike `extract_text`, this function does not strip HTML tags or modify whitespace - it only decodes entities.

```lua
local decoded = web_sanitize.unescape_html("Hello &amp; world &#x27;test&#x27;")
-- Returns: "Hello & world 'test'"
```

### CSS

#### `sanitize_style(unsafe_style_attributes)`

Sanitizes a list of CSS attributes (not an entire CSS file). Suitable for use
on the `style` HTML attribute.

```lua
local safe_style = web_sanitize.sanitize_style("border: 12px; behavior:url(script.htc);")
```

## Configuring The Whitelist

### HTML

The default whitelist provides a basic set of authorized HTML tags. Feel free
to submit a pull request if there is something missing.

Get access to the whitelist like so:

```lua
local whitelist = require "web_sanitize.whitelist"
```

Its recommended to make clone of the whitelist before modifying it:


```lua
local my_whitelist = whitelist:clone()

-- let iframes be used in sanitzied HTML
my_whitelist.tags.iframe = {
  width = true,
  height = true,
  frameborder = true,
  src = true,
}
```

In order to use your modified whitelist you'll need to instantiate a
`Sanitizer` object directly:


```lua
local Sanitizer = require("web_sanitize.html").Sanitizer
local sanitize_html = Sanitizer({whitelist = my_whitelist})

sanitize_html([[<iframe src="http://leafo.net" frameborder="0"></iframe>]])
```

See [`whitelist.moon`][2] for the default whitelist.

The whitelist table has three important fields:

* `tags`: a table of valid tag names and their corresponding valid attributes
* `add_attributes`: a table of attributes that should be inserted into a tag
* `self_closing`: a set of tags that don't need a closing tag

The `tags` field specifies tags that are possible to be used, and the
attributes that can be on them.

A attribute whitelist can be either a boolean, or a function. If it's a
function then it takes as arguments `value`, `attribute_name`, and `tag_name`.
If this function returns a string, then that value is used to replace the value
of the attribute. If it returns any other value, it's coerced into a boolean
and used to determine if the attribute should be kept.

For example, you could include `sanitize_style` in the HTML whitelist to allow
a subset of CSS:

```lua
local web_sanitize = require "web_sanitize"
local whitelist = require("web_sanitize.whitelist"):clone()

-- set the default style attribute handler
whitelist[1].style = function(value)
  return web_sanitize.sanitize_style(value)
end
```

The `add_attributes` can be used to inject additional attributes onto a tag.
The default whitelist contains a rule to make all links `nofollow`:

```lua
whitelist.add_attributes = {
  a =  {
    rel = "nofollow"
  }
}
```

As an example, you could change this to make it also add a `rel=noopener` as well:

```lua
whitelist.add_attributes.a = {
  rel = "nofollow noopener"
}
```

Add attributes can also also take a function to dynamically insert attribute
values based on the other attributes in the tag. The function will receive one
argument, a table of the parsed attributes. These are the attributes as written
in the original HTML, it does not reflect any changes the sanitizer will make
to the element. The function can return `nil` or `false` to make no changes, or
return a string to add an attribute containing that value.

Here's how you might add `nofollow noopener` to every link except those from a
certain domain:


```lua
whitelist.add_attributes.a = {
  rel = function(attr)
    for tuple in ipairs(attr) do
      if tuple[1]:lower() == "href" and not tuple[2]:match("^https?://leafo%.net/") then
        return "nofollow noopener"
      end
    end
  end
}
```

The format of the attributes argument has all attributes stored as `{name,
value}` tuples in the numeric indices, and the normalized (lowercase) attribute
name and value stored in the hash table component. The hash table component is
added for convenience. For security critical testing you should iterate over
the numerical components to make sure that no attributes are being shadowed.

This HTML will create the following object as the argument:

    <a href="http://leafo.net" HREF="http://itch.io" onclick="alert('hi')"></a>

```lua
{
  {"href", "http://leafo.net"},
  {"HREF", "http://itch.io"},
  {"onclick", "alert('hi')"},
  href = "http://itch.io",
  onclick = "alert('hi')",
}
```

### CSS

Similar to above, see [`css_whitelist.moon`][6]

## Customizing The Sanitizer

In addition to the `whitelist` option shown above, the sanitizer has the following options:

* `strip_tags` - *boolean* Remove unknown tags from output entirely, instead of escapting them as text default: `false`
* `strip_comments` - *boolean* Remove comments from output instead of escaping them, default: `false`

```lua
local Sanitizer = require("web_sanitize.html").Sanitizer
local sanitize_html = Sanitizer({strip_tags = true})

sanitize_html([[<body>Hello <strong>world</strong></body>]]) --> Hello <strong>world</strong>
```

## HTML Parser

The HTML parser lets you extract data from, and manipulate HTML using a minimal
Document Object Model and [query selector
syntax](https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector).
It attempts to follow the [HTML
spec](https://html.spec.whatwg.org/multipage/syntax.html) as best it can.

The scanner provies a lower level interface that lets you iterate through each
node in an HTML document using a callback. For each node parsed in the HTML
document a callback is called with an object representing the structure of the
document at the current location. This node supports mutating the document when
using the `replace_html` function.

```lua
local scanner = require("web_sanitize.query.scan_html")
```

Here are a few things to be aware of when using the scanner:

* The scanner performs a *depth first* scan: the callback is issued on a node after the closing tag for that node has been parsed.
* Any markup in *raw text* elements like `script`, `style`, `title` is ignored (unless it's the appropriate closing tag)
* Any markup inside HTML comments or CDATA sections is ignored
* Unclosed tags are considered dangling tags and will be processed after the parser reaches the end of the input (With the exception of void tags (eg. img, hr) which are always automatically closed regardless of if self closing (`<a/>`)  syntax is used.)
* Attributes automatically have their values HTML entities decoded (eg. &amp;amp; becomes &amp;)
* All edits are performed after the scan has taken place, not during the scan. If you alter the content of a node's inner or outer html then scanner will not see these changes in the current iteration. Additionally, making edits to a parent node's content will shadow any edits you've made to child nodes. You can work around these limitations by doing multi-pass replacements.
* Text nodes (when enabled) will treat CDATA tags as separate text nodes. Get the content with `inner_html` method. (`outer_html` will return the CDATA tag)

The scanner exposes two primitive object types: `NodeStack` and `HTMLNode`

`NodeStack` has the following methods and properties:

* `stack[n]` - get the nth item in the stack (as an `HTMLNode`)
* `stack:current()` - return the `HTMLNode` on top of the stack
* `stack:is(query)` - return `true` if the stack matches the query selector

`HTMLNode` has the following methods and properties:

* `node.tag` - the name of the tag (eg. `"div"`, `"span"`). Will be `""` for text nodes, and `"cdata"` for `CDATA` text nodes
* `node.type` - set to `"text_node"` for text nodes, `nil` otherwise
* `node.num` - integer representing what nth child position this node is (NOTE: this number changes depending on if text nodes are enabled or not)
* `node.self_closing` - `true` if the tag uses self closing syntax (`<a />`), `nil` otherwise
* `node.attr` - A table of attributes if the tag has attributes, `nil` otherwise. See attribute table format below
* `node:outer_html()` - get HTML fragment as string of the entire tag, including the opening and closing tag
* `node:inner_html()` - get HTML fragment as string of the content of the tag, excludes opening and closing tag
* `node:inner_text()` - get a string of the textual content inside the tag (effectively `extract_text(inner_html)`, using `extract_text` function described above)
* `node:replace_outer_html(html_text)` **(`replace_html` only)** - Replaces the entire tag with HTML fragment `html_text`
* `node:replace_inner_html(html_text)` **(`replace_html` only)** - Replaces the inside of the tag with HTML fragment `html_text`
* `node:replace_attributes(tbl)` **(`replace_html` only)** - Replaces all attributes on the tag with the table of attributes
* `node:update_attributes(tbl)` **(`replace_html` only)** - Merges a table of attributes with the current attributes, overwriting any of the existing ones (including duplicates) with the ones provided

The node attributes are stored in a table with both array and hash table
elements. The hash table elements have their keys normalized to lowercase and
only hold the most recent value.

```lua
-- <div first="value" first="&quot;hey&quot;" Hello=world readonly></div>
node.attr = {
  { "first", "value"},
  { "first", '"hey"'},
  { "Hello", "world"},
  { "readonly" },

  first = '"hey"',
  hello = "world",
  readonly = true
}
````

When updating or replacing attributes, the same table syntax is used as the
argument, but it will write duplicates if you have a single attribute repeated
in both the table and array format.

#### `scan_html(html_text, callback, opts)`

Scans over all nodes in the `html_text`, calling the `callback` function for
each node found. The callback receives one argument, an instance of a
`NodeStack`. A node stack is a Lua table holding an array of all the nodes in
the stack, with the top most node being the current one.

Each node in the node stack is an instance of `HTMLNode`. In `scan_html` the
node is read-only, and can be used to get the properties and content of the
node (eg. `inner_html`, `inner_text`, `outer_html`).

Here's how you might get the `href` and text of every `a` element in in an HTML string:

```lua
local scanner = require("web_sanitize.query.scan_html")

local my_html = [[
<ul>
  <li><a href="http://leafo.net">My homepage</a>
  <li><a href="http://github.com/leafo">My GitHub</a>
</ul>

<p>Also, don't forget to check out <a href="http://itch.io">itch.io</a>.</p>
]]

local urls = {}

scanner.scan_html(my_html, function(stack)
  if stack:is("a") then
    local node = stack:current()

    table.insert(urls, {
      url = node.attr.href,
      text = node:inner_text()
    })
  end
end)
```

You can optionally enable *text nodes* to have the parser emit a node for each
chunk of text. This includes text that is nested within a tag. Set `text_nodes`
to `true` in an options table passed as the last argument.

You can get the content of the node by calling either `inner_html` or
`outer_html`.

#### `replace_html(html_text, callback, opts)`

Works the same as `scan_html`, except each node in the stack is capable of
being mutated using the `replace_attributes`, `update_attributes`,
`replace_inner_html`, `replace_outer_html` methods.

Here's how you might convert all `a` tags that don't match a certain URL
pattern to plain text:

```lua
scanner.replace_html(my_html, function(stack)
  if stack:is("a") then
    local node = stack:current()
    local url = node.attr.href or ""

    if not url:match("^https?://leafo%.net") then
      node:replace_outer_html(node:inner_html())
    end
  end
end)
```

Text nodes can also be manipulated by `replace_html`. You can enable text nodes
by setting `text_nodes` to `true` in a options table passed as the last
argument. The text node can be updated by either calling `replace_outer_html`
or `replace_inner_html`.

For example, you might want to write a script that converts links to `a` tags,
but not when they're already inside an `a` tag:


```lua
local my_html = [[
  text that should be a link: http://leafo.net
  and a link that should be unchanged: <a href="https://itch.io">https://itch.io</a>
]]

local formatted_html = replace_html(my_html, function(stack)
  local node = stack:current()
  if node.tag == "" and not stack:is("a *, a") then
    node:replace_outer_html(node:outer_html():gsub("(https?://[^ <\"']+)", "<a href=\"%1\">%1</a>"))
  end
end, { text_nodes = true })

print(formatted_html)
```

## Fast?

It should be pretty fast. It's powered by the wonderful library [LPeg][3].
There is only one string concatenation on each call to `sanitize_html`. 200kb
of HTML can be sanitized in 0.01 seconds on my computer. This makes it
unnecessary in most circumstances to sanitize ahead of time when rendering
untrusted HTML.

## Tests

Requires [Busted][4] and [MoonScript][5].

```bash
make test
```

## Changelog

**Dec 16 2025** - 1.6.0

* Stricter `url()` parsing for CSS
* Fix bug where ident and url treated same in validation table

**May 16 2023** - 1.5.0

* The self closing `/>` syntax for immediately closing an opening tag is only accepted as valid if the tag type is listed in the `self_closing` object in the whitelist. Previously it would have been possible to write something like `<div/>` and have it pass through the sanitizer. This would cause the browser to render any subsequent content that doesn't close that nesting inside of that tag, allowing the input markup to influence the appearance of content outside the sanitized area.
* Update the default list of `self_closing` tags to include a few more common *void* tags.

**Oct 23 2022** - 1.4.0

**This is a critical update if you are using a custom white list with `iframe` elements allowed.** Due to their non-standard parsing within browsers it maybe be possible to craft HTML to bypass sanitization by using an element with an attribute value of a closing iframe tag. Those using the default whitelist are not affected.

* Make attribute escaping more strict:
  * Approved attributes passed through will now always have `<` and `>` characters in the value replaced with `&lt;` and `&gt;`
  * Injected attributes (attributes that are added despite not previously being there): The value will be escaped as HTML text to ensure invalid markup can't be returned by the injection function/literal
  * Injected attribute names will throw an error if using invalid characters (like `<` or `>`)
  * Note: Modified attributes will continue to function the same: the value provided is escaped as HTML text, (escaping `<` `>`, `&`, etc.)

**May 20 2022** - 1.3.0

This update includes a fix for the `stack overflow (too many captures)` error produced by LPeg when parsing too large of an input. The structure of the parser has been modified slightly when handing inputs that are over 10kb.

* Add separate pattern for sanitizing HTML inputs that are over 10kb
* Add an assertion when parsing query selectors with the scanning library

**Apr 09 2022** - 1.2.0

* Substantial updates to the HTML scanner/updater
  * Support parsing HTML comments (they will no longer be part of text nodes, any markup inside of a comment will be completely passed over)
  * Support parsing CDATA tags, markup inside of them will not be parsed. They are emitted as individual text nodes when text nodes are enabled (with tag set to `cdata` and type set to `text_node`)
  * Support parsing "raw text" tags like `script` and `style`. The content of these tags is read as text until the respective closing tag, no nested tags are parsed inside of them.
  * Support for parsing auto closing tags as defined by the HTML spec. This includes things like auto-closing `tr`, `td` tags when defining a table, or auto closing `li` tags when defining a list.
  * Support for auto closing `p` tags when an invalid block level tag is included inside
  * The format of the `attr` field on node now matches the format used on the HTML sanitizer. All attributes are included in tuple form (`{ key, value}` including duplicates) in the array portion of the table, and then lowercase key, values are stored as fields in the table, with the right most value overwriting any duplicates
  * Add `update_attributes` method on Node class for replacing rewriting an element's attributes with specified ones in addition to existing ones
  * `replace_attributes` will write all attributes both in tuple and table form (`{"hello", "world"}` and `{ hello = "world" }`, if you have multiple entries with the same name then they will all be written) The argument format is analogous to the `attr` field of a parsed node
  * Fix a bug for automatically closed tags due to parent closing was not working as intended. It caused the tag to be closed at the end of the document with the contents taking up the rest of the document
  * Be more diligent about reusing Lpeg patterns where possible to avoid extra allocations when running the scanner
  * Refactored parsing primitives to parse things more atomically (reducing use of `Cmt`)
* The HTML entity decoder now correctly respects that HTML entities are case sensitive
* Add more documentation for `scan_html`/`replace_html`, including interface for the node and stack
* Add `web_sanitize.patterns` module with some common patterns for parsing HTML (Although this module is undocumented, the interface should be relatively stable)

**Jan 26 2021** - 1.1.0

* Update text extractor
  * Add option for extracting as html or as plain text
  * Add option for removing non-printable characters
  * Add HTML entitiy translation when extracting as plain text
  * Whitespace trimming and normalization is utf8 whitespace aware
* Minor updates to CSS default whitelist for border attributes

**Jan 15  2020** - 1.0.0

* **Important** &mdash; Added fix where specially crafted HTML could sanitize to HTML with an unclosed tag
* Fixed whitespace preservation for text around self closing tags
* Updated CSS whitelist
* Added cache to `parse_query` for huge speedups when doing repeat matches

**Sep 08  2017** - 0.6.1

* Add support for callback to `add_attributes` for dynamically injecting an attribute into a tag

**May 09  2016** - 0.5.0

Sanitizer

* Add `clone` method to whitelist
* Add `Sanitizer` constructor, with `whitelist` and `strip_tags` options
* Add `Extractor` constructor

Scanner

* `replace_attributes` works correctly with boolean attributes, eg. `{allowfullscreen = true}`
* `replace_attributes` works correctly with void tags
* `replace_attributes` only manipulates text of opening tag, not entire tag, preventing any double edit bugs
* attribute order is preserved when mutating attributes with `replace_attributes`
* the `attr` object has array positional items with the names of the attributes in the order they were encountered

**Dec 27  2015** - 0.4.0

* Add query and scan implementations
* Add html rewrite interface, attribute rewriter
* Support Lua 5.2 and above (removed references to global `unpack`)

*Note: all of these things are undocumented at the moment, sorry. Check the specs for examples*

**Feb 1 2015** - 0.3.0

* Add `sanitize_css`
* Let attribute values be overwritten from whitelist
* `extract_text` collapses extra whitespace

**Oct 6 2014** - 0.2.0

* Add `extract_text` function
* Correctly parse protocol relative URLS in `href`/`src` attributes
* Correctly parse attributes that have no value

**April 16 2014** - 0.0.1

* Initial release

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))
License: MIT Copyright (c) 2020 Leaf Corcoran
Email: leafot@gmail.com
Homepage: <http://leafo.net>


 [1]: https://github.com/leafo/web_sanitize/blob/master/test.moon
 [2]: https://github.com/leafo/web_sanitize/blob/master/web_sanitize/whitelist.moon
 [3]: http://www.inf.puc-rio.br/~roberto/lpeg/
 [4]: http://olivinelabs.com/busted/
 [5]: http://moonscript.org
 [6]: https://github.com/leafo/web_sanitize/blob/master/web_sanitize/css_whitelist.moon
