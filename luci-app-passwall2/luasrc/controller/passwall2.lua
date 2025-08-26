-- Copyright (C) 2022-2025 xiaorouji

module("luci.controller.passwall2", package.seeall)
local api = require "luci.passwall2.api"
local appname = api.appname		-- not available
local uci = api.uci				-- in funtion index()
local http = require "luci.http"
local util = require "luci.util"
local i18n = require "luci.i18n"
local fs = api.fs
local jsonStringify = luci.jsonc.stringify

function index()
	if not nixio.fs.access("/etc/config/passwall2") then
		if nixio.fs.access("/usr/share/passwall2/0_default_config") then
			luci.sys.call('cp -f /usr/share/passwall2/0_default_config /etc/config/passwall2')
		else return end
	end
	local api = require "luci.passwall2.api"
	local appname = api.appname		-- global definitions not available
	local uci = api.uci				-- in function index()
	entry({"admin", "services", appname}).dependent = true
	entry({"admin", "services", appname, "reset_config"}, call("reset_config")).leaf = true
	entry({"admin", "services", appname, "show"}, call("show_menu")).leaf = true
	entry({"admin", "services", appname, "hide"}, call("hide_menu")).leaf = true
	local e
	if uci:get(appname, "@global[0]", "hide_from_luci") ~= "1" then
		e = entry({"admin", "services", appname}, alias("admin", "services", appname, "settings"), _("PassWall 2"), 0)
	else
		e = entry({"admin", "services", appname}, alias("admin", "services", appname, "settings"), nil, 0)
	end
	e.dependent = true
	e.acl_depends = { "luci-app-passwall2" }
	--[[ Client ]]
	entry({"admin", "services", appname, "settings"}, cbi(appname .. "/client/global"), _("Basic Settings"), 1).dependent = true
	entry({"admin", "services", appname, "node_list"}, cbi(appname .. "/client/node_list"), _("Node List"), 2).dependent = true
	entry({"admin", "services", appname, "node_subscribe"}, cbi(appname .. "/client/node_subscribe"), _("Node Subscribe"), 3).dependent = true
	entry({"admin", "services", appname, "other"}, cbi(appname .. "/client/other", {autoapply = true}), _("Other Settings"), 92).leaf = true
	if nixio.fs.access("/usr/sbin/haproxy") then
		entry({"admin", "services", appname, "haproxy"}, cbi(appname .. "/client/haproxy"), _("Load Balancing"), 93).leaf = true
	end
	entry({"admin", "services", appname, "app_update"}, cbi(appname .. "/client/app_update"), _("App Update"), 95).leaf = true
	entry({"admin", "services", appname, "rule"}, cbi(appname .. "/client/rule"), _("Rule Manage"), 96).leaf = true
	entry({"admin", "services", appname, "geoview"}, form(appname .. "/client/geoview"), _("Geo View"), 97).leaf = true
	entry({"admin", "services", appname, "node_subscribe_config"}, cbi(appname .. "/client/node_subscribe_config")).leaf = true
	entry({"admin", "services", appname, "node_config"}, cbi(appname .. "/client/node_config")).leaf = true
	entry({"admin", "services", appname, "shunt_rules"}, cbi(appname .. "/client/shunt_rules")).leaf = true
	entry({"admin", "services", appname, "socks_config"}, cbi(appname .. "/client/socks_config")).leaf = true
	entry({"admin", "services", appname, "acl"}, cbi(appname .. "/client/acl"), _("Access control"), 98).leaf = true
	entry({"admin", "services", appname, "acl_config"}, cbi(appname .. "/client/acl_config")).leaf = true
	entry({"admin", "services", appname, "log"}, form(appname .. "/client/log"), _("Watch Logs"), 999).leaf = true

	--[[ Server ]]
	entry({"admin", "services", appname, "server"}, cbi(appname .. "/server/index"), _("Server-Side"), 99).leaf = true
	entry({"admin", "services", appname, "server_user"}, cbi(appname .. "/server/user")).leaf = true

	--[[ API ]]
	entry({"admin", "services", appname, "server_user_status"}, call("server_user_status")).leaf = true
	entry({"admin", "services", appname, "server_user_log"}, call("server_user_log")).leaf = true
	entry({"admin", "services", appname, "server_get_log"}, call("server_get_log")).leaf = true
	entry({"admin", "services", appname, "server_clear_log"}, call("server_clear_log")).leaf = true
	entry({"admin", "services", appname, "link_add_node"}, call("link_add_node")).leaf = true
	entry({"admin", "services", appname, "socks_autoswitch_add_node"}, call("socks_autoswitch_add_node")).leaf = true
	entry({"admin", "services", appname, "socks_autoswitch_remove_node"}, call("socks_autoswitch_remove_node")).leaf = true
	entry({"admin", "services", appname, "gen_client_config"}, call("gen_client_config")).leaf = true
	entry({"admin", "services", appname, "get_now_use_node"}, call("get_now_use_node")).leaf = true
	entry({"admin", "services", appname, "get_redir_log"}, call("get_redir_log")).leaf = true
	entry({"admin", "services", appname, "get_socks_log"}, call("get_socks_log")).leaf = true
	entry({"admin", "services", appname, "get_log"}, call("get_log")).leaf = true
	entry({"admin", "services", appname, "clear_log"}, call("clear_log")).leaf = true
	entry({"admin", "services", appname, "index_status"}, call("index_status")).leaf = true
	entry({"admin", "services", appname, "haproxy_status"}, call("haproxy_status")).leaf = true
	entry({"admin", "services", appname, "socks_status"}, call("socks_status")).leaf = true
	entry({"admin", "services", appname, "connect_status"}, call("connect_status")).leaf = true
	entry({"admin", "services", appname, "ping_node"}, call("ping_node")).leaf = true
	entry({"admin", "services", appname, "urltest_node"}, call("urltest_node")).leaf = true
	entry({"admin", "services", appname, "set_node"}, call("set_node")).leaf = true
	entry({"admin", "services", appname, "copy_node"}, call("copy_node")).leaf = true
	entry({"admin", "services", appname, "clear_all_nodes"}, call("clear_all_nodes")).leaf = true
	entry({"admin", "services", appname, "delete_select_nodes"}, call("delete_select_nodes")).leaf = true
	entry({"admin", "services", appname, "update_rules"}, call("update_rules")).leaf = true
	entry({"admin", "services", appname, "subscribe_del_node"}, call("subscribe_del_node")).leaf = true
	entry({"admin", "services", appname, "subscribe_del_all"}, call("subscribe_del_all")).leaf = true
	entry({"admin", "services", appname, "subscribe_manual"}, call("subscribe_manual")).leaf = true
	entry({"admin", "services", appname, "subscribe_manual_all"}, call("subscribe_manual_all")).leaf = true

	--[[Components update]]
	entry({"admin", "services", appname, "check_passwall2"}, call("app_check")).leaf = true
	local coms = require "luci.passwall2.com"
	local com
	for com, _ in pairs(coms) do
		entry({"admin", "services", appname, "check_" .. com}, call("com_check", com)).leaf = true
		entry({"admin", "services", appname, "update_" .. com}, call("com_update", com)).leaf = true
	end

	--[[Backup]]
	entry({"admin", "services", appname, "create_backup"}, call("create_backup")).leaf = true
	entry({"admin", "services", appname, "restore_backup"}, call("restore_backup")).leaf = true

	--[[geoview]]
	entry({"admin", "services", appname, "geo_view"}, call("geo_view")).leaf = true
