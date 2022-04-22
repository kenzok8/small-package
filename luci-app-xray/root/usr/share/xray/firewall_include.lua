#!/usr/bin/lua
local ucursor = require "luci.model.uci"

local flush = [[# firewall include file to stop transparent proxy
ip rule del fwmark 251 lookup 251
ip rule del fwmark 252 lookup 252
ip route del local default dev lo table 251
ip route del local default dev lo table 252
iptables-save -c | grep -v "TP_SPEC" | iptables-restore -c]]
local header = [[# firewall include file to start transparent proxy
ip rule add fwmark 251 lookup 251
ip rule add fwmark 252 lookup 252
ip route add local default dev lo table 251
ip route add local default dev lo table 252
iptables-restore -n <<-EOF
*nat
COMMIT
*mangle
:TP_SPEC_LAN_AC - [0:0]
:TP_SPEC_LAN_DG - [0:0]
:TP_SPEC_WAN_AC - [0:0]
:TP_SPEC_WAN_DG - [0:0]
:TP_SPEC_WAN_FW - [0:0]
-I PREROUTING 1 -m mark --mark 0xfc -j TP_SPEC_WAN_AC]]
local lan = "-I PREROUTING 1 -i %s -j TP_SPEC_LAN_DG"
local rules = [[-A OUTPUT -j TP_SPEC_WAN_DG
-A TP_SPEC_LAN_AC -m set --match-set tp_spec_src_bp src -j RETURN
-A TP_SPEC_LAN_AC -m set --match-set tp_spec_src_fw src -j TP_SPEC_WAN_FW
-A TP_SPEC_LAN_AC -m set --match-set tp_spec_src_ac src -j TP_SPEC_WAN_AC
-A TP_SPEC_LAN_AC -j TP_SPEC_WAN_AC
-A TP_SPEC_LAN_DG -m set --match-set tp_spec_dst_sp dst -j RETURN
-A TP_SPEC_LAN_DG -p tcp -j TP_SPEC_LAN_AC
-A TP_SPEC_LAN_DG -p udp -j TP_SPEC_LAN_AC
-A TP_SPEC_WAN_AC -m set --match-set tp_spec_dst_fw dst -j TP_SPEC_WAN_FW
-A TP_SPEC_WAN_AC -m set --match-set tp_spec_dst_bp dst -j RETURN
-A TP_SPEC_WAN_AC -j TP_SPEC_WAN_FW
-A TP_SPEC_WAN_DG -m set --match-set tp_spec_dst_sp dst -j RETURN
-A TP_SPEC_WAN_DG -m set --match-set tp_spec_dst_bp dst -j RETURN
-A TP_SPEC_WAN_DG -m set --match-set tp_spec_def_gw dst -j RETURN
-A TP_SPEC_WAN_DG -m mark --mark 0x%x -j RETURN
-A TP_SPEC_WAN_DG -p tcp -j MARK --set-xmark 0xfc/0xffffffff
-A TP_SPEC_WAN_DG -p udp -j MARK --set-xmark 0xfc/0xffffffff
-A TP_SPEC_WAN_FW -p tcp -j TPROXY --on-port %d --on-ip 0.0.0.0 --tproxy-mark 0xfb/0xffffffff
-A TP_SPEC_WAN_FW -p udp -j TPROXY --on-port %d --on-ip 0.0.0.0 --tproxy-mark 0xfb/0xffffffff
COMMIT
*filter
COMMIT
EOF]]

local proxy_section = ucursor:get_first("xray", "general")
local proxy = ucursor:get_all("xray", proxy_section)

print(flush)
if proxy.transparent_proxy_enable ~= "1" then
    do
        return
    end
end
if arg[1] == "enable" then
    print(header)
    print(string.format(lan, proxy.lan_ifaces))
    print(string.format(rules, tonumber(proxy.mark), proxy.tproxy_port_tcp, proxy.tproxy_port_udp))
else
    print("# arg[1] == " .. arg[1] .. ", not enable")
end
