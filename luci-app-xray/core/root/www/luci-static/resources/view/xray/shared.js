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
    variant: variant
});
