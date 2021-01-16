import P, Cs, R, S from require "lpeg"

cont = R("\128\191")
utf8_codepoint = R("\194\223") * cont +
  R("\224\239") * cont * cont +
  R("\240\244") * cont * cont * cont

acceptable_character = S("\r\n\t") + R("\032\126") + utf8_codepoint
acceptable_string = acceptable_character^0 * P -1

strip_invalid_utf8 = do
  p = Cs (R("\0\127") + utf8_codepoint + P(1) / "")^0
  (text) -> p\match text

strip_bad_chars = do
  p = Cs (acceptable_character + P(1) / "")^0 * -1
  (text) -> p\match text

unpack = unpack or table.unpack

local lshift, rshift, band, bor, bnot


MAX_UNICODE = 0x10FFFF
_utf8_encode = (codepoint) ->
  assert codepoint and codepoint <= MAX_UNICODE, "invalid codepoint"

  if codepoint < 0x80
    string.char codepoint
  else
    unless lshift
      -- on 5.4 we only have bitwise operators
      _bit = unless bit or bit32
        (loadstring or load) [[
          return {
            lshift = function(x,y) return x << y end,
            rshift = function(x,y) return x >> y end,
            bor = function(x,y) return x | y end,
            band = function(x,y) return x ^ y end,
            bnot = function(x) return ~x end,
          }
        ]]

      { :lshift, :rshift, :band, :bor, :bnot } = (_bit and _bit!) or bit32 or require "bit"

    mfb = 0x3f
    chars = {}

    while true
      table.insert chars, 1, bor 0x80, band codepoint, 0x3f
      codepoint = rshift codepoint, 6
      mfb = rshift mfb, 1
      break unless codepoint > mfb

    remaining = bor lshift(bnot(mfb), 1), codepoint
    -- truncate to char
    remaining = band 0xFF, remaining

    table.insert chars, 1, remaining
    string.char unpack chars

-- default to using lua5.3 built in if available
utf8_encode = utf8 and utf8.char or _utf8_encode

{
  :strip_invalid_utf8
  :acceptable_character
  :acceptable_string
  :strip_bad_chars
  :_utf8_encode -- exposed for testing
  :utf8_encode
}
