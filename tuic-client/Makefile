# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2025 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=tuic-client
PKG_UPSTREAM_VERSION:=2.0.0-dev3
PKG_VERSION:=2.0.0_pre3
PKG_RELEASE:=1

TUIC_HASH_AARCH64:=45d61e97532157354ad2af27c34fbe26ec4b3429c4e4d0a3b02f0fc5cf7d31d6
TUIC_HASH_ARMV7:=065659cd12ab03e873fcecc5142fa69e40c55c56f4932a9545463e9cf4ed0cad
TUIC_HASH_ARMV7HF:=dc94542a1cf6758b9f2c20b4cecb73c66292cba4f8371fd6b3cce5b8a45bd709
TUIC_HASH_I686:=39dc1a25ea083104e01bb0d9e4ad51d2590178b32b55caf1cb78f18d28a96735
TUIC_HASH_X86_64:=b547bdd77400726328ccd7d4950309feb7d0803ce8a03dcc7df401fb7b65502c

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>
PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

ifeq ($(ARCH),aarch64)
	TUIC_ARCH:=tuic-client-aarch64-linux-musl
	PKG_HASH:=$(TUIC_HASH_AARCH64)
else ifeq ($(ARCH),arm)
	ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
	ifeq ($(ARM_CPU_FEATURES),)
		TUIC_ARCH:=tuic-client-armv7-linux-musl
		PKG_HASH:=$(TUIC_HASH_ARMV7)
	else
		TUIC_ARCH:=tuic-client-armv7-linux-muslhf
		PKG_HASH:=$(TUIC_HASH_ARMV7HF)
	endif
else ifeq ($(ARCH),i386)
	TUIC_ARCH:=tuic-client-i686-linux-musl
	PKG_HASH:=$(TUIC_HASH_I686)
else ifeq ($(ARCH),x86_64)
	TUIC_ARCH:=tuic-client-x86_64-linux-musl
	PKG_HASH:=$(TUIC_HASH_X86_64)
else
	PKG_SOURCE:=dummy
	PKG_HASH:=dummy
endif

define Download/tuic-client
	URL:=https://github.com/Itsusinn/tuic/releases/download/v$(PKG_UPSTREAM_VERSION)/
	URL_FILE:=$(TUIC_ARCH)
	FILE:=$(TUIC_ARCH)-$(PKG_UPSTREAM_VERSION)
	HASH:=$(PKG_HASH)
endef

$(eval $(call Download,tuic-client))

define Package/tuic-client
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=TUIC proxy protocol client
  URL:=https://github.com/Itsusinn/tuic
  DEPENDS:=@USE_MUSL @(aarch64||arm_v7||i386||x86_64) @!(TARGET_x86_geode||TARGET_x86_legacy)
endef

define Package/tuic-client/description
  Delicately-TUICed 0-RTT proxy protocol client.
endef

define Build/Compile
endef

define Package/tuic-client/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(DL_DIR)/$(TUIC_ARCH)-$(PKG_UPSTREAM_VERSION) $(1)/usr/bin/tuic-client
endef

$(eval $(call BuildPackage,tuic-client))
