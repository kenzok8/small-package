-- Copyright (C) 2023  sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/chatgpt-web.git
-- Licensed to the public under the Apache License 2.0.

local fs = require "nixio.fs"
local uci = require 'luci.model.uci'.cursor()

module("luci.controller.chatgpt-web", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/chatgpt-web") then
		return
	end

	entry({"admin",  "services", "chatgpt-web"}, alias("admin", "services", "chatgpt-web", "setting"),_("Chatgpt Web"), 20).dependent = true
	entry({"admin", "services", "chatgpt-web", "setting"}, cbi("chatgpt-web"), _("Base Setting"), 10).leaf=true
	entry({"admin",  "services", "chatgpt-web", "chatgpt-web"}, template("chatgpt-web"), _("Chatgpt Web"), 30).leaf = true
	-- entry({"admin",  "services", "chatgpt-web", "chatgpt-api"}, call("act_chatgpt_api"))
end

function act_chatgpt_api()
	local e = {}
	if fs.access('/etc/config/chatgpt-web') then
	        e.apihosts = uci:get_first('chatgpt-web', 'basic', 'apiHost')
	        e.apikeys = uci:get_first('chatgpt-web', 'basic', 'apikey')
		e.stat = true
	else
		e.stat = false
	end
	
	luci.http.prepare_content('application/json')
	luci.http.write_json(e)
end