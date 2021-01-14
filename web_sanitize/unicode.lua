local P, Cs, R, S
do
  local _obj_0 = require("lpeg")
  P, Cs, R, S = _obj_0.P, _obj_0.Cs, _obj_0.R, _obj_0.S
end
local cont = R("\128\191")
local utf8_codepoint = R("\194\223") * cont + R("\224\239") * cont * cont + R("\240\244") * cont * cont * cont
local has_utf8_codepoint
do
  local p = (1 - utf8_codepoint) ^ 0 * utf8_codepoint
  has_utf8_codepoint = function(str)
    return not not p:match(str)
  end
end
local acceptable_character = S("\r\n\t") + R("\032\126") + utf8_codepoint
local acceptable_string = acceptable_character ^ 0 * P(-1)
local strip_invalid_utf8
do
  local p = Cs((R("\0\127") + utf8_codepoint + P(1) / "") ^ 0)
  strip_invalid_utf8 = function(text)
    return p:match(text)
  end
end
local strip_bad_chars
do
  local p = Cs((acceptable_character + P(1) / "") ^ 0 * -1)
  strip_bad_chars = function(text)
    return p:match(text)
  end
end
return {
  utf8_codepoint = utf8_codepoint,
  has_utf8_codepoint = has_utf8_codepoint,
  strip_invalid_utf8 = strip_invalid_utf8,
  acceptable_character = acceptable_character,
  acceptable_string = acceptable_string,
  strip_bad_chars = strip_bad_chars
}
