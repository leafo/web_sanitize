
test:: build
	busted

build::
	moonc web_sanitize.moon web_sanitize/

local: build
	luarocks make --lua-version=5.1 --local web_sanitize-dev-1.rockspec

watch: build
	moonc -w web_sanitize.moon web_sanitize/

lint:
	moonc -l $$(find web_sanitize | grep moon$$)

