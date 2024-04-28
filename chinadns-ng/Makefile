# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=chinadns-ng
PKG_VERSION:=2024.04.27
PKG_RELEASE:=1

ifeq ($(ARCH),aarch64)
  PKG_ARCH:=chinadns-ng@aarch64-linux-musl@generic+v8a@fast+lto
  PKG_HASH:=61eb8132c640bea1879d239169ed55cef79606f273ee46bbf1fd13872d1c8fca
else ifeq ($(ARCH),arm)
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    PKG_ARCH:=chinadns-ng@arm-linux-musleabi@generic+v6+soft_float@fast+lto
    PKG_HASH:=05c5abfed04c0236bef25742f6753f800a5e14d9743ce18a506f6d205ca848d6
  else
    PKG_ARCH:=chinadns-ng@arm-linux-musleabihf@generic+v7a@fast+lto
    PKG_HASH:=489f2ac213391edd169233abeddec3efb1d2a763665db6fc51bddb2ecc553fd4
  endif
else ifeq ($(ARCH),mips)
  PKG_ARCH:=chinadns-ng@mips-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=7d30ffe8496353c9dabda5ff13b53953a10545418c0977b9d6929771a08e3769
else ifeq ($(ARCH),mipsel)
  PKG_ARCH:=chinadns-ng@mipsel-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=067c04e1aaf1772c9857290a42b47f6ad285dacac281cc48a711c6d804b68d5d
else ifeq ($(ARCH),i386)
  PKG_ARCH:=chinadns-ng@i386-linux-musl@i686@fast+lto
  PKG_HASH:=76b03582a5d9618ca95e7dcc712433683f0f74cfa9aba50aaeb2ac6316ef8721
else ifeq ($(ARCH),x86_64)
  PKG_ARCH:=chinadns-ng@x86_64-linux-musl@x86_64@fast+lto
  PKG_HASH:=36792a45c39304eca69e1cd5bb38c985c836e54b8672ab8cefe06a915b05f5c9
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
  DEPENDS:=@(aarch64||arm||i386||mips||mipsel||x86_64) @!(TARGET_x86_geode||TARGET_x86_legacy) +ipset
endef

define Build/Compile
endef

define Package/chinadns-ng/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/chinadns-ng $(1)/usr/bin
endef

$(eval $(call BuildPackage,chinadns-ng))
