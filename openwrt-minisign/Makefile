#
# Copyright (C) 2019 peter-tank@github.com
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=minisign
PKG_VERSION:=0.11
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/jedisct1/minisign.git
PKG_SOURCE_VERSION:=709fed6b739422f62dafce048669430fbc956770
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.xz

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=peter-tank

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION)

CMAKE_INSTALL:=1
PKG_BUILD_PARALLEL:=0
PKG_BUILD_DEPENDS:=libsodium

PKG_CONFIG_DEPENDS:= \
	CONFIG_$(PKG_NAME)_STATIC_LINK \
	CONFIG_$(PKG_NAME)_WITH_SODIUM

include $(INCLUDE_DIR)/package.mk

include $(INCLUDE_DIR)/cmake.mk

TARGET_CXXFLAGS += -Wall -Wextra
TARGET_CXXFLAGS += $(FPIC)

TARGET_CXXFLAGS += -DED25519_NONDETERMINISTIC

TARGET_CXXFLAGS := $(filter-out -O%,$(TARGET_CXXFLAGS)) -O3

TARGET_CXXFLAGS += -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections

define Package/minisign
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=A dead simple tool to sign files and verify signatures.
	URL:=https://github.com/jedisct1/minisign
	DEPENDS:=+libpthread \
		+!$(PKG_NAME)_WITH_SODIUM:libsodium
endef

define Package/minisign/config
menu "minisign Compile Configuration"
	config $(PKG_NAME)_STATIC_LINK
		bool "enable static link libraries."
		default y

		menu "Select libraries"
			depends on $(PKG_NAME)_STATIC_LINK
			config $(PKG_NAME)_WITH_SODIUM
				bool "static link libsodium."
				default y

		endmenu
endmenu
endef

define Package/minisign/description
Minisign is a dead simple tool to sign files and verify signatures.
endef

CMAKE_OPTIONS += -DCMAKE_STRIP=$(TOOLCHAIN_DIR)/bin/$(TARGET_CROSS)strip

ifeq ($(CONFIG_$(PKG_NAME)_STATIC_LINK),y)
	ifeq ($(CONFIG_$(PKG_NAME)_WITH_SODIUM),y)
		CMAKE_OPTIONS += -DSTATIC_LIBSODIUM=1
	endif
endif

define Package/minisign/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/minisign $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
