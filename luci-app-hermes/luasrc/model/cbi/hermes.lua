-- LuCI - Lua Configuration Interface

local taskd = require "luci.model.tasks"
local hermes_model = require "luci.model.hermes"
local m, s, o

m = taskd.docker_map("hermes", "hermes", "/usr/libexec/istorec/hermes.sh",
	translate("Hermes"),
	translate("The self-improving AI agent that runs on your server. Choose the Native mise-runtime backend or the isolated Docker backend.")
		.. " " .. translate("Official website:") .. ' <a href="https://get-hermes.ai/" target="_blank">https://get-hermes.ai/</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("Only one backend is active at a time. A failed activation restores the previous healthy backend."))
s:append(Template("hermes/status"))

s = m:section(TypedSection, "main", translate("Setup"),
	translate("Select the backend to be activated by Install or Upgrade, then configure its tab."))
s.addremove = false
s.anonymous = true

o = s:option(ListValue, "target_backend", translate("Deployment backend") .. "<b>*</b>")
o:value("native", translate("Native (mise-runtime)"))
o:value("docker", translate("Docker"))
o.default = "native"
o.rmempty = false

s:tab("native", translate("Native"), translate("Runs directly under procd with a fixed Python supplied by mise-runtime. Docker is not required."))
s:tab("docker", translate("Docker"), translate("Runs in an isolated container. Docker must be installed separately."))

o = s:taboption("native", DummyValue, "_native_python", translate("Python runtime"))
o.rawhtml = true
function o.cfgvalue()
	return translate("Python 3.14.9 (mise-runtime, SHA-verified)")
end

o = s:taboption("native", Value, "native_base_dir", translate("Native data and runtime path") .. "<b>*</b>")
o.rmempty = false
o.datatype = "string"
local blocks = hermes_model.blocks()
for _, mountpoint in pairs(blocks) do
	o:value(mountpoint .. "/Configs/HermesNative", mountpoint .. "/Configs/HermesNative")
end

o = s:taboption("native", Value, "native_port", translate("Native port") .. "<b>*</b>")
o.default = "18787"
o.datatype = "port"
o.rmempty = false

o = s:taboption("native", ListValue, "native_bind", translate("Listen address"))
o:value("0.0.0.0", translate("All interfaces"))
o:value("127.0.0.1", translate("Localhost only"))
o.default = "0.0.0.0"

o = s:taboption("native", Flag, "native_install_accelerated", translate("Accelerate downloads with ks-cli"))
o.default = "0"
o.rmempty = false

o = s:taboption("docker", DummyValue, "_docker_image", translate("Pinned image"))
function o.cfgvalue()
	return "linkease/hermes@sha256:6958262de9d71633b81866e2b17f35c8662e2aaa9a91b0444d29d795b3b08763"
end

o = s:taboption("docker", Value, "port", translate("Docker port") .. "<b>*</b>")
o.default = "8787"
o.datatype = "port"
o.rmempty = false

o = s:taboption("docker", Value, "data_path", translate("Docker data path") .. "<b>*</b>")
o.rmempty = false
o.datatype = "string"
for _, mountpoint in pairs(blocks) do
	o:value(mountpoint .. "/Configs/HermesDocker/data", mountpoint .. "/Configs/HermesDocker/data")
end

o = s:taboption("docker", Value, "workspace_path", translate("Docker workspace path") .. "<b>*</b>")
o.rmempty = false
o.datatype = "string"
for _, mountpoint in pairs(blocks) do
	o:value(mountpoint .. "/Configs/HermesDocker/workspace", mountpoint .. "/Configs/HermesDocker/workspace")
end

return m
