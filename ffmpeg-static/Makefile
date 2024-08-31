#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_ffmpeg:=$(ARCH)

PKG_NAME:=ffmpeg-static
PKG_VERSION:=0.0.1
PKG_RELEASE:=
PKG_SOURCE:=ffmpeg-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Carseason/openwrt-packages/releases/download/prebuilt/
PKG_HASH:=4dad394ac404672810ffa57d5d79d3ec0c3475f4b6bb788e967df195ca80d3a0
PKG_BUILD_DIR:=$(BUILD_DIR)/ffmpeg-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=FFMPEG
	URL:=https://github.com/Carseason/openwrt-packages
endef

define Package/$(PKG_NAME)/description
  A complete, cross-platform solution to record, convert and stream audio and video.
endef

define Package/$(PKG_NAME)/postinst
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ffmpeg.$(PKG_ARCH_ffmpeg) $(1)/usr/sbin/ffmpeg
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ffprobe.$(PKG_ARCH_ffmpeg) $(1)/usr/sbin/ffprobe
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