end

local function http_write_json(content)
	http.prepare_content("application/json")
	http.write(jsonStringify(content or {code = 1}))
end

function reset_config()
	luci.sys.call('/etc/init.d/passwall2 stop')
	luci.sys.call('[ -f "/usr/share/passwall2/0_default_config" ] && cp -f /usr/share/passwall2/0_default_config /etc/config/passwall2')
	http.redirect(api.url())
end

function show_menu()
	api.sh_uci_del(appname, "@global[0]", "hide_from_luci", true)
	luci.sys.call("rm -rf /tmp/luci-*")
	luci.sys.call("/etc/init.d/rpcd restart >/dev/null")
	http.redirect(api.url())
end

function hide_menu()
	api.sh_uci_set(appname, "@global[0]", "hide_from_luci", "1", true)
	luci.sys.call("rm -rf /tmp/luci-*")
	luci.sys.call("/etc/init.d/rpcd restart >/dev/null")
	http.redirect(luci.dispatcher.build_url("admin", "status", "overview"))
end

function link_add_node()
	-- 分片接收以突破uhttpd的限制
	local tmp_file = "/tmp/links.conf"
	local chunk = http.formvalue("chunk")
	local chunk_index = tonumber(http.formvalue("chunk_index"))
	local total_chunks = tonumber(http.formvalue("total_chunks"))

	if chunk and chunk_index ~= nil and total_chunks ~= nil then
		-- 按顺序拼接到文件
		local mode = "a"
		if chunk_index == 0 then
			mode = "w"
		end
		local f = io.open(tmp_file, mode)
		if f then
			f:write(chunk)
			f:close()
		end
		-- 如果是最后一片，才执行
		if chunk_index + 1 == total_chunks then
			luci.sys.call("lua /usr/share/passwall2/subscribe.lua add log")
		end
	end
