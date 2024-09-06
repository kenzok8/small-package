# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2022-2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

LUCI_TITLE:=The modern ImmortalWrt proxy platform for ARM64/AMD64
LUCI_PKGARCH:=all
LUCI_DEPENDS:= \
	+sing-box \
	+chinadns-ng \
	+firewall4 \
	+kmod-nft-tproxy \
	+unzip

PKG_NAME:=luci-app-homeproxy

define Package/luci-app-homeproxy/conffiles
/etc/config/homeproxy
/etc/homeproxy/certs/
/etc/homeproxy/ruleset/
/etc/homeproxy/resources/direct_list.txt
/etc/homeproxy/resources/proxy_list.txt
/etc/homeproxy/resources/clash_dashboard.ver
/etc/homeproxy/resources/*.zip
/etc/homeproxy/cache.db
endef

PKG_UNPACK=$(CURDIR)/.prepare.sh $(PKG_NAME) $(CURDIR) $(PKG_BUILD_DIR)

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
