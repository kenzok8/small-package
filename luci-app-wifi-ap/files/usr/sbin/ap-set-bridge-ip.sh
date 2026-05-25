#!/bin/sh
# 桥接网口为 eth0-eth2，eth3为固定IP管理口，仅首次开机或固件重置后自动运行

FLAG_FILE="/etc/wifi-ap/.bridge_mode_applied"
MGMT_IF="eth3"
MGMT_IP="192.168.10.254"
MGMT_NETMASK="255.255.255.0"
BR_IFNAME="eth0 eth1 eth2"
LAN_IF="br-lan"

# 仅首次开机或固件重置后执行
FIRSTBOOT_FLAG="/etc/rc.firstboot_done"
[ ! -f "$FIRSTBOOT_FLAG" ] && [ ! -f "$FLAG_FILE" ] || exit 0

# 检查是否已设置过，防止重复执行
if [ -f "$FLAG_FILE" ]; then
    echo "AP桥接模式已应用，无需重复设置"
    exit 0
fi

# 1. 设置LAN为桥接，包含eth0/eth1/eth2，协议为DHCP
uci set network.lan.type='bridge'
uci set network.lan.ifname="$BR_IFNAME"
uci set network.lan.proto='dhcp'
uci delete network.lan.ipaddr 2>/dev/null
uci delete network.lan.netmask 2>/dev/null
uci delete network.lan.gateway 2>/dev/null
uci delete network.lan.dns 2>/dev/null

# 2. 配置eth3为管理口，static固定IP
uci delete network.mgmt 2>/dev/null
uci set network.mgmt="interface"
uci set network.mgmt.ifname="$MGMT_IF"
uci set network.mgmt.proto="static"
uci set network.mgmt.ipaddr="$MGMT_IP"
uci set network.mgmt.netmask="$MGMT_NETMASK"
uci delete network.mgmt.gateway 2>/dev/null
uci delete network.mgmt.dns 2>/dev/null

# 3. 禁用LAN口DHCP服务
uci set dhcp.lan.ignore='1'
# 4. 禁用管理口DHCP服务（如有）
uci delete dhcp.mgmt 2>/dev/null

# 5. 应用配置
uci commit network
uci commit dhcp

# 6. 重启网络服务
/etc/init.d/network restart
/etc/init.d/dnsmasq restart
sleep 5

# 7. 检查桥接和管理IP是否生效
CUR_BR_TYPE=$(uci get network.lan.type 2>/dev/null)
CUR_BR_PROTO=$(uci get network.lan.proto 2>/dev/null)
CUR_BR_IF=$(uci get network.lan.ifname 2>/dev/null)
CUR_MGMT_IP=$(ifstatus mgmt 2>/dev/null | grep -o '"address": *"[^"]*' | grep -o '[0-9.]\{7,15\}' | head -n1)

if [ "$CUR_BR_TYPE" = "bridge" ] && [ "$CUR_BR_PROTO" = "dhcp" ] && [ "$CUR_BR_IF" = "$BR_IFNAME" ] && [ "$CUR_MGMT_IP" = "$MGMT_IP" ]; then
    echo "桥接LAN口($BR_IFNAME)为DHCP，管理口$MGMT_IF固定IP设置成功: $CUR_MGMT_IP"
    touch "$FLAG_FILE"
    exit 0
else
    echo "桥接或管理口设置失败，当前: br_type=$CUR_BR_TYPE br_proto=$CUR_BR_PROTO br_if=$CUR_BR_IF mgmt_ip=$CUR_MGMT_IP"
    exit 1
fi
