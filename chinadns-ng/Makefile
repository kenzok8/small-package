# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=chinadns-ng
PKG_VERSION:=2024.03.07
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://github.com/zfl9/chinadns-ng/releases/download/$(PKG_VERSION)
UNPACK_CMD=$(CP) $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)/chinadns-ng

ifeq ($(ARCH),aarch64)
  PKG_SOURCE:=chinadns-ng@aarch64-linux-musl@generic+v8a@fast+lto
  PKG_HASH:=a699d6d6a3b03b068d6a52fa411611f0e6738a51b5c43cb745c36e2d155e03d8
else ifeq ($(ARCH),arm)
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    PKG_SOURCE:=chinadns-ng@arm-linux-musleabi@generic+v7a@fast+lto
    PKG_HASH:=0c77f8d7631cca22d1816a90655b407b9f82bbb349ac221d12a9a26da6c72dcb
  else
    PKG_SOURCE:=chinadns-ng@arm-linux-musleabihf@generic+v7a@fast+lto
    PKG_HASH:=02ef7b8c9d54a1718fa7f6832bbdc04b9c3e2f29ecb89f726c801030c1f0a3b4
  endif
else ifeq ($(ARCH),mips)
  PKG_SOURCE:=chinadns-ng@mips-linux-musl@mips32@fast+lto
  PKG_HASH:=5d04803e8353f69d0358ce14d2c44579cf286477d3457e72ce8a3f6659b6625f
else ifeq ($(ARCH),mipsel)
  PKG_SOURCE:=chinadns-ng@mipsel-linux-musl@mips32@fast+lto
  PKG_HASH:=10bf2f022596ed69585876cb126aa487e6585a574ec2787f535d0b7b419b3c58
else ifeq ($(ARCH),i386)
  PKG_SOURCE:=chinadns-ng@i386-linux-musl@i686@fast+lto
  PKG_HASH:=fef4eeb0533dbec588cdbc768e9eaa6d6087eb484f0a693a4ec677e06d3caa46
else ifeq ($(ARCH),x86_64)
  PKG_SOURCE:=chinadns-ng@x86_64-linux-musl@x86_64@fast+lto
  PKG_HASH:=f2cb388d150b836228dc114d25867fc649fdd56a6ff04d35c1ef6df5025f0888
else
  PKG_SOURCE:=dummy
  PKG_HASH:=dummy
endif

PKG_LICENSE:=AGPL-3.0-only
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=sbwml <admin@cooluc.com>

include $(INCLUDE_DIR)/package.mk

define Package/chinadns-ng
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  TITLE:=ChinaDNS next generation, refactoring with epoll and ipset.
  URL:=https://github.com/zfl9/chinadns-ng
  DEPENDS:=@(aarch64||arm||i386||mips||mipsel||x86_64) @!(TARGET_x86_geode||TARGET_x86_legacy) +ipset
endef

define Build/Compile
endef

define Package/chinadns-ng/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/chinadns-ng $(1)/usr/bin
endef

$(eval $(call BuildPackage,chinadns-ng))
