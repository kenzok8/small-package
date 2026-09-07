# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2025 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=tuic-client
PKG_UPSTREAM_VERSION:=2.0.0-dev4
PKG_VERSION:=2.0.0_pre4
PKG_RELEASE:=1

TUIC_HASH_AARCH64:=0f9cf59e42482c9760cc5dab33246d470f62315d921ace69eba32e6707db4512
TUIC_HASH_ARMV7:=b6ca20ddcf56614b4044c30d5bdeeec3c121ca6d6d60565df5d07317af42abfc
TUIC_HASH_ARMV7HF:=674be311611406a9475fa2f954d352dd84bca7e49ba4d7265c945f12f52b2db0
TUIC_HASH_I686:=f58775774e94a2222e72aafa570510f96180f745dee40ce295404669b22a6449
TUIC_HASH_X86_64:=6b0af183a8b5634d5e1192ff88b6b6f212e3e0c33a7c7efd0c5828b0685eb372

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
