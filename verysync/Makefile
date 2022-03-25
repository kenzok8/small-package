# SPDX-Identifier-License: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

ifeq ($(ARCH),x86_64)
	PKG_ARCH_VERYSYNC:=amd64
endif
ifeq ($(ARCH),mipsel)
	PKG_ARCH_VERYSYNC:=mipsle
endif
ifeq ($(ARCH),mips)
	PKG_ARCH_VERYSYNC:=mips
endif
ifeq ($(ARCH),i386)
	PKG_ARCH_VERYSYNC:=386
endif
ifeq ($(ARCH),arm)
	PKG_ARCH_VERYSYNC:=arm
endif
ifeq ($(ARCH),aarch64)
	PKG_ARCH_VERYSYNC:=arm64
endif
ifeq ($(ARCH),powerpc64)
	PKG_ARCH_VERYSYNC:=ppc64
endif

PKG_NAME:=verysync
PKG_VERSION:=2.13.2
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE:=$(PKG_NAME)-linux-$(PKG_ARCH_VERYSYNC)-v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://dl.verysync.com/releases/v$(PKG_VERSION)/ \
		http://dl-cn.verysync.com/releases/v$(PKG_VERSION)/
PKG_HASH:=skip
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-linux-$(PKG_ARCH_VERYSYNC)-v$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/verysync
  SECTION:=net
  CATEGORY:=Network
  TITLE:=A efficient data transmission tool
  URL:=http://www.verysync.com
endef

define Build/Compile
endef

define Package/verysync/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/verysync $(1)/usr/bin/verysync
endef

$(eval $(call BuildPackage,verysync))
