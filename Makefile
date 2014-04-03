
test:: build
	busted

build::
	moonc web_sanitize.moon web_sanitize/

local: build
	luarocks make --local web_sanitize-dev-1.rockspec

watch: build
	moonc -w web_sanitize.moon web_sanitize/

