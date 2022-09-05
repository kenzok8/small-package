module("luci.controller.xunyou", package.seeall)

function index()
	
	entry({'admin', 'services', 'xunyou'}, alias('admin', 'services', 'xunyou', 'client'), _('xunyou'), 10).dependent = true -- 首页
	entry({"admin", "services", "xunyou",'client'}, cbi("xunyou/status", {hideresetbtn=true, hidesavebtn=true}), _("xunyou"), 20).leaf = true

	entry({"admin", "services", "xunyou","status"}, call("container_status"))
	entry({"admin", "services", "xunyou","stop"}, call("stop_container"))
	entry({"admin", "services", "xunyou","start"}, call("start_container"))
	entry({"admin", "services", "xunyou","install"}, call("install_container"))
	entry({"admin", "services", "xunyou","uninstall"}, call("uninstall_container"))
end

local sys  = require "luci.sys"
local uci  = require "luci.model.uci".cursor()
local keyword  = "xunyou"
local util  = require("luci.util")

function container_status()
	local xunyou_running = tonumber(util.exec("ps | grep -v grep | grep -c -w 'xunyou_config'")) == 1

	local status = {
		xunyou_running = xunyou_running,
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
	return status
end

function stop_container()
	util.exec("sh /xunyou/scripts/xunyou_config.sh stop")
end

function start_container()
	luci.sys.call('sh /xunyou/scripts/xunyou_config.sh start')

	-- util.exec("./xunyou/scripts/xunyou_config.sh start")
end


-- 总结：
-- docker是否安装
-- 容器是否安装
-- 缺少在lua和htm中运行命令的方法
-- 获取容器id docker ps -aqf'name=xunyou'
-- 启动容器 docker start 78a8455e6d38
-- 停止容器 docker stop 78a8455e6d38


--[[
todo
网络请求提示框
 --]]