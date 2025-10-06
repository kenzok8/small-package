include $(TOPDIR)/rules.mk

PKG_NAME:=modemband
PKG_VERSION:=20250928
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/modemband
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Setting LTE/5G bands for selected modems
	MAINTAINER:=Cezary Jackiewicz <cezary@eko.one.pl>
	PKGARCH:=all
	DEPENDS:=+sms-tool
endef

define Build/Compile
endef

define Package/modemband/install
	$(CP) ./files/* $(1)
endef

$(eval $(call BuildPackage,modemband))
