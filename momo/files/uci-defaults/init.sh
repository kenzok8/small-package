#!/bin/sh

. "$IPKG_INSTROOT/etc/momo/scripts/include.sh"

# check momo.config.init
init=$(uci -q get momo.config.init); [ -z "$init" ] && return

# generate random string for api secret and authentication password
random=$(awk 'BEGIN{srand(); printf "%06d", int(rand() * 1000000)}')

# set momo.mixin.api_secret
uci set momo.mixin.external_control_api_secret="$random"

# remove momo.config.init
uci del momo.config.init

# commit
uci commit momo

# exit with 0
exit 0
