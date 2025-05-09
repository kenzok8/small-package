-- Copyright (C) 2023-2025 sirpdboy  <herboy2008@gmail.com>  https://github.com/sirpdboy/https://github.com/sirpdboy/luci-app-chatgpt-web

local m, s ,o

m = Map("chatgpt-web")
m.title = translate("Chatgpt Web")
m.description = translate("ChatGPT-Web is the version used on OPENWRT of OPENAI")..translate("</br>For specific usage, see:")..translate("<a href=\'https://github.com/sirpdboy/chatgpt-web.git' target=\'_blank\'>GitHub @sirpdboy/chatgpt-web\ </a>")

s = m:section(TypedSection, "basic", translate("Base Setting"))
s.addremove = false
s.anonymous = true


o = s:option(Value,"userpic",translate("Character images"))
o:value("girl.jpg",translate("girl"))
o:value("girl2.jpg",translate("girl2"))
o:value("girl3.jpg",translate("girl3"))
o:value("boy.jpg",translate("boy"))
o:value("boy2.jpg",translate("boy2"))
o:value("boy3.jpg",translate("boy3"))
o:value("dog.jpg",translate("dog"))
o:value("cartoon.jpg",translate("cartoon"))
o:value("cartoonboy.jpg",translate("cartoonboy"))
o:value("cartoonboy2.jpg",translate("cartoonboy2"))
o:value("cartoongirl.jpg",translate("cartoongirl"))
o:value("cartoongirl2.jpg",translate("cartoongirl2"))
o.rmempty = true
o.default="girl.jpg"


o=s:option(TextValue, "systemrole" ,translate("Default Role Settings"))
o.rows = 5
o.rmempty=false


return m
