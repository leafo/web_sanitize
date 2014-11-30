
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
