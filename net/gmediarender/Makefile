# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=gmediarender
PKG_VERSION:=0.3
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/hzeller/gmrender-resurrect/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=dbe0d41b01339a4805fdd0edf914fbc4870dba2eb9c54ad5bf9446ccfd3fa482
PKG_BUILD_DIR:=$(BUILD_DIR)/gmrender-resurrect-$(PKG_VERSION)

PKG_FIXUP:=autoreconf
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/gmediarender
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=Resource efficient UPnP/DLNA renderer
  DEPENDS:=+glib2 +gstreamer1 +gstreamer1-utils +gst1-plugins-base \
    +gst1-plugins-bad +gst1-plugins-good +libupnp
endef

define Package/gmediarender/description
  gmediarender implements the server component that provides UPnP
  controllers a means to render media content (audio, video and images)
  from a UPnP media server.
endef

define Package/gmediarender/config
	select PACKAGE_gstreamer1-plugins-bad
	select PACKAGE_gstreamer1-plugins-good
endef

define Package/gmediarender/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/gmediarender $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/share/gmediarender
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/share/gmediarender/grender-*.png $(1)/usr/share/gmediarender/
endef

$(eval $(call BuildPackage,gmediarender))
