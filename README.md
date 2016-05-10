# web\_sanitize

A Lua library for working with HTML and CSS. It can do HTML and CSS
sanitization using a whitelist, along with general HTML parsing and
transformation. It also includes a query-selector syntax (similar to jquery)
for scanning HTML.

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
* Support Lua 5.2 and above by remove direct references to unpack

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
