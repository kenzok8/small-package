include $(TOPDIR)/rules.mk

PKG_NAME:=sendat
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ouyangzq/sendat.git
PKG_SOURCE_DATE:=2024-01-22
PKG_SOURCE_VERSION:=624c58f6331e5be3eac6d144ed985b4a4af94b10
PKG_MIRROR_HASH:=b5243fd583604fd567b24400f2be859435e4e7f3393c974e054619c2c6f6d015

include $(INCLUDE_DIR)/package.mk

define Package/sendat
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=WWAN
  TITLE:=Send AT commands to serial
endef

MAKE_PATH:=src

define Package/sendat/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/sendat $(1)/usr/bin/
endef

$(eval $(call BuildPackage,sendat))
