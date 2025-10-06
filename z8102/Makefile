#
# Copyright (C) 2018-2023 Ycarus (Yannick Chabanois) <ycarus@zugaina.org> for OpenMPTCProuter
#
# Originally made by DairyMan@Whirlpool come from https://github.com/ofmodemsandmen/ROOterSource2305/tree/main/package/rooter/0routerspecfic/z8102
# 

include $(TOPDIR)/rules.mk

PKG_NAME:=z8102
PKG_VERSION:=0.2
PKG_RELEASE:=1

PKG_MAINTAINER:=Yannick Chabanois <contact@openmptcprouter.com>

include $(INCLUDE_DIR)/package.mk

define Package/z8102
  SECTION:=OMR
  CATEGORY:=OpenMPTCProuter
  TITLE:=Install scripts for z8102
  DEPENDS:=+gpiod-tools
  PKGARCH:=all
endef

define Package/z8102/description
  Helper scripts to install scripts for z8102
endef


define Build/Compile
endef

define Package/z8102/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,z8102))