end

function socks_autoswitch_add_node()
	local id = http.formvalue("id")
	local key = http.formvalue("key")
	if id and id ~= "" and key and key ~= "" then
		uci:set(appname, id, "enable_autoswitch", "1")
		local new_list = uci:get(appname, id, "autoswitch_backup_node") or {}
		for i = #new_list, 1, -1 do
			if (uci:get(appname, new_list[i], "remarks") or ""):find(key) then
				table.remove(new_list, i)
			end
		end
		for k, e in ipairs(api.get_valid_nodes()) do
			if e.node_type == "normal" and e["remark"]:find(key) then
				table.insert(new_list, e.id)
			end
		end
		uci:set_list(appname, id, "autoswitch_backup_node", new_list)
		api.uci_save(uci, appname)
	end
	http.redirect(api.url("socks_config", id))
end

function socks_autoswitch_remove_node()
	local id = http.formvalue("id")
	local key = http.formvalue("key")
	if id and id ~= "" and key and key ~= "" then
		uci:set(appname, id, "enable_autoswitch", "1")
		local new_list = uci:get(appname, id, "autoswitch_backup_node") or {}
		for i = #new_list, 1, -1 do
			if (uci:get(appname, new_list[i], "remarks") or ""):find(key) then
				table.remove(new_list, i)
			end
		end
		uci:set_list(appname, id, "autoswitch_backup_node", new_list)
		api.uci_save(uci, appname)
	end
	http.redirect(api.url("socks_config", id))
end

function gen_client_config()
	local id = http.formvalue("id")
	local config_file = api.TMP_PATH .. "/config_" .. id
	luci.sys.call(string.format("/usr/share/passwall2/app.sh run_socks flag=config_%s node=%s bind=127.0.0.1 socks_port=1080 config_file=%s no_run=1", id, id, config_file))
	if nixio.fs.access(config_file) then
		http.prepare_content("application/json")
		http.write(luci.sys.exec("cat " .. config_file))
		luci.sys.call("rm -f " .. config_file)
	else
		http.redirect(api.url("node_list"))
	end
end

function get_now_use_node()
	local e = {}
	local node = api.get_cache_var("ACL_GLOBAL_node")
	if node then
		e["global"] = node
	end
	http_write_json(e)
end

function get_redir_log()
	local id = http.formvalue("id")
	local name = http.formvalue("name")
	local file_path = "/tmp/etc/passwall2/acl/" .. id .. "/" .. name .. ".log"
	if nixio.fs.access(file_path) then
		local content = luci.sys.exec("tail -n 19999 '" .. file_path .. "'")
		content = content:gsub("\n", "<br />")
		http.write(content)
	else
		http.write(string.format("<script>alert('%s');window.close();</script>", i18n.translate("Not enabled log")))
	end
end

function get_socks_log()
	local name = http.formvalue("name")
	local path = "/tmp/etc/passwall2/SOCKS_" .. name .. ".log"
	if nixio.fs.access(path) then
		local content = luci.sys.exec("tail -n 5000 ".. path)
		content = content:gsub("\n", "<br />")
		http.write(content)
	else
		http.write(string.format("<script>alert('%s');window.close();</script>", i18n.translate("Not enabled log")))
	end
end

function get_log()
	-- luci.sys.exec("[ -f /tmp/log/passwall2.log ] && sed '1!G;h;$!d' /tmp/log/passwall2.log > /tmp/log/passwall2_show.log")
	http.write(luci.sys.exec("[ -f '/tmp/log/passwall2.log' ] && cat /tmp/log/passwall2.log"))
end

function clear_log()
	luci.sys.call("echo '' > /tmp/log/passwall2.log")
end

