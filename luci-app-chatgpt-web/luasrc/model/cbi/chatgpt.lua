-- Copyright (C) 2023-2025 sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/luci-app-chatgpt-web
require("luci.util")
local m, s

m = Map("chatgpt-web",translate(""))

m:section(SimpleSection).template = "chatgpt-web"

return m
