# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=chinadns-ng
PKG_VERSION:=2024.09.08
PKG_RELEASE:=1

ifeq ($(ARCH),aarch64)
  ifeq ($(BOARD),rockchip)
    PKG_ARCH:=chinadns-ng+wolfssl@aarch64-linux-musl@generic+v8a@fast+lto
    PKG_HASH:=a8e61df163d8afe6e891bbbf615f7d12b83b5ff300816c6a9ee28cad0b62b2ff
  else
    PKG_ARCH:=chinadns-ng+wolfssl_noasm@aarch64-linux-musl@generic+v8a@fast+lto
    PKG_HASH:=bac7fa5355b60e811092bbc0ba3f44512682087c5af0cd5ca5864bfe264d41ed
  endif
else ifeq ($(ARCH),arm)
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    PKG_ARCH:=chinadns-ng+wolfssl@arm-linux-musleabi@generic+v6+soft_float@fast+lto
    PKG_HASH:=2e81cef3dae7e736fa98d6a4b2d654c5bbc2e13a0f128f22db564f4cac9a5283
  else
    PKG_ARCH:=chinadns-ng+wolfssl@arm-linux-musleabihf@generic+v7a@fast+lto
    PKG_HASH:=7d4f53b8982b415f087fafefb2568a317a0c241d0f79d0cf07ce2de089b11256
  endif
else ifeq ($(ARCH),mips)
  PKG_ARCH:=chinadns-ng+wolfssl@mips-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=e5784f4a4bded6a9856469a5d4605c15c1f6d02b13aeb1f46a38fa4f78537bbb
else ifeq ($(ARCH),mipsel)
  PKG_ARCH:=chinadns-ng+wolfssl@mipsel-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=129110ee8846323eeec7b44e0227b3b7a2a76cb493c30437a5d65be31e1289c9
else ifeq ($(ARCH),mips64)
  PKG_ARCH:=chinadns-ng+wolfssl@mips64-linux-musl@mips64+soft_float@fast+lto
  PKG_HASH:=c99247b3f7268651321340955a26edee00edcb6490017725f8d0722777830c4a
else ifeq ($(ARCH),i386)
  PKG_ARCH:=chinadns-ng+wolfssl@i386-linux-musl@i686@fast+lto
  PKG_HASH:=7ad9528daceb81e7e4376d80a6956ca947e6d096f5d3fb3b46a97f64b1c06ddc
else ifeq ($(ARCH),x86_64)
  PKG_ARCH:=chinadns-ng+wolfssl@x86_64-linux-musl@x86_64@fast+lto
  PKG_HASH:=862fa3efdb91cdbd9dacd74c6733a672e999410dbe9c6f2d48d479aae9454165
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
