# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2025 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=tuic-client
PKG_UPSTREAM_VERSION:=1.5.2
PKG_VERSION:=1.5.2
PKG_RELEASE:=1

TUIC_HASH_AARCH64:=63b6dfb7e8f4d6cdc7412405cd89ed19ce99c7475031bbcaf0bb9be64264eb0a
TUIC_HASH_ARMV7:=eac1426b7a967291238fa391c3d32fd24d5b0f8ed65d7b9c04fa59dc628e1ba5
TUIC_HASH_ARMV7HF:=d3d73e6451da287d66968631062ffdb7408ccc203f87ad27d07a0c051973ca6a
TUIC_HASH_I686:=5a93917774fa2c9ad5f6067435f9a2fb62d8790141fdc260ed3b2ac9cf81978f
TUIC_HASH_X86_64:=24a6ec967ab86392b56be317e8d3ba9fd942871e1c55040faf0a87277d09d5ef

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
