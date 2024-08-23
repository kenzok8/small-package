# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=v2ray-geodata
PKG_RELEASE:=1

PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

include $(INCLUDE_DIR)/package.mk

GEOIP_VER:=202408220047
GEOIP_FILE:=geoip.dat.$(GEOIP_VER)
define Download/geoip
  URL:=https://github.com/v2fly/geoip/releases/download/$(GEOIP_VER)/
  URL_FILE:=geoip.dat
  FILE:=$(GEOIP_FILE)
  HASH:=2c6b6ee15f4593a7b54853c8db5a2b881986ae405122d9fa1427f33c26316ff3
endef

GEOSITE_VER:=20240823035651
GEOSITE_FILE:=dlc.dat.$(GEOSITE_VER)
define Download/geosite
  URL:=https://github.com/v2fly/domain-list-community/releases/download/$(GEOSITE_VER)/
  URL_FILE:=dlc.dat
  FILE:=$(GEOSITE_FILE)
  HASH:=e9197238b1b4e6e6ae9f35dfc40484936093562bef354501981bf8d5e29950da
endef

GEOSITE_IRAN_VER:=202408190030
GEOSITE_IRAN_FILE:=iran.dat.$(GEOSITE_IRAN_VER)
define Download/geosite-ir
  URL:=https://github.com/bootmortis/iran-hosted-domains/releases/download/$(GEOSITE_IRAN_VER)/
  URL_FILE:=iran.dat
  FILE:=$(GEOSITE_IRAN_FILE)
  HASH:=43f48f650b5259f82024a995990d2c5b55e79123773ce5c4ca332d8cb24707e4
endef

define Package/v2ray-geodata/template
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  URL:=https://www.v2fly.org
  PKGARCH:=all
endef

define Package/v2ray-geoip
  $(call Package/v2ray-geodata/template)
  TITLE:=GeoIP List for V2Ray
  VERSION:=$(GEOIP_VER)-$(PKG_RELEASE)
  LICENSE:=CC-BY-SA-4.0
endef

define Package/v2ray-geosite
  $(call Package/v2ray-geodata/template)
  TITLE:=Geosite List for V2Ray
  VERSION:=$(GEOSITE_VER)-$(PKG_RELEASE)
  LICENSE:=MIT
endef

define Package/v2ray-geosite-ir
  $(call Package/v2ray-geodata/template)
  TITLE:=Iran Geosite List for V2Ray
  PROVIDES:=xray-geosite-ir
  VERSION:=$(GEOSITE_IRAN_VER)-$(PKG_RELEASE)
  LICENSE:=MIT
endef

define Build/Prepare
	$(call Build/Prepare/Default)
ifneq ($(CONFIG_PACKAGE_v2ray-geoip),)
	$(call Download,geoip)
endif
ifneq ($(CONFIG_PACKAGE_v2ray-geosite),)
	$(call Download,geosite)
endif
ifneq ($(CONFIG_PACKAGE_v2ray-geosite-ir),)
	$(call Download,geosite-ir)
endif
endef

define Build/Compile
endef

define Package/v2ray-geoip/install
	$(INSTALL_DIR) $(1)/usr/share/v2ray
	$(INSTALL_DATA) $(DL_DIR)/$(GEOIP_FILE) $(1)/usr/share/v2ray/geoip.dat
endef

define Package/v2ray-geosite/install
	$(INSTALL_DIR) $(1)/usr/share/v2ray
	$(INSTALL_DATA) $(DL_DIR)/$(GEOSITE_FILE) $(1)/usr/share/v2ray/geosite.dat
endef

define Package/v2ray-geosite-ir/install
	$(INSTALL_DIR) $(1)/usr/share/v2ray $(1)/usr/share/xray
	$(INSTALL_DATA) $(DL_DIR)/$(GEOSITE_IRAN_FILE) $(1)/usr/share/v2ray/iran.dat
	$(LN) ../v2ray/iran.dat $(1)/usr/share/xray/iran.dat
endef

$(eval $(call BuildPackage,v2ray-geoip))
$(eval $(call BuildPackage,v2ray-geosite))
$(eval $(call BuildPackage,v2ray-geosite-ir))
