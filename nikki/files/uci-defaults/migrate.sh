#!/bin/sh

. "$IPKG_INSTROOT/etc/nikki/scripts/include.sh"

# commit
uci commit nikki

# exit with 0
exit 0
