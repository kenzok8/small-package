# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2022  sirpdboy  <herboy2008@gmail.com>
# 
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lucky
PKG_VERSION:=2.15.8
PKG_RELEASE:=1
PKGARCH:=all 

ifeq ($(ARCH),mipsel)
	LUCKY_ARCH:=mipsle_softfloat
endif
ifeq ($(ARCH),mips)
	LUCKY_ARCH:=mips_softfloat
endif
ifeq ($(ARCH),i386)
	LUCKY_ARCH:=i386
endif
ifeq ($(ARCH),x86_64)
	LUCKY_ARCH:=x86_64
endif
ifeq ($(ARCH),arm)
	LUCKY_ARCH:=armv7
endif
ifeq ($(BOARD),bcm53xx)
	LUCKY_ARCH:=armv6
ifeq ($(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE)))),)
	LUCKY_ARCH:=armv5
endif
endif
ifeq ($(BOARD),kirkwood)
	LUCKY_ARCH:=armv5
endif
ifeq ($(ARCH),aarch64)
	LUCKY_ARCH:=arm64
endif

PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=GDY666 <gdy666@foxmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_HASH:=63db49b178157ff3ff5bc89371353acf3fb9f833a40d14731b7a98b407f13d36

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Lucky dynamic domain name ddns-go service, socat,frp 
	DEPENDS:=@(i386||x86_64||arm||aarch64||mipsel||mips)
	URL:=https://github.com/gdy666/lucky
endef

define Package/$(PKG_NAME)/description
  Main functions of Lucky: dynamic domain name ddns-go service, socat,reverse proxy ,wake on lan
endef

define Build/Prepare
	[ ! -f $(PKG_BUILD_DIR)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz ] && wget https://github.com/gdy666/lucky/releases/download/v$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz -O $(PKG_BUILD_DIR)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
	tar -xzvf $(PKG_BUILD_DIR)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz -C $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lucky $(1)/usr/bin/lucky
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
