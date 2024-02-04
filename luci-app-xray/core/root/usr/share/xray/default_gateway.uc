#!/usr/bin/ucode
"use strict";

import { open, popen, stat } from "fs";
import { connect } from "ubus";

function network_dump() {
    const ubus = connect();
    if (ubus) {
        const result = ubus.call("network.interface", "dump");
        ubus.disconnect();
        return result;
    }
    return {
        "interface": []
    };
}

function get_default_gateway(dump) {
    let dgs = {};
    for (let i in dump["interface"] || []) {
        for (let j in i["route"] || []) {
            if (j["target"] == "0.0.0.0") {
                dgs[j["nexthop"]] = true;
                if (j["source"] != "0.0.0.0/0") {
                    dgs[j["source"]] = true;
                }
            }
        }
    };
    return keys(dgs);
}

function get_prefix_delegate(dump) {
    let pds = {};
    for (let i in dump["interface"] || []) {
        for (let j in i["ipv6-prefix"] || []) {
            if (j["assigned"]) {
                pds[`${j["address"]}/${j["mask"]}`] = true;
            }
        }
    }
    return keys(pds);
}

function gen_tp_spec_dv4_dg(dg) {
    if (stat("/usr/share/xray/ignore_tp_spec_def_gw")) {
        return "";
    }
    if (length(dg) > 0) {
        return `set tp_spec_dv4_dg {
            type ipv4_addr
            size 16
            flags interval
            elements = { ${join(", ", dg)} }
        }\n`;
    }
    return "";
}

function gen_tp_spec_dv6_dg(pd) {
    if (length(pd) > 0) {
        return `set tp_spec_dv6_dg {
            type ipv6_addr
            size 16
            flags interval
            elements = { ${join(", ", pd)} }
        }\n`;
    }
    return "";
}

function generate_include(rule_dg, rule_pd, file_path) {
    const handle = open(file_path, "w");
    handle.write(rule_dg);
    handle.write(rule_pd);
    handle.flush();
    handle.close();
}

function update_nft(rule_dg, rule_pd) {
    const handle = popen("nft -f -", "w");
    handle.write(`table inet fw4 {
        ${rule_dg}
        ${rule_pd}
    }`);
    handle.flush();
    handle.close();
}

function restart_dnsmasq_if_necessary() {
    if (stat("/usr/share/xray/restart_dnsmasq_on_iface_change")) {
        system("service dnsmasq restart");
    }
}

const dump = network_dump();
const dg = get_default_gateway(dump);
const pd = get_prefix_delegate(dump);
const log = join(", ", [...dg, ...pd]);
if (log == "") {
    print("default gateway not available, please wait for interface ready");
} else {
    print(`default gateway available at ${log}\n`);
    const rule_dg = gen_tp_spec_dv4_dg(dg);
    const rule_pd = gen_tp_spec_dv6_dg(pd);
    update_nft(rule_dg, rule_pd);
    generate_include(rule_dg, rule_pd, "/var/etc/xray/02_default_gateway_include.nft");
}
restart_dnsmasq_if_necessary();