function index_status()
	local e = {}
	e["global_status"] = luci.sys.call("/bin/busybox top -bn1 | grep -v 'grep' | grep '/tmp/etc/passwall2/bin/' | grep 'default' | grep 'global' >/dev/null") == 0
	http_write_json(e)
end

function haproxy_status()
	local e = luci.sys.call(string.format("/bin/busybox top -bn1 | grep -v grep | grep '%s/bin/' | grep haproxy >/dev/null", appname)) == 0
	http_write_json(e)
end

function socks_status()
	local e = {}
	local index = http.formvalue("index")
	local id = http.formvalue("id")
	e.index = index
	e.socks_status = luci.sys.call(string.format("/bin/busybox top -bn1 | grep -v -E 'grep|acl/|acl_' | grep '%s/bin/' | grep '%s' | grep 'SOCKS_' > /dev/null", appname, id)) == 0
	local use_http = uci:get(appname, id, "http_port") or 0
	e.use_http = 0
	if tonumber(use_http) > 0 then
		e.use_http = 1
		e.http_status = luci.sys.call(string.format("/bin/busybox top -bn1 | grep -v -E 'grep|acl/|acl_' | grep '%s/bin/' | grep '%s' | grep -E 'HTTP_|HTTP2SOCKS' > /dev/null", appname, id)) == 0
	end
	http_write_json(e)
end

function connect_status()
	local e = {}
	e.use_time = ""
	local url = http.formvalue("url")
	local result = luci.sys.exec('curl --connect-timeout 3 -o /dev/null -I -sk -w "%{http_code}:%{time_appconnect}" ' .. url)
	local code = tonumber(luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $1}'") or "0")
	if code ~= 0 then
		local use_time = luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $2}'")
		if use_time:find("%.") then
			e.use_time = string.format("%.2f", use_time * 1000)
		else
			e.use_time = string.format("%.2f", use_time / 1000)
		end
		e.ping_type = "curl"
	end
	http_write_json(e)
end

function ping_node()
	local index = http.formvalue("index")
	local address = http.formvalue("address")
	local port = http.formvalue("port")
	local type = http.formvalue("type") or "icmp"
	local e = {}
	e.index = index
	if type == "tcping" and luci.sys.exec("echo -n $(command -v tcping)") ~= "" then
		if api.is_ipv6(address) then
			address = api.get_ipv6_only(address)
		end
		e.ping = luci.sys.exec(string.format("echo -n $(tcping -q -c 1 -i 1 -t 2 -p %s %s 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null", port, address))
	else
		e.ping = luci.sys.exec("echo -n $(ping -c 1 -W 1 %q 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null" % address)
	end
	http_write_json(e)
end

function urltest_node()
	local index = http.formvalue("index")
	local id = http.formvalue("id")
	local e = {}
	e.index = index
	local result = luci.sys.exec(string.format("/usr/share/passwall2/test.sh url_test_node %s %s", id, "urltest_node"))
	local code = tonumber(luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $1}'") or "0")
	if code ~= 0 then
		local use_time = luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $2}'")
		if use_time:find("%.") then
			e.use_time = string.format("%.2f", use_time * 1000)
		else
			e.use_time = string.format("%.2f", use_time / 1000)
		end
	end
	http_write_json(e)
end

function set_node()
	local type = http.formvalue("type")
	local config = http.formvalue("config")
	local section = http.formvalue("section")
	uci:set(appname, type, config, section)
	api.uci_save(uci, appname, true, true)
	http.redirect(api.url("log"))
end

function copy_node()
	local section = http.formvalue("section")
	local uuid = api.gen_short_uuid()
	uci:section(appname, "nodes", uuid)
	for k, v in pairs(uci:get_all(appname, section)) do
		local filter = k:find("%.")
		if filter and filter == 1 then
		else
			xpcall(function()
				uci:set(appname, uuid, k, v)
			end,
			function(e)
			end)
		end
	end
	uci:delete(appname, uuid, "add_from")
	uci:set(appname, uuid, "add_mode", 1)
	api.uci_save(uci, appname)
	http.redirect(api.url("node_config", uuid))
end

