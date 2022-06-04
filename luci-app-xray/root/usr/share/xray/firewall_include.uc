#!/usr/bin/utpl
{%
    const uci = require("uci");
    const cursor = uci.cursor();
    cursor.load("xray");
    const config = cursor.get_all("xray");
    const general = config[filter(keys(config), k => config[k][".type"] == "general")[0]];
    const tp_spec_src_fw = map(filter(keys(config), k => config[k][".type"] == "lan_hosts" && config[k].bypassed == "0"), k => config[k].macaddr) || [];
    const tp_spec_src_bp = map(filter(keys(config), k => config[k][".type"] == "lan_hosts" && config[k].bypassed == "1"), k => config[k].macaddr) || [];
    let wan_bp_ips = general.wan_bp_ips || [];
    let wan_fw_ips = general.wan_fw_ips || [];
    push(wan_bp_ips, split(general.fast_dns, ":")[0]);
    push(wan_fw_ips, split(general.secure_dns, ":")[0]);
%}
    set tp_spec_src_ac {
        type ether_addr
        size 65536
    }

    set tp_spec_src_bp {
        type ether_addr
        size 65536
{% if (length(tp_spec_src_bp) > 0): %}
        elements = { {{ join(", ", tp_spec_src_bp) }} }
{% endif %}
    }

    set tp_spec_src_fw {
        type ether_addr
        size 65536
{% if (length(tp_spec_src_fw) > 0): %}
        elements = { {{ join(", ", tp_spec_src_fw) }} }
{% endif %}
    }

    set tp_spec_dst_sp {
        type ipv4_addr
        size 65536
        flags interval
        elements = { 0.0.0.0/8, 10.0.0.0/8,
                 100.64.0.0/10, 127.0.0.0/8,
                 169.254.0.0/16, 172.16.0.0/12,
                 192.0.0.0/24, 192.31.196.0/24,
                 192.52.193.0/24, 192.88.99.0/24,
                 192.168.0.0/16, 192.175.48.0/24,
                 224.0.0.0-255.255.255.255 }
    }

    set tp_spec_dst_bp {
        type ipv4_addr
        size 65536
        flags interval
        elements = { {{ join(", ", wan_bp_ips)}} }
    }

    set tp_spec_dst_fw {
        type ipv4_addr
        size 65536
        flags interval
        elements = { {{ join(", ", wan_fw_ips)}} }
    }

    set tp_spec_def_gw {
        type ipv4_addr
        size 65536
        flags interval
    }

    chain xray_prerouting {
        type filter hook prerouting priority filter; policy accept;
        meta mark 0x000000fc jump tp_spec_wan_ac
        iifname "{{ general.lan_ifaces }}" jump tp_spec_lan_dg
    }

    chain xray_output {
        type route hook output priority filter; policy accept;
        jump tp_spec_wan_dg
    }

    chain tp_spec_lan_ac {
        ether saddr @tp_spec_src_bp return
        ether saddr @tp_spec_src_fw jump tp_spec_wan_fw
        ether saddr @tp_spec_src_ac jump tp_spec_wan_ac
        jump tp_spec_wan_ac
    }

    chain tp_spec_lan_dg {
        ip daddr @tp_spec_dst_sp return
        meta l4proto { tcp, udp } jump tp_spec_lan_ac
    }

    chain tp_spec_wan_ac {
        ip daddr @tp_spec_dst_fw jump tp_spec_wan_fw
        ip daddr @tp_spec_dst_bp return
        jump tp_spec_wan_fw
    }

    chain tp_spec_wan_dg {
        ip daddr @tp_spec_dst_sp return
        ip daddr @tp_spec_dst_bp return
        ip daddr @tp_spec_def_gw return
        meta mark {{ sprintf("0x%08x", general.mark) }} return
        meta l4proto { tcp, udp } meta mark set 0x000000fc
    }

    chain tp_spec_wan_fw {
        meta l4proto tcp meta mark set 0x000000fb tproxy ip to 0.0.0.0:{{ general.tproxy_port_tcp }} accept
        meta l4proto udp meta mark set 0x000000fb tproxy ip to 0.0.0.0:{{ general.tproxy_port_udp }} accept
    }
