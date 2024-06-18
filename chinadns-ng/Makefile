# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=chinadns-ng
PKG_VERSION:=2024.05.12
PKG_RELEASE:=1

ifeq ($(ARCH),aarch64)
  ifeq ($(BOARD),rockchip)
    PKG_ARCH:=chinadns-ng+wolfssl@aarch64-linux-musl@generic+v8a@fast+lto
    PKG_HASH:=d907398d08a2cadd8ab5b3c6c353de572bddb87db1363a458703dd7e966ddb13
  else
    PKG_ARCH:=chinadns-ng+wolfssl_noasm@aarch64-linux-musl@generic+v8a@fast+lto
    PKG_HASH:=80435ead00ed10b0122d999ef654c44c5be2eb58a270c2d7634244d6db0d9127
  endif
else ifeq ($(ARCH),arm)
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    PKG_ARCH:=chinadns-ng+wolfssl@arm-linux-musleabi@generic+v6+soft_float@fast+lto
    PKG_HASH:=4f97d84065203f0e62815b2b0319818ac767698adad8ddc56a7974de08749e71
  else
    PKG_ARCH:=chinadns-ng+wolfssl@arm-linux-musleabihf@generic+v7a@fast+lto
    PKG_HASH:=86115b25ce082099c720169cbdee348dc8bbef3433f6a6580487ae6cc7fffd01
  endif
else ifeq ($(ARCH),mips)
  PKG_ARCH:=chinadns-ng+wolfssl@mips-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=9f2f95eaf74ee5fc00e750f512563f8db00e7181c0dbef86d98dfaa1ff5ee2c4
else ifeq ($(ARCH),mipsel)
  PKG_ARCH:=chinadns-ng+wolfssl@mipsel-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=aefe6a4e0aeffb74a568fe84d0a01ef033b1a702fff31ea97427538ad0e5a8f4
else ifeq ($(ARCH),i386)
  PKG_ARCH:=chinadns-ng+wolfssl@i386-linux-musl@i686@fast+lto
  PKG_HASH:=a80335eaf98f04c4cf433bcfddd5a66ec03e6084accdfb3e35f02df1c5626ea9
else ifeq ($(ARCH),x86_64)
  PKG_ARCH:=chinadns-ng+wolfssl@x86_64-linux-musl@x86_64@fast+lto
  PKG_HASH:=a32e16b69760aaf3b2ef463229f0668ea5ac58bd87408f7aac05ddb8e52915c5
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
  DEPENDS:=@(aarch64||arm||i386||mips||mipsel||x86_64) +ipset
endef

define Build/Compile
endef

define Package/chinadns-ng/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/chinadns-ng $(1)/usr/bin
endef

$(eval $(call BuildPackage,chinadns-ng))
