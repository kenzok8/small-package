api = require "luci.passwall2.api"
appname = api.appname
fs = api.fs

api.set_default_cbi()

m = Map("passwall2_server", translate("User Config"))
m.redirect = api.url("server")
api.set_apply_on_parse(m)

if not arg[1] or not m:get(arg[1]) then
	luci.http.redirect(m.redirect)
end

s = m:section(NamedSection, arg[1], "user", "")
s.addremove = false
s.dynamic = false

o = s:option(Value, "username", translate("Username"))
o.datatype = "and(uciname,maxlength(24))"
o.rmempty = false

o = s:option(Value, "password",  translate("Password"))
o.rmempty = false

o = s:option(Value, "uuid",  "UUID")
o.datatype = "uuid"
o.default = api.gen_uuid()
o.rmempty = false

return api.return_map(m)
