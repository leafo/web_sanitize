# web\_sanitize

[![Build Status](https://travis-ci.org/leafo/web_sanitize.svg?branch=master)](https://travis-ci.org/leafo/web_sanitize)

A Lua library for working with HTML and CSS. It can do HTML and CSS
sanitization using a whitelist, along with general HTML parsing and
transformation. It also includes a query-selector syntax (similar to jquery)
for scanning HTML.

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
replaced with their escaped equivalent. Attributes of tags that don't match the
whitelist are stripped from the output. You can excplicitly add your own
attributes to tags as well, for example, all `a` tags will have a
`rel="nofollow"` attribute inserted by default

Any unclosed tags will be closed at the end of the string. This means it's safe
to put sanitized HTML anywhere in an existing document without worrying about
breaking the structure.

If an outer tag is prematurely closed before the inner tags, the inner
tags will automatically be closed.

* `<li><b>Hello World` → `<li><b>Hello World</b></li>`
* `<li><b>Hello World</li>` → `<li><b>Hello World</b></li>`


For CSS, a whitelist is used to define an approved set of CSS properties, along
with a type specification for what kinds of parameters they can take. If a CSS
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

Extracts just the textual content of unsafe HTML. No HTML tags will be present
in the the output. There may be HTML escape sequences present if the text
contains any characters that might be interpreted as part of an HTML tag (eg. a
`<`).

```lua
local text = web_sanitize.extract_text("<div>hello <b>world</b></div>")
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
The default whitelist contians a rule to make all links `nofollow`:

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

* `strip_tags` - *boolean* Remove unknown tags from output entirely, default: `false`
* `strip_comments` - *boolean* Remove comments from output instead of escaping them, default: `false`

```lua
local Sanitizer = require("web_sanitize.html").Sanitizer
local sanitize_html = Sanitizer({strip_tags = true})

sanitize_html([[<body>Hello world</body>]]) --> Hello world
```


## HTML Parser

The HTML parser lets you extract data from, and manipulate HTML using [query
selector
syntax](https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector).


The scanner interface is a lower level interface that lets you iterate through
each node in the HTML document. It's located in the
`web_sanitize.query.scan_html` module.


```lua
local scanner = require("web_sanitize.query.scan_html")
```

#### `scan_html(html_text, callback, opts)`

Scans over all nodes in the `html_text`, calling the `callback` function for
each node found. The callback recieves one argument, an instance of a
`NodeStack`. A node stack is a Lua table holding an array of all the nodes in
the stack, with the top most node being the current one.

Each node in the node stack is an instance of `HTMLNode`. In `scan_html` the
node is read-only, and can be used to get the properties and content of the
node.

Here's how you might get the `href` and text of every `a` tag in the html:

```lua
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

Text nodes have the `tag` attribute set to `""` (empty string). You can get the
content of the node by calling either `inner_html` or `outer_html`.

#### `replace_html(html_text, callback, opts)`

Works the same as `scan_html`, except each node in the stack is capable of
being mutated using the `replace_attributes`, `replace_inner_html`,
`replace_outer_html` methods.

Here's how you might conver all `a` tags that don't match a certain URL
pattern to plain text:

```lua
scanner.replace_html(my_html, function(stack)
  if stack:is("a") then
    local node = stack:current()
    let url = node.attr.href or ""

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

**Sep 08  2017** - 0.6.0

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
* Correctly parse protocol relative URLS in href/src attributes
* Correctly parse attributes that have no value

**April 16 2014** - 0.0.1

* Initial release

## TODO

* Automatic link conversion

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))
License: MIT Copyright (c) 2015 Leaf Corcoran
Email: leafot@gmail.com
Homepage: <http://leafo.net>


 [1]: https://github.com/leafo/web_sanitize/blob/master/test.moon
 [2]: https://github.com/leafo/web_sanitize/blob/master/web_sanitize/whitelist.moon
 [3]: http://www.inf.puc-rio.br/~roberto/lpeg/
 [4]: http://olivinelabs.com/busted/
 [5]: http://moonscript.org
 [6]: https://github.com/leafo/web_sanitize/blob/master/web_sanitize/css_whitelist.moon
