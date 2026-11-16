#
# Copyright (C) 2015-2026 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=airconnect
PKG_VERSION:=1.12.4
PKG_RELEASE:=1

PKG_SOURCE:=AirConnect-$(PKG_VERSION)-src.tar.xz
PKG_SOURCE_URL:=https://github.com/sbwml/airconnect-src/releases/download/$(PKG_VERSION)/
PKG_HASH:=6822fe28b69cf215c86b1caf4a37e2400f390780bbfff9e1e86bae29b3875932

PKG_BUILD_DIR:=$(BUILD_DIR)/AirConnect-$(PKG_VERSION)

PKG_LICENSE:=MIT
PKG_LICENSE_FILE:=LICENSE
PKG_MAINTAINER:=sbwml <admin@cooluc.com>

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/airconnect
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=AirConnect
  DEPENDS:=+libpthread +libopenssl +libupnp +libflac +shine +jansson
  URL:=https://github.com/philippe44/AirConnect
endef

define Package/airconnect/description
  AirConnect enables AirPlay streaming to UPnP/Sonos and Chromecast devices.
endef

define Package/airconnect/conffiles
/etc/config/airconnect
endef

TARGET_CFLAGS += \
	-I$(STAGING_DIR)/usr/include/upnp \
	-I$(STAGING_DIR)/usr/include/shine \
	-I$(STAGING_DIR)/usr/include

TARGET_LDFLAGS += \
	-L$(STAGING_DIR)/usr/lib

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		all
endef

define Package/airconnect/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/airconnect.config $(1)/etc/config/airconnect

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/airconnect.init $(1)/etc/init.d/airconnect

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/aircast $(1)/usr/bin/aircast
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/airupnp $(1)/usr/bin/airupnp
endef

$(eval $(call BuildPackage,airconnect))
