# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=chinadns-ng
PKG_VERSION:=2025.03.27
PKG_RELEASE:=1

ifeq ($(ARCH),aarch64)
  ifeq ($(BOARD),rockchip)
    PKG_ARCH:=chinadns-ng+wolfssl@aarch64-linux-musl@generic+v8a@fast+lto
    PKG_HASH:=2b3f77f1526da452c1884119dd01176a7964e0d3544b9fc624f67b2a7760613d
  else
    PKG_ARCH:=chinadns-ng+wolfssl_noasm@aarch64-linux-musl@generic+v8a@fast+lto
    PKG_HASH:=0d6f5f742a3c81f907639b5e1ef2b727870f7aafc67010728e88a7968079b9c0
  endif
else ifeq ($(ARCH),arm)
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    PKG_ARCH:=chinadns-ng+wolfssl@arm-linux-musleabi@generic+v6+soft_float@fast+lto
    PKG_HASH:=2d972e864a90d1c5e7c874e8ff1f1229fddc03e869c7be9f3b4bf4347a7f150a
  else
    PKG_ARCH:=chinadns-ng+wolfssl@arm-linux-musleabihf@generic+v7a@fast+lto
    PKG_HASH:=77faf3fea926752e2ab54a4d32b3de1c29ada8e075921a0e5bb219285d34d938
  endif
else ifeq ($(ARCH),mips)
  PKG_ARCH:=chinadns-ng+wolfssl@mips-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=b8ae32305069cccf01ef2704633ab326d69bd8ef7cfb71a30722d71e9cd6787e
else ifeq ($(ARCH),mipsel)
  PKG_ARCH:=chinadns-ng+wolfssl@mipsel-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=f12ce9b5227fefbf82401bd22379a52f2ec157c7cbe7e7dbdd2c0b2599e3a323
else ifeq ($(ARCH),mips64)
  PKG_ARCH:=chinadns-ng+wolfssl@mips64-linux-musl@mips64+soft_float@fast+lto
  PKG_HASH:=658d2f46caad44ba731193380b06faaeaa82501766584a6208ec4ff54d9b16e5
else ifeq ($(ARCH),i386)
  PKG_ARCH:=chinadns-ng+wolfssl@i386-linux-musl@i686@fast+lto
  PKG_HASH:=d9d0c3c38ca5b3ac266ae5753a0d87b37f571a6e2a8806699f858ad348afbf5e
else ifeq ($(ARCH),x86_64)
  PKG_ARCH:=chinadns-ng+wolfssl@x86_64-linux-musl@x86_64@fast+lto
  PKG_HASH:=37b337f1006b85176840f1b82508731a292751d1ee94bb3791578d04d63f856f
else
  PKG_HASH:=dummy
endif

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_ARCH)
PKG_SOURCE_URL:=https://github.com/zfl9/chinadns-ng/releases/download/$(PKG_VERSION)/$(PKG_ARCH)?
UNPACK_CMD=$(CP) $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)/$(PKG_NAME)

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
  DEPENDS:=@(aarch64||arm||i386||mips||mipsel||mips64||x86_64) +ipset
endef

define Build/Compile
endef

define Package/chinadns-ng/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/chinadns-ng $(1)/usr/bin
endef

$(eval $(call BuildPackage,chinadns-ng))
