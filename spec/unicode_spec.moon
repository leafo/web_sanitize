
MAX_CODEPOINT = 0xFFFF

describe "unicode", ->
  it "_utf8_encode", ->
    -- we use cjson valid implementation to verify our own utf8 encode function (up to FFFF)
    json = require "cjson"

    -- is pure lua version that depends on bit library
    import _utf8_encode from require "web_sanitize.unicode"

    count = 0

    for codepoint=1,MAX_CODEPOINT
      hex = "%04x"\format codepoint
      local expected
      pcall ->
        expected = json.decode "\"\\u#{hex}\""

      continue unless expected
      count += 1

      assert expected == _utf8_encode codepoint



