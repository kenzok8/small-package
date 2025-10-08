# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2024-2025 Anya Lin <hukk1996@gmail.com>

include $(TOPDIR)/rules.mk

LUCI_TITLE:=FullCombo Shark! supplies flexible customization of mihomo on OpenWrt.
LUCI_PKGARCH:=all
LUCI_DEPENDS:= \
	+mihomo \
	+ca-bundle \
	+firewall4 \
	+kmod-inet-diag \
	+kmod-nft-tproxy \
	+yq +wget-ssl +coreutils-timeout \
#	+ip-full +kmod-tun +dnsmasq-full \

PKG_NAME:=luci-app-fchomo

define Package/luci-app-fchomo/conffiles
/etc/config/fchomo
/etc/fchomo/certs/
/etc/fchomo/provider/
/etc/fchomo/ruleset/
/etc/fchomo/resources/
/etc/fchomo/templates/
/etc/fchomo/resources.json
/etc/fchomo/geoip.dat
/etc/fchomo/geosite.dat
/etc/fchomo/asn.mmdb
/etc/fchomo/cache.db
endef

PKG_UNPACK=$(CURDIR)/.prepare.sh $(PKG_NAME) $(CURDIR) $(PKG_BUILD_DIR)

define Package/luci-app-fchomo/postinst
#!/bin/sh
# openwrt version check
export REVISION VERSION_NUMBER ARCH_PACKAGES
if [ -n "$$IPKG_INSTROOT" ]; then
	# building
	REVISION=$$($$TOPDIR/scripts/getver.sh)
	REVISION=$$(echo "$$REVISION" | cut -f1 -d'-' | sed 's|[a-z]||gi')
else
	# system
	REVISION=$$(ubus call system board | jsonfilter -qe '@.release.revision' | cut -f1 -d'-' | sed 's|[a-z]||gi')
fi

[ "$$REVISION" -ge 28158 ] || { 2>&1 echo "Minimum OpenWrt version required is 24.10."; exit 1; }
# https://archive.openwrt.org/releases/**/version.buildinfo
# r?????-??????????    25.??.?-rc1
# r28158-d276b4c91a    24.10.0-rc1
# r23069-e2701e0f33    23.05.0-rc1
exit 0
endef

define Package/luci-app-fchomo/prerm
#!/bin/sh
uci delete firewall.fchomo_pre
uci delete firewall.fchomo_post
uci commit firewall
endef

# Disable CSStidy for compilation
#CONFIG_LUCI_CSSTIDY:=

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