function clear_all_nodes()
	uci:set(appname, '@global[0]', "enabled", "0")
	uci:set(appname, '@global[0]', "socks_enabled", "0")
	uci:set(appname, '@haproxy_config[0]', "balancing_enable", "0")
	uci:delete(appname, '@global[0]', "node")
	uci:foreach(appname, "socks", function(t)
		uci:delete(appname, t[".name"])
		uci:set_list(appname, t[".name"], "autoswitch_backup_node", {})
	end)
	uci:foreach(appname, "haproxy_config", function(t)
		uci:delete(appname, t[".name"])
	end)
	uci:foreach(appname, "acl_rule", function(t)
		uci:delete(appname, t[".name"], "node")
	end)
	uci:foreach(appname, "nodes", function(node)
		uci:delete(appname, node['.name'])
	end)
	uci:foreach(appname, "subscribe_list", function(t)
		uci:delete(appname, t[".name"], "md5")
		uci:delete(appname, t[".name"], "chain_proxy")
		uci:delete(appname, t[".name"], "preproxy_node")
		uci:delete(appname, t[".name"], "to_node")
	end)

	api.uci_save(uci, appname, true, true)
end

function delete_select_nodes()
	local ids = http.formvalue("ids")
	string.gsub(ids, '[^' .. "," .. ']+', function(w)
		if (uci:get(appname, "@global[0]", "node") or "") == w then
			uci:delete(appname, '@global[0]', "node")
		end
		uci:foreach(appname, "socks", function(t)
			if t["node"] == w then
				uci:delete(appname, t[".name"])
			end
			local auto_switch_node_list = uci:get(appname, t[".name"], "autoswitch_backup_node") or {}
			for i = #auto_switch_node_list, 1, -1 do
				if w == auto_switch_node_list[i] then
					table.remove(auto_switch_node_list, i)
				end
			end
			uci:set_list(appname, t[".name"], "autoswitch_backup_node", auto_switch_node_list)
		end)
		uci:foreach(appname, "haproxy_config", function(t)
			if t["lbss"] == w then
				uci:delete(appname, t[".name"])
			end
		end)
		uci:foreach(appname, "acl_rule", function(t)
			if t["node"] == w then
				uci:delete(appname, t[".name"], "node")
			end
		end)
		uci:foreach(appname, "nodes", function(t)
			if t["preproxy_node"] == w then
				uci:delete(appname, t[".name"], "preproxy_node")
				uci:delete(appname, t[".name"], "chain_proxy")
			end
			if t["to_node"] == w then
				uci:delete(appname, t[".name"], "to_node")
				uci:delete(appname, t[".name"], "chain_proxy")
			end
			local list_name = t["urltest_node"] and "urltest_node" or (t["balancing_node"] and "balancing_node")
			if list_name then
				local nodes = uci:get_list(appname, t[".name"], list_name)
				if nodes then
					local changed = false
					local new_nodes = {}
					for _, node in ipairs(nodes) do
						if node ~= w then
							table.insert(new_nodes, node)
						else
							changed = true
						end
					end
					if changed then
						uci:set_list(appname, t[".name"], list_name, new_nodes)
					end
				end
			end
			if t["fallback_node"] == w then
				uci:delete(appname, t[".name"], "fallback_node")
			end
		end)
		uci:foreach(appname, "subscribe_list", function(t)
			if t["preproxy_node"] == w then
				uci:delete(appname, t[".name"], "preproxy_node")
				uci:delete(appname, t[".name"], "chain_proxy")
			end
			if t["to_node"] == w then
				uci:delete(appname, t[".name"], "to_node")
				uci:delete(appname, t[".name"], "chain_proxy")
			end
		end)
		if (uci:get(appname, w, "add_mode") or "0") == "2" then
			local add_from = uci:get(appname, w, "add_from") or ""
			if add_from ~= "" then
				uci:foreach(appname, "subscribe_list", function(t)
					if t["remark"] == add_from then
						uci:delete(appname, t[".name"], "md5")
					end
				end)
			end
		end
		uci:delete(appname, w)
	end)
	api.uci_save(uci, appname, true, true)
end

function update_rules()
	local update = http.formvalue("update")
	luci.sys.call("lua /usr/share/passwall2/rule_update.lua log '" .. update .. "' > /dev/null 2>&1 &")
	http_write_json()
end

function server_user_status()
	local e = {}
	e.index = http.formvalue("index")
	e.status = luci.sys.call(string.format("/bin/busybox top -bn1 | grep -v 'grep' | grep '%s/bin/' | grep -i '%s' >/dev/null", appname .. "_server", http.formvalue("id"))) == 0
	http_write_json(e)
