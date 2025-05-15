# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2025  sirpdboy  <herboy2008@gmail.com> 
# https://github.com/sirpdboy/luci-app-netspeedtest
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-netspeedtest

PKG_VERSION:=5.0.3
PKG_RELEASE:=20250515

LUCI_TITLE:=LuCI Support for netspeedtest
LUCI_DEPENDS:=+speedtest-cli +homebox $(if $(find_package iperf3-ssl),+iperf3-ssl,+iperf3)
LUCI_PKGARCH:=all
PKG_MAINTAINER:=sirpdboy  <herboy2008@gmail.com>


define Package/$(PKG_NAME)/conffiles
/etc/config/netspeedtest
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
    if ! uci show netspeedtest.config >/dev/null 2>&1; then
        uci set netspeedtest.config=netspeedtest
        uci set netspeedtest.config.enabled='1'
        uci commit netspeedtest
    fi
fi
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk


# call BuildPackage - OpenWrt buildroot signature
