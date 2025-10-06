# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=vlmcsd
PKG_RELEASE:=8

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Wind4/vlmcsd.git
PKG_SOURCE_DATE:=2020-03-30
PKG_SOURCE_VERSION:=e599080486478e219cd065e141d6de050a450c27
PKG_MIRROR_HASH:=a5b9854a7cb2055fa2c7890ee196a7fbbec1fd6165bf5115504d160e2e3a7a19

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=fuyumi <280604399@qq.com>

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/vlmcsd
  SECTION:=net
  CATEGORY:=Network
  TITLE:=A KMS Emulator in C
  URL:=https://github.com/Wind4/vlmcsd
  DEPENDS:=+libpthread
  USERID:=vlmcsd:vlmcsd
endef

define Package/vlmcsd/description
  KMS Emulator in C (currently runs on Linux including Android, FreeBSD,
  Solaris, Minix, Mac OS, iOS, Windows with or without Cygwin)
endef

define Package/vlmcsd/conffiles
/etc/config/vlmcsd
/etc/vlmcsd.ini
endef

MAKE_FLAGS += \
	CC="$(TARGET_CC_NOCACHE)" \
	VLMCSD_VERSION="$(PKG_VERSION)"

define Package/vlmcsd/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/vlmcsd $(1)/usr/bin/vlmcsd

	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_BIN) ./files/vlmcsd.ini $(1)/etc/vlmcsd.ini
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) ./files/vlmcsd.conf $(1)/etc/config/vlmcsd
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/vlmcsd.init $(1)/etc/init.d/vlmcsd
endef

$(eval $(call BuildPackage,vlmcsd))
