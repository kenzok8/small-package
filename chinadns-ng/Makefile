# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=chinadns-ng
PKG_VERSION:=2024.04.30
PKG_RELEASE:=1

ifeq ($(ARCH),aarch64)
  PKG_ARCH:=chinadns-ng@aarch64-linux-musl@generic+v8a@fast+lto
  PKG_HASH:=4d9c7efd782bd77f215b371faa272e3a503412e0a934ef70bdbd4058f5e0c96f
else ifeq ($(ARCH),arm)
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    PKG_ARCH:=chinadns-ng@arm-linux-musleabi@generic+v6+soft_float@fast+lto
    PKG_HASH:=02ab8efb0522bc7ee2bf5e9ef0d8011a2916843ad192b473d7c2d7900fb6c498
  else
    PKG_ARCH:=chinadns-ng@arm-linux-musleabihf@generic+v7a@fast+lto
    PKG_HASH:=9bff2c01dd0a212a55f5c5a0e048c131a2f1515f7f9140b090f36c723be90aaf
  endif
else ifeq ($(ARCH),mips)
  PKG_ARCH:=chinadns-ng@mips-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=2c88fa6ba8412b4cd4c344a47d4bfbf6c11855163937308e5d9b8137fe9a2491
else ifeq ($(ARCH),mipsel)
  PKG_ARCH:=chinadns-ng@mipsel-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=db32bf9c40a532bff26822fdf41ebf55ababd2dc58da687f221230999e47bc10
else ifeq ($(ARCH),i386)
  PKG_ARCH:=chinadns-ng@i386-linux-musl@i686@fast+lto
  PKG_HASH:=46650b1a509b5c8369f5eecaefe09fa8bde78fa339a17258669f73498d63a557
else ifeq ($(ARCH),x86_64)
  PKG_ARCH:=chinadns-ng@x86_64-linux-musl@x86_64@fast+lto
  PKG_HASH:=611ccb0f3391798f2289362f4026e2e446f939309f0de6f2689e1551793d8274
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
