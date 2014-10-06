# web\_sanitize

A Lua library for doing HTML sanitization using a whitelist.

Example:

```lua
local web_sanitize = require "web_sanitize"
print(web_sanitize.sanitize_html([[<h1 onload="alert('XSS')"> This HTML Stinks <ScRiPt>alert('hacked!')]]))
--  <h1> This HTML Stinks &lt;ScRiPt&gt;alert(&#x27;hacked!&#x27;)</h1>
```

## Install

```bash
$ luarocks install http://rocks.moonscript.org/web_sanitize-dev-1.rockspec
```

## How

`web_sanitize` tries to preserve the structure of the input as best as possible
while sanitizing bad content. Tags that don't match a whitelist are replaced
with their escaped equivalent. Attributes of tags that don't match the
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

## Functions

#### `sanitize_html(unsafe_html)`

Sanitizes HTML using the whitelist located in `require "web_sanitize.whitelist"`

#### `extract_text(unsafe_html)`

Extracts just the textual content of unsafe HTML. No HTML tags will be present
in the the output. There may be HTML escape sequences present if the text
contains any characters that might be interpreted as part of an HTML tag (eg. a
`<`).

## Configuring The Whitelist

The default whitelist should be adequate but you can configure it. (Feel free
to submit a pull request if there is something missing)

Get access to the whitelist like so:

```lua
local tags = require "web_sanitize.whitelist"
```

See [`whitelist.moon`][2] for an example of the default whitelist.

The returned table has three important items:

* `tags`: a table of valid tag names and their corresponding valid attributes
* `add_attributes`: a table of attributes that should be inserted into a tag
* `self_closing`: a set of tags that should not be automatically closed

## Fast?

It should be pretty fast. It's powered by the wonderful library [LPEG][3]. There is
only one string concatenation on each call to `sanitize_html`. 200kb of HTML
can be sanitized in 0.01 seconds on my computer.

## Tests

Requires [Busted][4] and [MoonScript][5].

```bash
make test
```

## Changelog

**Oct 6 2014** - 0.2.0

* Add `extract_text` function
* Correctly parse protocol relative URLS in href/src attributes
* Correctly parse attributes that have no value

**April 16 2014** - 0.0.1

* Initial release

## TODO

* Automatic link conversion
* Option to strip all tags
* Add CSS sanitization

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))  
Email: leafot@gmail.com  
Homepage: <http://leafo.net>  


 [1]: https://github.com/leafo/web_sanitize/blob/master/test.moon
 [2]: https://github.com/leafo/web_sanitize/blob/master/web_sanitize/whitelist.moon
 [3]: http://www.inf.puc-rio.br/~roberto/lpeg/
 [4]: http://olivinelabs.com/busted/
 [5]: http://moonscript.org
