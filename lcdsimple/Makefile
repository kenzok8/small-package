#
# Copyright (C)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lcdsimple
PKG_VERSION:=1.0.3

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Simple monitor screen
	DEPENDS:=+libfreetype
endef

define Package/$(PKG_NAME)/description
	Simple monitor screen
endef

TARGET_CFLAGS += -I./ -I"$(STAGING_DIR)/usr/include/freetype2"
TARGET_LDFLAGS += -lfreetype -ldrm
MAKE_FLAGS += FPIC="$(FPIC)"

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/share/lcdsimple/assets $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lcdsimple $(1)/usr/sbin/lcdsimple
	$(INSTALL_BIN) ./files/lcdsimple.init $(1)/etc/init.d/lcdsimple
	$(INSTALL_BIN) ./files/lcdsimple.config $(1)/etc/config/lcdsimple
	$(INSTALL_BIN) ./files/lcdsimple.uci-default $(1)/etc/uci-defaults/lcdsimple
	$(CP) ./files/assets/* $(1)/usr/share/lcdsimple/assets/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