end

function server_user_log()
	local id = http.formvalue("id")
	if nixio.fs.access("/tmp/etc/passwall2_server/" .. id .. ".log") then
		local content = luci.sys.exec("cat /tmp/etc/passwall2_server/" .. id .. ".log")
		content = content:gsub("\n", "<br />")
		http.write(content)
	else
		http.write(string.format("<script>alert('%s');window.close();</script>", i18n.translate("Not enabled log")))
	end
end

function server_get_log()
	http.write(luci.sys.exec("[ -f '/tmp/log/passwall2_server.log' ] && cat /tmp/log/passwall2_server.log"))
end

function server_clear_log()
	luci.sys.call("echo '' > /tmp/log/passwall2_server.log")
end

function app_check()
	local json = api.to_check_self()
	http_write_json(json)
end

function com_check(comname)
	local json = api.to_check("", comname)
	http_write_json(json)
end

function com_update(comname)
	local json = nil
	local task = http.formvalue("task")
	if task == "extract" then
		json = api.to_extract(comname, http.formvalue("file"), http.formvalue("subfix"))
	elseif task == "move" then
		json = api.to_move(comname, http.formvalue("file"))
	else
		json = api.to_download(comname, http.formvalue("url"), http.formvalue("size"))
	end

	http_write_json(json)
end

local backup_files = {
	"/etc/config/passwall2",
	"/etc/config/passwall2_server",
	"/usr/share/passwall2/domains_excluded"
}

function create_backup()
	local date = os.date("%y%m%d%H%M")
	local tar_file = "/tmp/passwall2-" .. date .. "-backup.tar.gz"
	fs.remove(tar_file)
	local cmd = "tar -czf " .. tar_file .. " " .. table.concat(backup_files, " ")
	api.sys.call(cmd)
	http.header("Content-Disposition", "attachment; filename=passwall2-" .. date .. "-backup.tar.gz")
	http.header("X-Backup-Filename", "passwall2-" .. date .. "-backup.tar.gz")
	http.prepare_content("application/octet-stream")
	http.write(fs.readfile(tar_file))
	fs.remove(tar_file)
end

function restore_backup()
	local result = { status = "error", message = "unknown error" }
	local ok, err = pcall(function()
		local filename = http.formvalue("filename")
		local chunk = http.formvalue("chunk")
		local chunk_index = tonumber(http.formvalue("chunk_index") or "-1")
		local total_chunks = tonumber(http.formvalue("total_chunks") or "-1")
		if not filename then
			result = { status = "error", message = "Missing filename" }
			return
		end
		if not chunk then
			result = { status = "error", message = "Missing chunk data" }
			return
		end
		local file_path = "/tmp/" .. filename
		local decoded = nixio.bin.b64decode(chunk)
		if not decoded then
			result = { status = "error", message = "Base64 decode failed" }
			return
		end
		local fp = io.open(file_path, "a+")
		if not fp then
			result = { status = "error", message = "Failed to open file: " .. file_path }
			return
		end
		fp:write(decoded)
		fp:close()
		if chunk_index + 1 == total_chunks then
			api.sys.call("echo '' > /tmp/log/passwall2.log")
			api.log(" * PassWall2 配置文件上传成功…")
			local temp_dir = '/tmp/passwall2_bak'
			api.sys.call("mkdir -p " .. temp_dir)
			if api.sys.call("tar -xzf " .. file_path .. " -C " .. temp_dir) == 0 then
				for _, backup_file in ipairs(backup_files) do
					local temp_file = temp_dir .. backup_file
					if fs.access(temp_file) then
						api.sys.call("cp -f " .. temp_file .. " " .. backup_file)
					end
				end
				api.log(" * PassWall2 配置还原成功…")
				api.log(" * 重启 PassWall2 服务中…\n")
				luci.sys.call('/etc/init.d/passwall2 restart > /dev/null 2>&1 &')
				luci.sys.call('/etc/init.d/passwall2_server restart > /dev/null 2>&1 &')
				result = { status = "success", message = "Upload completed", path = file_path }
			else
				api.log(" * PassWall2 配置文件解压失败，请重试！")
				result = { status = "error", message = "Decompression failed" }
			end
			api.sys.call("rm -rf " .. temp_dir)
			fs.remove(file_path)
		else
			result = { status = "success", message = "Chunk received" }
		end
	end)
	if not ok then
		result = { status = "error", message = tostring(err) }
	end
	http_write_json(result)
