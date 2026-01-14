"use strict";

import { port_array, stream_settings } from "../common/stream.mjs";

export function hysteria_outbound(server, tag) {
    const stream_settings_object = stream_settings(server, "hysteria", tag);
    const stream_settings_result = stream_settings_object["stream_settings"];
    const dialer_proxy = stream_settings_object["dialer_proxy"];
    return {
        outbound: {
            protocol: "hysteria",
            tag: tag,
            settings: {
                address: server["server"],
                port: port_array(server["server_port"])[0],
            },
            streamSettings: stream_settings_result
        },
        dialer_proxy: dialer_proxy
    };
};
