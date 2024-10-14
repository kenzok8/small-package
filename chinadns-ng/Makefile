# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=chinadns-ng
PKG_VERSION:=2024.10.14
PKG_RELEASE:=1

ifeq ($(ARCH),aarch64)
  ifeq ($(BOARD),rockchip)
    PKG_ARCH:=chinadns-ng+wolfssl@aarch64-linux-musl@generic+v8a@fast+lto
    PKG_HASH:=cc998570801317b94578b94430edcb344e652cab2d57c02be1bc6390bc6b9b24
  else
    PKG_ARCH:=chinadns-ng+wolfssl_noasm@aarch64-linux-musl@generic+v8a@fast+lto
    PKG_HASH:=914e8b66805b1804f6688dfcda3b67c7c45e5fc5e05afff4837450f8b67a8372
  endif
else ifeq ($(ARCH),arm)
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    PKG_ARCH:=chinadns-ng+wolfssl@arm-linux-musleabi@generic+v6+soft_float@fast+lto
    PKG_HASH:=4881e4dc20a1a4b21bc0cc3c378da8d8004274929e5900d5246aece230eea4f8
  else
    PKG_ARCH:=chinadns-ng+wolfssl@arm-linux-musleabihf@generic+v7a@fast+lto
    PKG_HASH:=5a47e56ef6fac90d22eabc766ffb817cb15fa3875b03ea2a4cd8a684b25b401a
  endif
else ifeq ($(ARCH),mips)
  PKG_ARCH:=chinadns-ng+wolfssl@mips-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=b57f9ba76ff4a7c52d1cfbe75de47f6f0e8a1bf8f2a293a39c10b5d94c99cc0f
else ifeq ($(ARCH),mipsel)
  PKG_ARCH:=chinadns-ng+wolfssl@mipsel-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=f0ca46e7ca83711ae24a6c0d7c71400d994dc7289cae599412fd8e654b198f3e
else ifeq ($(ARCH),mips64)
  PKG_ARCH:=chinadns-ng+wolfssl@mips64-linux-musl@mips64+soft_float@fast+lto
  PKG_HASH:=65406d60af2fbc5fc165bbb6233002020407572a7214d8e5bc64ed3099003e60
else ifeq ($(ARCH),i386)
  PKG_ARCH:=chinadns-ng+wolfssl@i386-linux-musl@i686@fast+lto
  PKG_HASH:=f29853387f51bdb4a993504a31933ece538f99365f3f3b46794caa75a3b653ba
else ifeq ($(ARCH),x86_64)
  PKG_ARCH:=chinadns-ng+wolfssl@x86_64-linux-musl@x86_64@fast+lto
  PKG_HASH:=6928e28f1c6c41099b6ce8ab1ce38a98cc9da75ff9533f8644f67be455463d0e
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
