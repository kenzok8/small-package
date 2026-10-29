# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2025 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=tuic-client
PKG_UPSTREAM_VERSION:=2.0.0-dev10
PKG_VERSION:=2.0.0_pre10
PKG_RELEASE:=1

TUIC_HASH_AARCH64:=e2e357f3be41773ada13057a0ea2116b27e68abd200c76dda1c277bde18f6d92
TUIC_HASH_ARMV7:=2fc8ffcaab3af6ce9a8ad52fe7029fb708ac71229bbb73b70d1241f5f873e34b
TUIC_HASH_ARMV7HF:=9eef2aaf32591d5d351dcf7674f1c5a77b097f1ff4716d1c9339413961a3e7f0
TUIC_HASH_I686:=391f734badcb6adf3f7d1fa3d837af3f063d697d6a0862b209acd779b1913ffd
TUIC_HASH_X86_64:=ee5d5a55ab147b99f16c1e051247487d959df04ad8947097e285e4bde20e39d1

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
