"use strict";

import { stream_settings } from "../common/stream.mjs";

export function shadowsocks_outbound(server, tag) {
    const stream_settings_object = stream_settings(server, "shadowsocks", tag);
    const stream_settings_result = stream_settings_object["stream_settings"];
    const dialer_proxy = stream_settings_object["dialer_proxy"];
    return {
        outbound: {
            protocol: "shadowsocks",
            tag: tag,
            settings: {
                servers: [
                    {
                        address: server["server"],
                        port: int(server["server_port"]),
                        password: server["password"],
                        method: server["shadowsocks_security"],
                        uot: server["shadowsocks_udp_over_tcp"] == '1'
                    }
                ]
            },
            streamSettings: stream_settings_result
        },
        dialer_proxy: dialer_proxy
    };
};
