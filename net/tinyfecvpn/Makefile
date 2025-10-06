#
# Copyright (c) 2017 Yu Wang <wangyucn@gmail.com>
#
# This is free software, licensed under the MIT.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tinyfecVPN
PKG_VERSION:=20230206.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/wangyu-/tinyfecVPN.git
PKG_SOURCE_VERSION:=057b71f28d7c41ee220804cead976ec60c7fd5c8
PKG_MIRROR_HASH:=eb8ed90f3bfb64e046ef86f0881d992dd3c7586c22a88561559a6d1d005ebf3a

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Yu Wang

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/tinyfecvpn
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=A Network Improving Tool
  URL:=https://github.com/wangyu-/tinyfecVPN
  DEPENDS:=+libstdcpp +kmod-tun
endef

define Package/tinyfecvpn/description
  A Lightweight VPN with Build-in Forward Error Correction Support
  (or A Network Improving Tool which works at VPN mode). Improves
  your Network Quality on a High-latency Lossy Link.
endef

MAKE_FLAGS += \
	cc_cross=$(TARGET_CXX) \
	nolimit_cross

define Build/Configure
	$(SED) 's,cross:git_version,cross:,g' $(PKG_BUILD_DIR)/makefile
	echo 'const char *gitversion = "$(PKG_SOURCE_VERSION)";' > $(PKG_BUILD_DIR)/git_version.h

	$(call Build/Configure/Default)
endef

define Package/tinyfecvpn/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tinyvpn_cross $(1)/usr/bin/tinyvpn
endef

$(eval $(call BuildPackage,tinyfecvpn))
