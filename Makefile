
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

make_entities::
	curl -O https://html.spec.whatwg.org/entities.json
	moon make_entities.moon > web_sanitize/html_named_entities.lua


