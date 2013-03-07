
build::
	moonc test.moon web_sanitize.moon web_sanitize/

local: build
	luarocks make --local web_sanitize-dev-1.rockspec

watch: build
	moonc -w test.moon web_sanitize.moon web_sanitize/

test:: build
	busted test.lua
