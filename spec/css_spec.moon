
describe "css_types", ->
  import Number, String, check_type from require "web_sanitize.css_types"

  it "should match type pattern", ->
    assert.truthy check_type "ss", String * String

  it "should not match type pattern with extra type", ->
    assert.falsy check_type "sss", String * String

  it "should match a repeating type pattern", ->
    assert.truthy check_type "sn", (String * Number)^1
    assert.truthy check_type "snsn", (String * Number)^1
    assert.falsy check_type "snsns", (String * Number)^1


describe "sanitize_style", ->
  import sanitize_style from require "web_sanitize.css"
  it "should pass through empty string", ->
    assert.same "", (sanitize_style "")
    assert.same "", (sanitize_style "  ")

  check = (expected, given) ->
    if expected
      it "should sanitize `#{given}`", ->
        assert.same expected, (sanitize_style given)
    else
      it "should reject `#{given}`", ->
        assert.same nil, (sanitize_style given)

  check "margin-left: 50px", "margin-left: 50px;"
  check "margin-left: 50px", "margin-left: 50px"
  check "margin-left: hello", "margin-left: hello"
  check "", "padding-left: hello"

  check "margin: 10em 10em 10em 10em","margin: 10em 10em 10em 10em;"
  check "margin: 10em 10em", "margin: 10em 10em;"
  check "margin: 10em 10em 12em", "margin: 10em 10em 12em;"
  check "", "margin: 10em 10em 10em 10em 23px;"

  check "", "fake-property: 100"
  check "margin: 10px; margin: 10px", "margin: 10px; fake-property: 100; margin: 10px"

  check "text-align: left", "text-align: left;"
  check "font-size: 150%", "font-size: 150%"

  check "color: red", "color: red"
  check "color: #fff", "color: #fff"
  check "color: rgba(0.2,0.3,232)", "color: rgba(0.2,0.3,232)"

  check "opacity: 0.3", "opacity: 0.3"

  check "border: 0; width: 400px; height: 208px", "border: 0; width: 400px; height: 208px;"
  check "border: 23px; border-color: #fff", "border: 23px; border-color: #fff"
  check nil, "border: "
  check "border: 1px solid blue", "border: 1px solid blue"
  check "border-width: 1px 2px", "border-width: 1px 2px"

  -- invalid syntax
  check nil, "background: url(http://example.com/image.png)"
  check nil, "background: url(https://example.com/image.png)"
  check nil, "background: url(javascript:alert(1))"

  -- quoted URLs with bad protocols are stripped
  check "", "background: url(\"javascript:alert(1)\")"
  check "", "background: url('javascript:alert(1)')"
  check "", "background: url(\"data:text/html,<script>alert(1)</script>\")"
  check "", "background: url(\"vbscript:alert(1)\")"
  check "", "background-image: url(\"javascript:alert(1)\")"

  -- allow http and https protocols
  check "background: url(\"https://example.com/image.png\")", "background: url(\"https://example.com/image.png\")"
  check "background: url(\"http://example.com/image.png\")", "background: url(\"http://example.com/image.png\")"
  check "background: url('https://example.com/image.png')", "background: url('https://example.com/image.png')"
  check "background-image: url(\"https://example.com/bg.jpg\")", "background-image: url(\"https://example.com/bg.jpg\")"
  check "background-image: url(\"http://example.com/bg.jpg\")", "background-image: url(\"http://example.com/bg.jpg\")"

  -- URL not allowed on other properties
  check "", "margin-left: url(\"https://example.com/image.png\")"
  check "", "text-align: url(\"https://example.com/image.png\")"
  check "", "color: url(\"https://example.com/image.png\")"

  -- background-image with ident (like 'none')
  check "background-image: none", "background-image: none"

