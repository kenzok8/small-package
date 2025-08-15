#!/bin/sh

. "$IPKG_INSTROOT/etc/momo/scripts/include.sh"

# migrate

section_placeholder=$(uci -q get momo.placeholder); [ -z "$section_placeholder" ] && uci set momo.placeholder="placeholder"

# commit
uci commit momo

# exit with 0
exit 0
