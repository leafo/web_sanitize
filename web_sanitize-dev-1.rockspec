package = "web_sanitize"
version = "dev-1"

source = {
  url = "git://github.com/leafo/web_sanitize.git",
}

description = {
  summary = "Lua library for sanitizing and manipulating HTML & CSS",
  license = "MIT",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
  homepage = "https://github.com/leafo/web_sanitize",
}

dependencies = {
  "lua >= 5.1",
  "lpeg"
}

build = {
  type = "builtin",
  modules = {
    ["web_sanitize"] = "web_sanitize/init.lua",
    ["web_sanitize.css"] = "web_sanitize/css.lua",
    ["web_sanitize.css_types"] = "web_sanitize/css_types.lua",
    ["web_sanitize.css_whitelist"] = "web_sanitize/css_whitelist.lua",
    ["web_sanitize.data"] = "web_sanitize/data.lua",
    ["web_sanitize.html"] = "web_sanitize/html.lua",
    ["web_sanitize.query"] = "web_sanitize/query.lua",
    ["web_sanitize.query.parse_query"] = "web_sanitize/query/parse_query.lua",
    ["web_sanitize.query.scan_html"] = "web_sanitize/query/scan_html.lua",
    ["web_sanitize.whitelist"] = "web_sanitize/whitelist.lua",
  }
}
