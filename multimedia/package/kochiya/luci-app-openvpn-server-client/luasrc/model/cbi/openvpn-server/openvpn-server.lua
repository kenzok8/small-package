--[[
LuCI - Lua Configuration Interface

Copyright 2025 LunaticKochiya<125438787@qq.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

--require("luci.tools.webadmin")

local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"

local function get_openvpn_info()
    local version_str = sys.exec("openvpn --version 2>/dev/null | head -n1")
    local full_output = sys.exec("openvpn --version 2>/dev/null")

    local major, minor, patch = version_str:match("OpenVPN%s+(%d+)%.(%d+)%.(%d+)")
    if not (major and minor and patch) then
        return nil, nil, nil, false
    end

    local lzo_supported = full_output:match("%[LZO%]") ~= nil

    return tonumber(major), tonumber(minor), tonumber(patch), lzo_supported
end

local major, minor, patch, lzo = get_openvpn_info()

mp = Map("openvpn", "OpenVPN Server",translate("An easy config OpenVPN Server Web-UI"))

mp:section(SimpleSection).template  = "openvpn/openvpn_status"

s = mp:section(TypedSection, "openvpn")
s.anonymous = true
s.addremove = false


s.filter = function(self, section)
    return section:match("^myvpn") ~= nil
end

s:tab("basic",  translate("Base Setting"))

o = s:taboption("basic", Flag, "enabled", translate("Enable"))

port = s:taboption("basic", Value, "port", translate("Port"))
port.datatype = "range(1,65535)"

ddns = s:taboption("basic", Value, "ddns", translate("WAN DDNS or IP"))
ddns.datatype = "string"
ddns.default = "exmple.com"
ddns.rmempty = false

localnet = s:taboption("basic", Value, "server", translate("Client Network"))
localnet.datatype = "string"
localnet.description = translate("VPN Client Network IP with subnet")

proto = s:taboption("basic",Value,"proto", translate("proto"))
proto.datatype = "string"
proto:value("tcp4")
proto:value("udp4")
proto:value("tcp6")
proto:value("udp6")
proto.default ="tcp4"

if (major > 2) or (major == 2 and minor >= 6) then
disable_dco = s:taboption("basic",Flag,"disable_dco", translate("disable dco"))
disable_dco.description = translate("Disabling DCO provides better compatibility but disables acceleration.")
end

if (major > 2) or (major == 2 and minor >= 5) then
allow_compression = s:taboption("basic",Value,"allow_compression", translate("Allow Compression"))
allow_compression.datatype = "string"
allow_compression:value("asym")
allow_compression:value("yes")
allow_compression:value("no")
allow_compression.default="asym"
allow_compression.description = translate("Allow compression, DCO can only be used when set to NO. asym is compatible mode.")

push_peer_info = s:taboption("basic",Flag,"push_peer_info", translate("push peer info"))
push_peer_info.description = translate("This will allow the server to know more info about the client like HWADDR, very useful for managing IoT devices.")

end

if lzo then
comp_lzo = s:taboption("basic",Value,"comp_lzo", translate("comp_lzo"))
comp_lzo.datatype = "string"
comp_lzo:value("adaptive")
comp_lzo:value("yes")
comp_lzo:value("no")
if (major > 2) or (major == 2 and minor >= 5) then
comp_lzo:depends("allow_compression", "yes")
comp_lzo:depends("allow_compression", "asym")
comp_lzo:depends("comp_lzo", "yes")
comp_lzo:depends("comp_lzo", "adaptive")
comp_lzo.default="adaptive"
else
comp_lzo:depends("comp_lzo", "yes")
comp_lzo:depends("comp_lzo", "adaptive")
comp_lzo.default="adaptive"
end
comp_lzo.description = translate("Using LZO compression, it does not support versions above 2.5.X, does not support DCO; if your version number is greater than this version, select NO to disable it.")
end

auth_user_pass_verify = s:taboption("basic",Value,"auth_user_pass_verify", translate("user password verify"))
auth_user_pass_verify.datatype = "string"
auth_user_pass_verify.description = translate("Default: /etc/openvpn/server/checkpsw.sh via-env, leave it empty to disable")

script_security = s:taboption("basic",Value,"script_security", translate("script_security: to use with user and password"))
script_security.datatype = "range(1,3)"
script_security:value("1")
script_security:value("2")
script_security:value("3")
script_security.description = translate("Default 3, leave it empty to disable")

duplicate_cn = s:taboption("basic",Flag,"duplicate_cn", translate("duplicate_cn"))
duplicate_cn.description = translate("This option allows multiple clients to connect using the same certificate and key and assign different IP addresses")
client_to_client = s:taboption("basic",Flag,"client_to_client", translate("client-to-client"))
client_to_client.description = translate("Allow clients to see each other, otherwise multiple clients can only access the server and cannot connect to each other")
username_as_common_name = s:taboption("basic",Flag,"username_as_common_name", translate("username_as_common_name"))
username_as_common_name.description = translate("Use the UserName provided by the client as the Common Name")
client_cert_not_required = s:taboption("basic",Flag,"client_cert_not_required", translate("client_cert_not_required"))
client_cert_not_required.description = translate("After this option is enabled, the client does not need cert and key. If this option is not enabled, cert and key and user password double verification are required.")

list = s:taboption("basic", DynamicList, "push")
list.title = translate("Client Settings")
list.datatype = "string"
list.description = translate("Set route 192.168.0.0 255.255.255.0 and dhcp-option DNS 192.168.0.1 base on your router")


local o
o = s:taboption("basic", Button,"certificate",translate("OpenVPN Client config file"))
o.inputtitle = translate("Download .ovpn file")
o.description = translate("If you use user password verification only, remember to delete the key and cert.")
o.inputstyle = "reload"
o.write = function()
  luci.sys.call("sh /etc/genovpn.sh 2>&1 >/dev/null")
	Download()
end

s:tab("code",  translate("Client code"))
local conf = "/etc/ovpnadd.conf"
local NXFS = require "nixio.fs"
o = s:taboption("code", TextValue, "conf")
o.description = translate("Here is the code that you want to add to the .ovpn file. If you use user password verification, you need to add auth-user-pass")
o.rows = 13
o.wrap = "off"
o.cfgvalue = function(self, section)
	return NXFS.readfile(conf) or ""
end
o.write = function(self, section, value)
	NXFS.writefile(conf, value:gsub("\r\n", "\n"))
end

s:tab("passwordfile",  translate("User and password"))
local pass = "/etc/openvpn/server/psw-file"
local NXFS = require "nixio.fs"
o = s:taboption("passwordfile", TextValue, "pass")
o.description = translate("Each line contains a pair of user and password, separated by a space")
o.rows = 13
o.wrap = "off"
o.cfgvalue = function(self, section)
	return NXFS.readfile(pass) or ""
end
o.write = function(self, section, value)
	NXFS.writefile(pass, value:gsub("\r\n", "\n"))
end

s:tab("checkpsw",  translate("Authentication script"))
local checkpswconf = "/etc/openvpn/server/checkpsw.sh"
local NXFS = require "nixio.fs"
o = s:taboption("checkpsw", TextValue, "checkpswconf")
o.description = translate("Authentication script")
o.rows = 13
o.wrap = "off"
o.cfgvalue = function(self, section)
	return NXFS.readfile(checkpswconf) or ""
end
o.write = function(self, section, value)
	NXFS.writefile(checkpswconf, value:gsub("\r\n", "\n"))
end

local pid = luci.util.exec("/usr/bin/pgrep openvpn")

function openvpn_process_status()
  local status = "OpenVPN is not running now "

  if pid ~= "" then
      status = "OpenVPN is running with the PID " .. pid .. ""
  end

  local status = { status=status }
  local table = { pid=status }
  return table
end



function Download()
	local t,e
	t=nixio.open("/tmp/my.ovpn","r")
	luci.http.header('Content-Disposition','attachment; filename="my.ovpn"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end

t = mp:section(Table, openvpn_process_status())
t.anonymous = true

t:option(DummyValue, "status", translate("OpenVPN status"))

if pid == "" then
  start = t:option(Button, "_start", translate("Start"))
  start.inputstyle = "apply"
  function start.write(self, section)
        luci.util.exec("uci set openvpn.myvpn.enabled=='1' &&  uci commit openvpn")
        message = luci.util.exec("/etc/init.d/openvpn start 2>&1")
        luci.util.exec("sleep 2")
        luci.http.redirect(
                luci.dispatcher.build_url("admin", "services", "openvpn-server") .. "?message=" .. message
        )
  end
else
  stop = t:option(Button, "_stop", translate("Stop"))
  stop.inputstyle = "reset"
  function stop.write(self, section)
        luci.util.exec("uci set openvpn.myvpn.enabled=='0' &&  uci commit openvpn")
        luci.util.exec("/etc/init.d/openvpn stop")
        luci.util.exec("sleep 2")
        luci.http.redirect(
                luci.dispatcher.build_url("admin", "services", "openvpn-server")
        )
  end
end

local comp_lzo_val = uci:get("openvpn", "myvpn", "comp_lzo")

function mp.on_after_commit(self)
  os.execute("uci set firewall.openvpn.dest_port=$(uci get openvpn.myvpn.port) && uci commit firewall &&  /etc/init.d/firewall restart")
  os.execute("/etc/init.d/openvpn restart")
  if comp_lzo_val == "no" then
        uci:delete("openvpn", "myvpn", "comp_lzo")
        uci:commit("openvpn")
  end
end

gen = t:option(Button,"cert",translate("OpenVPN Cert"))
gen.inputstyle = "apply"
function gen.write(self, section)
  luci.util.exec("/etc/openvpncert.sh")
end

--local apply = luci.http.formvalue("cbi.apply")
--if apply then
--	os.execute("/etc/init.d/openvpn restart")
--end

return mp