end

function geo_view()
	local action = luci.http.formvalue("action")
	local value = luci.http.formvalue("value")
	if not value or value == "" then
		http.prepare_content("text/plain")
		http.write(i18n.translate("Please enter query content!"))
		return
	end
	local geo_dir = (uci:get(appname, "@global_rules[0]", "v2ray_location_asset") or "/usr/share/v2ray/"):match("^(.*)/")
	local geosite_path = geo_dir .. "/geosite.dat"
	local geoip_path = geo_dir .. "/geoip.dat"
	local geo_type, file_path, cmd
	local geo_string = ""
	if action == "lookup" then
		if api.datatypes.ipaddr(value) or api.datatypes.ip6addr(value) then
			geo_type, file_path = "geoip", geoip_path
		else
			geo_type, file_path = "geosite", geosite_path
		end
		cmd = string.format("geoview -type %s -action lookup -input '%s' -value '%s' -lowmem=true", geo_type, file_path, value)
		geo_string = luci.sys.exec(cmd):lower()
		if geo_string ~= "" then
			local lines = {}
			for line in geo_string:gmatch("([^\n]*)\n?") do
				if line ~= "" then
					table.insert(lines, geo_type .. ":" .. line)
				end
			end
			geo_string = table.concat(lines, "\n")
		end
	elseif action == "extract" then
		local prefix, list = value:match("^(geoip:)(.*)$")
		if not prefix then
			prefix, list = value:match("^(geosite:)(.*)$")
		end
		if prefix and list and list ~= "" then
			geo_type = prefix:sub(1, -2)
			file_path = (geo_type == "geoip") and geoip_path or geosite_path
			cmd = string.format("geoview -type %s -action extract -input '%s' -list '%s' -lowmem=true", geo_type, file_path, list)
			geo_string = luci.sys.exec(cmd)
		end
	end
	http.prepare_content("text/plain")
	if geo_string and geo_string ~="" then
		http.write(geo_string)
	else
		http.write(i18n.translate("No results were found!"))
	end
end

function subscribe_del_node()
	local remark = http.formvalue("remark")
	if remark and remark ~= "" then
		luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua truncate " .. luci.util.shellquote(remark) .. " > /dev/null 2>&1")
	end
	http.status(200, "OK")
end

function subscribe_del_all()
	luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua truncate > /dev/null 2>&1")
	http.status(200, "OK")
end

function subscribe_manual()
	local section = http.formvalue("section") or ""
	local current_url = http.formvalue("url") or ""
	if section == "" or current_url == "" then
		http_write_json({ success = false, msg = "Missing section or URL, skip." })
		return
	end
	local uci_url = api.sh_uci_get(appname, section, "url")
	if not uci_url or uci_url == "" then
		http_write_json({ success = false, msg = i18n.translate("Please save and apply before manually subscribing.") })
		return
	end
	if uci_url ~= current_url then
		api.sh_uci_set(appname, section, "url", current_url, true)
	end
	luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua start " .. section .. " manual >/dev/null 2>&1 &")
	http_write_json({ success = true, msg = "Subscribe triggered." })
end

function subscribe_manual_all()
	local sections = http.formvalue("sections") or ""
	local urls = http.formvalue("urls") or ""
	if sections == "" or urls == "" then
		http_write_json({ success = false, msg = "Missing section or URL, skip." })
		return
	end
	local section_list = util.split(sections, ",")
	local url_list = util.split(urls, ",")
	-- 检查是否存在未保存配置
	for i, section in ipairs(section_list) do
		local uci_url = api.sh_uci_get(appname, section, "url")
		if not uci_url or uci_url == "" then
			http_write_json({ success = false, msg = i18n.translate("Please save and apply before manually subscribing.") })
			return
		end
	end
	-- 保存有变动的url
	for i, section in ipairs(section_list) do
		local current_url = url_list[i] or ""
		local uci_url = api.sh_uci_get(appname, section, "url")
		if current_url ~= "" and uci_url ~= current_url then
			api.sh_uci_set(appname, section, "url", current_url, true)
		end
	end
	luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua start all manual >/dev/null 2>&1 &")
	http_write_json({ success = true, msg = "Subscribe triggered." })
end
