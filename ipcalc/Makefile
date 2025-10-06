#
# Copyright (C) 2018-2023 Ycarus (Yannick Chabanois) <ycarus@zugaina.org>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ipcalc
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://gitlab.com/ipcalc/ipcalc.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=d8a2fe29a89f0f9f0d44a7b15e260c74f0e8388b
PKG_MAINTAINER:=Ycarus (Yannick Chabanois) <ycarus@zugaina.org>
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILE:=COPYING

include $(INCLUDE_DIR)/package.mk

MAKE_FLAGS += USE_GEOIP=no USE_MAXMIND=no

define Package/ipcalc
	SECTION:=net
	CATEGORY:=Network
	MAINTAINER:=Ycarus (Yannick Chabanois) <ycarus@zugaina.org>
	TITLE:=Modern tool to assist in network address calculations for IPv4 and IPv6.
endef

define Package/ipcalc/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipcalc $(1)/usr/sbin/ipcalc
endef


$(eval $(call BuildPackage,$(PKG_NAME)))
