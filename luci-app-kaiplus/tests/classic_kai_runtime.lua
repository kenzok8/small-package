-- Real sources are embedded by the Python runner. All I/O is stubbed, so this
-- harness can also run over SSH without changing the device's files or services.
local checks = 0
local function check(value, message)
	assert(value, message)
	checks = checks + 1
end
local runtime_files = { "/usr/sbin/kai_bin", "/usr/sbin/kai_session", "/etc/init.d/kai", "/etc/config/kai", "/usr/share/kai/kai-plugin.json" }
local function fixture(o)
	o = o or {}
	local f = { calls = {}, routes = {} }
	local files = { ["/etc/config/kaiplus"] = true, ["/etc/init.d/tasks"] = true, ["/bin/is-opkg"] = true, ["/usr/libexec/kaiplus-classic"] = true }
	if o.installed then for _, path in ipairs(runtime_files) do files[path] = true end end
	if o.missing then files[o.missing] = nil end
	local fs = { access = function(path) return files[path] end }
	local sys = {
		call = function(command)
			f.calls[#f.calls + 1] = command
			if command:match("^pidof kai_bin") then return o.running and 0 or 1 end
			return o.rc or 0
		end,
		exec = function(command) f.task_query = command; return "task status fixture" end
	}
	package.loaded["nixio.fs"], package.loaded["luci.sys"] = fs, sys
	package.loaded["luci.jsonc"] = { parse = function() return o.task_status or {} end }
	package.loaded["luci.util"] = { shellquote = function(v) return "'" .. v:gsub("'", "'\\''") .. "'" end }
	package.loaded["luci.http"] = {
		getenv = function() return o.method or "POST" end,
		formvalue = function() return o.token or "valid-token" end,
		prepare_content = function() end,
		write_json = function(v) f.reply = v end,
		status = function(v) f.code = v end
	}
	package.loaded["luci.dispatcher"] = { context = { authsession = "session", token = "valid-token" } }
	if o.no_session then package.loaded["luci.dispatcher"].context.authsession = nil end
	f.classic = assert(loadstring(sources.classic))()
	package.loaded["luci.model.kaiplus.classic"] = f.classic
	f.paths = assert(loadstring(sources.paths))()
	f.paths.blocks = function() return {} end
	f.paths.home = function() return { Configs = "/mnt/test/Configs" } end
	package.loaded["luci.model.kaiplus"] = f.paths
	local cursor = { get_first = function(_, config, section, key)
		check(config == "kai" and section == "kai" and key == "enabled", "form must read only KAI configuration")
		return o.enabled or "0"
	end }
	local env = setmetatable({
		module = function() end, nixio = { fs = fs },
		_ = function(v) return v end, translate = function(v) return v end,
		entry = function(path, target)
			local r = { target = target }; f.routes[table.concat(path, "/")] = r; return r
		end,
		alias = function(...) return { kind = "alias", path = table.concat({...}, "/") } end,
		cbi = function(name) return { name = name } end,
		call = function(name) return { name = name } end,
		SimpleSection = {}, TypedSection = {}, Flag = {}, Value = {}
	}, { __index = _G })
	local function form(kind, name)
		local m = { kind = kind, name = name, sections = {}, uci = cursor }
		function m:section()
			local s = { fields = {} }
			function s:option(_, key)
				local field = { values = {} }
				function field:value(v) self.values[#self.values + 1] = v end
				self.fields[key] = field; return field
			end
			self.sections[#self.sections + 1] = s; return s
		end
		return m
	end
	env.Map = function(name) return form("map", name) end
	env.SimpleForm = function(name) return form("simple", name) end
	local function load(source)
		local chunk = assert(loadstring(source)); setfenv(chunk, env); return chunk()
	end
	load(sources.controller)
	f.controller, f.form = env, function() return load(sources.form) end
	return f
end

local f = fixture()
f.controller.index()
check(f.routes["admin/services/kaiplus"].target.kind == "alias", "root entry must keep working")
check(f.routes["admin/services/kaiplus/settings"].target.name == "kaiplus", "KaiPlus settings missing")
check(f.routes["admin/services/kaiplus/classic"].target.name == "kaiplus/classic", "classic tab must exist without KAI")
check(f.routes["admin/services/kaiplus/update_kai"].target.name == "update_kai", "update route missing")
f.controller.classic_status()
check(f.reply.installed == false and f.reply.running == false, "missing KAI status")
f = fixture({ installed = true, running = true })
f.controller.classic_status()
check(f.reply.installed and f.reply.running, "runtime must work without luci-app-kai")
check(f.calls[1] == "pidof kai_bin >/dev/null", "status must use classic process")
for _, path in ipairs(runtime_files) do
	f = fixture({ installed = true, missing = path })
	check(not f.classic.installed(), "incomplete runtime must not be installed: " .. path)
end
for _, o in ipairs({ { method = "GET" }, { token = "wrong" }, { no_session = true } }) do
	f = fixture(o); f.controller.install_kai()
	check(f.code == (o.method == "GET" and 405 or 403), "install requires POST, session and CSRF")
	check(#f.calls == 0 and not f.task_query, "rejected install must not execute commands")
	o.installed = true
	f = fixture(o); f.controller.update_kai()
	check(f.code == (o.method == "GET" and 405 or 403), "update requires POST, session and CSRF")
	check(#f.calls == 0 and not f.task_query, "rejected update must not execute commands")
end
f = fixture(); f.controller.install_kai()
check(f.reply.ok and f.reply.task_id == "kaiplus-kai-install", "install task missing")
check(#f.calls == 1 and f.calls[1]:find("/usr/libexec/kaiplus%-classic install"), "install optional runtime")
check(not f.calls[1]:find("luci%-app%-kai") and not f.calls[1]:find("/etc/init.d/kaiplus"), "install must not depend on old LuCI or restart KaiPlus")
f = fixture({ installed = true }); f.controller.install_kai()
check(f.reply.ok and f.reply.installed and #f.calls == 0, "already installed must be a no-op")
f = fixture(); f.controller.update_kai()
check(f.code == 409 and not f.reply.ok and #f.calls == 0, "update must not install an absent runtime")
f = fixture({ installed = true }); f.controller.update_kai()
check(f.reply.ok and f.reply.task_id == "kaiplus-kai-install", "update must share the installation task lock")
check(#f.calls == 1 and f.calls[1]:find("/usr/libexec/kaiplus%-classic update"), "queue classic update")
for _, running in ipairs({ true, 1, "1", "true" }) do
	f = fixture({ task_status = { running = running } }); f.controller.install_kai()
	check(f.reply.ok and f.reply.busy and #f.calls == 0, "do not duplicate busy installation")
	f = fixture({ installed = true, task_status = { running = running } }); f.controller.update_kai()
	check(f.reply.ok and f.reply.busy and #f.calls == 0, "install/update tasks must not overlap")
end
for _, path in ipairs({ "/etc/init.d/tasks", "/bin/is-opkg", "/usr/libexec/kaiplus-classic" }) do
	f = fixture({ missing = path }); f.controller.install_kai()
	check(not f.reply.ok and #f.calls == 0, "report unavailable installation support")
	f = fixture({ installed = true, missing = path }); f.controller.update_kai()
	check(not f.reply.ok and #f.calls == 0, "report unavailable update support")
end
f = fixture({ rc = 1 }); f.controller.install_kai()
check(not f.reply.ok and f.reply.task_id, "report task submission failure")
f = fixture({ installed = true, rc = 1 }); f.controller.update_kai()
check(not f.reply.ok and f.reply.task_id, "report update submission failure")
f = fixture()
local m = f.form()
check(m.kind == "simple" and m.submit == false and m.reset == false, "uninstalled tab must not create UCI form")
check(#f.calls == 0, "viewing tab must not start services")
f = fixture({ installed = true, enabled = "1" }); m = f.form()
check(m.kind == "map" and m.name == "kai", "edit original KAI configuration")
check(m.sections[2].fields.data_dir.default == "/mnt/test/Configs/KAI", "separate data directory")
check(m.sections[2].fields.port.default == "8197" and m.sections[2].fields.port.datatype == "port", "validated classic port")
m:on_after_commit()
check(#f.calls == 1 and f.calls[1] == "/etc/init.d/kai restart >/dev/null 2>&1", "apply must restart only KAI")
f = fixture({ installed = true, enabled = "0" }); m = f.form(); m:on_after_commit()
check(#f.calls == 1 and f.calls[1] == "/etc/init.d/kai stop >/dev/null 2>&1", "disable must stop only KAI")
f = fixture({ installed = true, enabled = "1", rc = 1 }); m = f.form(); m:on_after_commit()
check(m.message ~= nil, "report service operation failure")
local _, plus = f.paths.find_paths({}, { Configs = "/mnt/test/Configs" }, "Configs")
local _, classic = f.paths.find_paths({}, { Configs = "/mnt/test/Configs" }, "Configs", "KAI")
check(plus == "/mnt/test/Configs/KAIPlus" and classic == "/mnt/test/Configs/KAI", "preserve independent path defaults")
local _, fallback = f.paths.find_paths({ "/mnt/data" }, { Configs = "/root/Configs" }, "Configs", "KAI")
check(fallback == "/mnt/data/Configs/KAI", "preserve KAI disk selection")
print(checks .. " classic KAI runtime checks passed")
