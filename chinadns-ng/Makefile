# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=chinadns-ng
PKG_VERSION:=2024.03.25
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://github.com/zfl9/chinadns-ng/releases/download/$(PKG_VERSION)
UNPACK_CMD=$(CP) $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)/chinadns-ng

ifeq ($(ARCH),aarch64)
  PKG_SOURCE:=chinadns-ng@aarch64-linux-musl@generic+v8a@fast+lto
  PKG_HASH:=cd53686626f678fff3122b61aabee6c3bf9dad7e7577a8efc5f432fdeaf8d975
else ifeq ($(ARCH),arm)
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    PKG_SOURCE:=chinadns-ng@arm-linux-musleabi@generic+v7a@fast+lto
    PKG_HASH:=106a53e63991a78631c1ca6bfc648600bb9cabe08045b443acaaaf3113401b00
  else
    PKG_SOURCE:=chinadns-ng@arm-linux-musleabihf@generic+v7a@fast+lto
    PKG_HASH:=a04997e353732a77a374b869f8b37f5e7a3451e5659b8cb3db1e31f40f0a06d7
  endif
else ifeq ($(ARCH),mips)
  PKG_SOURCE:=chinadns-ng@mips-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=18970e6191661c3f2398a18ce8b003758c6a6c0f3c5d164a566fb108ab5bc1da
else ifeq ($(ARCH),mipsel)
  PKG_SOURCE:=chinadns-ng@mipsel-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=26aa029b141a3d25e078c4b92c06c93a87c06b0516e86c13d32a9ee865dd2ca2
else ifeq ($(ARCH),i386)
  PKG_SOURCE:=chinadns-ng@i386-linux-musl@i686@fast+lto
  PKG_HASH:=4147e3be49f5ef5c0200b6c62cb8036e7944b4f0729ede83faef33c828d6ff91
else ifeq ($(ARCH),x86_64)
  PKG_SOURCE:=chinadns-ng@x86_64-linux-musl@x86_64@fast+lto
  PKG_HASH:=ea17998c450eaf08cf82b8b2bc3767bd39f0d7686a53e1c5ad972b48db750974
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
