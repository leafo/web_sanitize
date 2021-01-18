local P, Cs, R, S
do
  local _obj_0 = require("lpeg")
  P, Cs, R, S = _obj_0.P, _obj_0.Cs, _obj_0.R, _obj_0.S
end
local cont = R("\128\191")
local utf8_codepoint = R("\194\223") * cont + R("\224\239") * cont * cont + R("\240\244") * cont * cont * cont
local whitespace = S("\13\32\10\11\12\9") + P("\239\187\191") + P("\194") * S("\133\160") + P("\225") * (P("\154\128") + P("\160\142")) + P("\226") * (P("\128") * S("\131\135\139\128\132\136\140\175\129\133\168\141\130\134\169\138\137") + P("\129") * S("\159\160")) + P("\227\128\128")
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
local unpack = unpack or table.unpack
local lshift, rshift, band, bor, bnot
local MAX_UNICODE = 0x10FFFF
local _utf8_encode
_utf8_encode = function(codepoint)
  assert(codepoint and codepoint <= MAX_UNICODE, "invalid codepoint")
  if codepoint < 0x80 then
    return string.char(codepoint)
  else
    if not (lshift) then
      local _bit
      if not (bit or bit32) then
        _bit = (loadstring or load)([[          return {
            lshift = function(x,y) return x << y end,
            rshift = function(x,y) return x >> y end,
            bor = function(x,y) return x | y end,
            band = function(x,y) return x & y end,
            bnot = function(x) return ~x end,
          }
        ]])
      end
      do
        local _obj_0 = (_bit and _bit()) or bit32 or require("bit")
        lshift, rshift, band, bor, bnot = _obj_0.lshift, _obj_0.rshift, _obj_0.band, _obj_0.bor, _obj_0.bnot
      end
    end
    local mfb = 0x3f
    local chars = { }
    while true do
      table.insert(chars, 1, bor(0x80, band(codepoint, 0x3f)))
      codepoint = rshift(codepoint, 6)
      mfb = rshift(mfb, 1)
      if not (codepoint > mfb) then
        break
      end
    end
    local remaining = bor(lshift(bnot(mfb), 1), codepoint)
    remaining = band(0xFF, remaining)
    table.insert(chars, 1, remaining)
    return string.char(unpack(chars))
  end
end
local utf8_encode = utf8 and utf8.char or _utf8_encode
return {
  strip_invalid_utf8 = strip_invalid_utf8,
  acceptable_character = acceptable_character,
  acceptable_string = acceptable_string,
  strip_bad_chars = strip_bad_chars,
  _utf8_encode = _utf8_encode,
  utf8_encode = utf8_encode
}
