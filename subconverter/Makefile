# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=subconverter
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/tindy2013/subconverter.git
PKG_SOURCE_DATE:=2023-10-09
PKG_SOURCE_VERSION:=e847df357bd9b4a2bb1b9188029d6f43a6da1041
PKG_MIRROR_HASH:=31fac089d96b4d37f5a2deb0c0e9123f2e58e778eafa5a0175a068edf58b8816
PKG_VERSION:=0.8.0-$(call version_abbrev,$(PKG_SOURCE_VERSION))

PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_DEPENDS:=jpcre2 rapidjson toml11
PKG_BUILD_FLAGS:=gc-sections lto

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/subconverter
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Utility to convert between various proxy subscription format
  URL:=https://github.com/tindy2013/subconverter
  DEPENDS:=+libatomic +libcron +libcurl +libevent2 +libpcre2 \
    +libquickjs +libstdcpp +libyaml-cpp
endef

# mips(el) & glibc require it
CMAKE_OPTIONS+= -DCMAKE_EXE_LINKER_FLAGS="-latomic"

TARGET_CXXFLAGS := $(filter-out -O%,$(TARGET_CXXFLAGS)) -O3
TARGET_CXXFLAGS += -Wall -Wextra

define Package/subconverter/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/subconverter $(1)/usr/bin/subconverter
	$(INSTALL_DIR) $(1)/etc/subconverter
	$(CP) $(PKG_BUILD_DIR)/base/* $(1)/etc/subconverter/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/subconverter.init $(1)/etc/init.d/subconverter
endef

$(eval $(call BuildPackage,subconverter))
