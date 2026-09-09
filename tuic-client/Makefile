# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2025 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=tuic-client
PKG_UPSTREAM_VERSION:=2.0.0-dev5
PKG_VERSION:=2.0.0_pre5
PKG_RELEASE:=1

TUIC_HASH_AARCH64:=9491a3d817288972555bba4e6ad853adf97723235ebb0bd7daba69584404c6cc
TUIC_HASH_ARMV7:=021ebfbfa9f7f7f005c0501b6391dcd9e23e121553bad32943c1d8cb0c0f213e
TUIC_HASH_ARMV7HF:=1de389a016faedde858706be98187a19bc1b55276030b1a4903110782ae3773e
TUIC_HASH_I686:=d35be9cd8289afbb7fb4653b1763d760ffdb22282ec81277defcd643e2b2bb66
TUIC_HASH_X86_64:=78ecf1c1250ddd2926459ffed47b25832e19e0ea9deda204dfcd9519a274e5ab

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
