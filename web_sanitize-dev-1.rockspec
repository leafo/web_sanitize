package = "web_sanitize"
version = "dev-1"

source = {
  url = "git://github.com/leafo/web_sanitize.git",
}

description = {
  summary = "Lua library for sanitizing untrusted HTML",
  license = "MIT",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
}

dependencies = {
  "lua >= 5.1",
  "lpeg"
}

build = {
  type = "builtin",
  modules = {
    ["web_sanitize"] = "web_sanitize/init.lua",
    ["web_sanitize.whitelist"] = "web_sanitize/whitelist.lua",
  }
}
