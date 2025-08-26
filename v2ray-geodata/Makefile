#
# Copyright (C) 2015-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray-geodata
PKG_VERSION:=$(shell date "+%Y.%m.%d")
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=sbwml <admin@cooluc.com>

include $(INCLUDE_DIR)/package.mk

define Package/v2ray-geodata/default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  URL:=https://www.v2fly.org
  PKGARCH:=all
endef

define Package/v2ray-geoip
  $(call Package/v2ray-geodata/default)
  TITLE:=GeoIP List for V2Ray
  LICENSE:=CC-BY-SA-4.0
endef

define Package/v2ray-geosite
  $(call Package/v2ray-geodata/default)
  TITLE:=Geosite List for V2Ray
  LICENSE:=GPL-3.0
endef

GEOIP_URL:=https://github.com/Loyalsoldier/geoip/releases/latest/download/geoip-only-cn-private.dat
GEOSITE_URL:=https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

define Build/Compile
	( \
		pushd $(PKG_BUILD_DIR) ; \
		curl -L $(GEOIP_URL) -o geoip.dat --progress-bar ; \
		curl -L $(GEOSITE_URL) -o geosite.dat --progress-bar ; \
		[ "$(curl -sL $(GEOIP_URL).sha256sum | awk '{print $1}')" != "$(sha256sum geoip.dat | awk '{print $1}')" ] && exit 1 ; \
		[ "$(curl -sL $(GEOSITE_URL).sha256sum | awk '{print $1}')" != "$(sha256sum geosite.dat | awk '{print $1}')" ] && exit 1 ; \
		popd ; \
	)
endef

define Package/v2ray-geoip/install
	$(INSTALL_DIR) $(1)/usr/share/v2ray
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/geoip.dat $(1)/usr/share/v2ray/geoip.dat
endef

define Package/v2ray-geosite/install
	$(INSTALL_DIR) $(1)/usr/share/v2ray
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/geosite.dat $(1)/usr/share/v2ray/geosite.dat
endef

$(eval $(call BuildPackage,v2ray-geoip))
$(eval $(call BuildPackage,v2ray-geosite))
