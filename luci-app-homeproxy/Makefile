# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2022-2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-homeproxy
PKG_VERSION:=20261026
PKG_RELEASE:=3
PKG_PO_VERSION:=$(PKG_VERSION)-r$(PKG_RELEASE)

LUCI_TITLE:=The modern ImmortalWRT proxy platform for ARM64/AMD64. Powered by Sing-Box/TUN/AI Edition
LUCI_DEPENDS:= \
	+luci-base \
	+sing-box \
	+firewall4 \
	+kmod-tun \
	+kmod-nft-queue \
	+curl \
	+flock \
	+unzip \
	+ucode-mod-digest \
	+ucode-mod-math
LUCI_EXTRA_DEPENDS:=sing-box (>=1.15.0_alpha10)
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/homeproxy
/etc/homeproxy/cache/
/etc/homeproxy/certs/
/etc/homeproxy/dashboard/
/etc/homeproxy/ruleset/
/etc/homeproxy/tailscale/
/etc/homeproxy/resources/
/etc/homeproxy/diversion/
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
