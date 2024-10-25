m = Map("gecoosac", translate("集客AC控制器"), translate("用于统一批量管理集客AP的程序。"))

m:section(SimpleSection).template  = "gecoosac/gecoosac_status"

s = m:section(TypedSection, "gecoosac")
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "enabled", translate("启用"))
enable.rmempty = false

o = s:option(Value, "program_path", translate("程序路径"))
o.placeholder = "/usr/bin/gecoosac"
o.default     = "/usr/bin/gecoosac"
o.description = translate("可执行文件路径，权限为0755")
o.rmempty     = false

o = s:option(Value, "port", translate("监听端口"))
o.placeholder = 60650
o.default     = 60650
o.datatype    = "port"
o.rmempty     = false

o = s:option(Value, "upload_dir", translate("上传目录"))
o.placeholder = "/etc/gecoosac/upload/"
o.default     = "/etc/gecoosac/upload/"
o.rmempty     = false

o = s:option(Value, "db_dir", translate("数据库目录"))
o.placeholder = "/etc/gecoosac/"
o.default     = "/etc/gecoosac/"
o.rmempty     = false

o = s:option(Flag, "log", translate("启用日志"))
o.default = 1
o.rmempty = false

return m
