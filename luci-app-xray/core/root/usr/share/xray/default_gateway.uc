#!/usr/bin/ucode
"use strict";

import { popen, stat } from "fs";
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
                dgs[j["source"]] = true;
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
        return `flush set inet fw4 tp_spec_dv4_dg\nadd element inet fw4 tp_spec_dv4_dg { ${join(", ", dg)} }\n`;
    }
    return "";
}

function gen_tp_spec_dv6_dg(pd) {
    if (length(pd) > 0) {
        return `flush set inet fw4 tp_spec_dv6_dg\nadd element inet fw4 tp_spec_dv6_dg { ${join(", ", pd)} }\n`;
    }
    return "";
}

function update_nft(dg, pd) {
    const process = popen("nft -f -", "w");
    process.write(gen_tp_spec_dv4_dg(dg));
    process.write(gen_tp_spec_dv6_dg(pd));
    process.flush();
    process.close();
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
    update_nft(dg, pd);
}
restart_dnsmasq_if_necessary();
