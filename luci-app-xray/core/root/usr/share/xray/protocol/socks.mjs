"use strict";

import { port_array, stream_settings } from "../common/stream.mjs";

export function socks_outbound(server, tag) {
    const stream_settings_object = stream_settings(server, "socks", tag);
    const stream_settings_result = stream_settings_object["stream_settings"];
    const dialer_proxy = stream_settings_object["dialer_proxy"];
    let users = null;
    if (server["username"] && server["password"]) {
        users = [
            {
                user: server["username"],
                pass: server["password"],
            }
        ];
    }
    return {
        outbound: {
            protocol: "socks",
            tag: tag,
            settings: {
                servers: map(port_array(server["server_port"]), function (v) {
                    return {
                        address: server["server"],
                        port: v,
                        users: users
                    };
                })
            },
            streamSettings: stream_settings_result
        },
        dialer_proxy: dialer_proxy
    };
};
