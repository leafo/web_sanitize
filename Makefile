
build::
	moonc test.moon web_sanitize.moon web_sanitize/

watch: build
	moonc -w test.moon web_sanitize.moon web_sanitize/

test:: build
	busted test.lua
