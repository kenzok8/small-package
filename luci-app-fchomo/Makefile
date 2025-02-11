# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2024-2025 Anya Lin <hukk1996@gmail.com>

include $(TOPDIR)/rules.mk

LUCI_TITLE:=FullCombo Shark! supplies maximum customization of mihomo on OpenWrt.
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

define Package/luci-app-fchomo/prerm
#!/bin/sh
uci delete firewall.fchomo_pre
uci delete firewall.fchomo_post
uci commit firewall
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
