o = Map("koolproxy")

t = o:section(TypedSection, "usetips")
t.title = translate("GodProxy 帮助支持")
t.anonymous = true
t:append(Template("koolproxy/tips"))

return o
