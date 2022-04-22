#!/usr/bin/lua

local io = require("io")
local ucursor = require "luci.model.uci"
local proxy_section = ucursor:get_first("xray", "general")
local proxy = ucursor:get_all("xray", proxy_section)
local gen_ipset_rules_extra = dofile("/usr/share/xray/gen_ipset_rules_extra.lua")

local create_ipset_rules = [[create tp_spec_src_ac hash:mac hashsize 64
create tp_spec_src_bp hash:mac hashsize 64
create tp_spec_src_fw hash:mac hashsize 64
create tp_spec_dst_sp hash:net hashsize 64
create tp_spec_dst_bp hash:net hashsize 64
create tp_spec_dst_fw hash:net hashsize 64
create tp_spec_def_gw hash:net hashsize 64]]

local function create_ipset()
    print(create_ipset_rules)
end

local function split_ipv4_host_port(val, port_default)
    local found, _, ip, port = val:find("([%d.]+):(%d+)")
    if found == nil then
        return val, tonumber(port_default)
    else
        return ip, tonumber(port)
    end
end

local function lan_access_control()
    ucursor:foreach("xray", "lan_hosts", function(v)
        if v.bypassed == '0' then
            print(string.format("add tp_spec_src_fw %s", v.macaddr))
        else
            print(string.format("add tp_spec_src_bp %s", v.macaddr))
        end
    end)
end

local function iterate_list(ln, set_name)
    local ip_list = proxy[ln]
    if ip_list == nil then
        return
    end
    for _, line in ipairs(ip_list) do
        print(string.format("add %s %s", set_name, line))
    end
end

local function iterate_file(fn, set_name)
    if fn == nil then
        return
    end
    local f = io.open(fn)
    if f == nil then
        return
    end
    for line in io.lines(fn) do
        if line ~= "" then
            print(string.format("add %s %s", set_name, line))
        end
    end
    f:close()
end

local function dns_ips()
    local fast_dns_ip, fast_dns_port = split_ipv4_host_port(proxy.fast_dns, 53)
    local secure_dns_ip, secure_dns_port = split_ipv4_host_port(proxy.secure_dns, 53)
    print(string.format("add tp_spec_dst_bp %s", fast_dns_ip))
    print(string.format("add tp_spec_dst_fw %s", secure_dns_ip))
end

create_ipset()
dns_ips()
lan_access_control()
iterate_list("wan_bp_ips", "tp_spec_dst_bp")
iterate_file(proxy.wan_bp_list or "/dev/null", "tp_spec_dst_bp")
iterate_list("wan_fw_ips", "tp_spec_dst_fw")
iterate_file(proxy.wan_fw_list or "/dev/null", "tp_spec_dst_fw")
gen_ipset_rules_extra(proxy)
