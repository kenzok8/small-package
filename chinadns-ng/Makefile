# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=chinadns-ng
PKG_VERSION:=2024.05.12
PKG_RELEASE:=1

ifeq ($(ARCH),aarch64)
  PKG_ARCH:=chinadns-ng@aarch64-linux-musl@generic+v8a@fast+lto
  PKG_HASH:=5d09aab8dbea99935b864b8f2c569e95a4e7c23aad8f0b19860b145dc917106f
else ifeq ($(ARCH),arm)
  ARM_CPU_FEATURES:=$(word 2,$(subst +,$(space),$(call qstrip,$(CONFIG_CPU_TYPE))))
  ifeq ($(ARM_CPU_FEATURES),)
    PKG_ARCH:=chinadns-ng@arm-linux-musleabi@generic+v6+soft_float@fast+lto
    PKG_HASH:=34c80e973ce2b59185ad6771a280afd35b82941d08f072f46b620cf993b7eb94
  else
    PKG_ARCH:=chinadns-ng@arm-linux-musleabihf@generic+v7a@fast+lto
    PKG_HASH:=ceee46ac45c4f3228c22a0a56e623132a5ad5631f0ce6a2ea0d3a4002fa4480f
  endif
else ifeq ($(ARCH),mips)
  PKG_ARCH:=chinadns-ng@mips-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=8f13c199ca9b91106de2b1739dcc4decf0078f32e1c141deb02fe009659bd78e
else ifeq ($(ARCH),mipsel)
  PKG_ARCH:=chinadns-ng@mipsel-linux-musl@mips32+soft_float@fast+lto
  PKG_HASH:=f43940ee1691ca1edc7cb0e142e74087dc99ed260c79556a96e98846c66b63b7
else ifeq ($(ARCH),i386)
  PKG_ARCH:=chinadns-ng@i386-linux-musl@i686@fast+lto
  PKG_HASH:=a9af39f0a8781a596fd221e8e8285cc8d880865deb1cdd353274c7ac2df9865f
else ifeq ($(ARCH),x86_64)
  PKG_ARCH:=chinadns-ng@x86_64-linux-musl@x86_64@fast+lto
  PKG_HASH:=323e5aebba9d894e9f4f9adecad078092a4a54b8bb91f5468216386430f6c120
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
