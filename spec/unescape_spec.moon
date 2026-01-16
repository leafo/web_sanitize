
describe "web_sanitize unescape_html", ->
  import unescape_html from require "web_sanitize"
  import utf8_encode from require "web_sanitize.unicode"

  it "decodes long named entities", ->
    assert.same utf8_encode(0x2233), unescape_html "&CounterClockwiseContourIntegral;"

  it "decodes 6-digit hex numeric entities", ->
    assert.same utf8_encode(0x1F4A9), unescape_html "&#x1F4A9;"

  it "decodes legacy named entities without semicolon when bounded", ->
    assert.same "A & B", unescape_html "A &amp B"

  it "does not decode legacy named entities before '='", ->
    assert.same "A &amp=1", unescape_html "A &amp=1"

  it "does not decode legacy named entities before alphanum", ->
    assert.same "A &ampx", unescape_html "A &ampx"

  it "decodes common named entities with semicolons", ->
    assert.same "A & B", unescape_html "A &amp; B"
    assert.same "A & B", unescape_html "A &AMP; B"
    assert.same "A & B", unescape_html "A &Amp; B"

  it "decodes nbsp to U+00A0", ->
    assert.same "A#{utf8_encode(0xA0)}B", unescape_html "A&nbsp;B"

  it "decodes decimal numeric entities", ->
    assert.same "<", unescape_html "&#60;"

  it "decodes hex numeric entities without semicolons", ->
    assert.same "<", unescape_html "&#x3C"
    assert.same "<", unescape_html "&#X3c"

  it "leaves unknown named entities unchanged", ->
    assert.same "A &notareal; B", unescape_html "A &notareal; B"

  it "leaves invalid numeric entities unchanged", ->
    assert.same "A &#x; B", unescape_html "A &#x; B"
    assert.same "A &#x110000; B", unescape_html "A &#x110000; B"
