'use strict';
'require baseclass';
'require uci';

const variant = "xray_core";

function badge(text, tooltip) {
    let options = { 'class': 'ifacebadge' };
    if (tooltip) {
        options["data-tooltip"] = tooltip;
    }
    return E('span', options, text);
}

return baseclass.extend({
    badge: badge,
    validate_object: function (id, a) {
        if (a == "") {
            return true;
        }
        try {
            const t = JSON.parse(a);
            if (Array.isArray(t)) {
                return "TypeError: Requires an object here, got an array";
            }
            if (t instanceof Object) {
                return true;
            }
            return "TypeError: Requires an object here, got a " + typeof t;
        } catch (e) {
            return e;
        }
    },
    validate_ip_or_geoip: function (id, a) {
        if (a == "") {
            return true;
        }
        if (a.startsWith("geoip:") || a.startsWith("ext:")) {
            return true;
        }
        return this.validation.parseIPv4(a) !== null || this.validation.parseIPv6(a) !== null || "Invalid IP address or rule: " + a;
    },
    validate_port_expression: function (id, a) {
        if (a == "") {
            return true;
        }
        const values = a.split(",");
        for (let v of values) {
            const parts = v.split("-").map(part => part === "" ? NaN : Number(part.trim()));
            if (parts.length > 2 || parts.some(part => isNaN(part) || part < 0 || part > 65535)) {
                return "Invalid expression: " + v;
            }
            if (parts.length === 2 && parts[0] > parts[1]) {
                return "Invalid port range: " + v;
            }
        }
        return true;
    },
    variant: variant
});
