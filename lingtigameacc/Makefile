# SPDX-License-Identifier: GPL-3.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lingtigameacc
PKG_VERSION:=2.1.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(ARCH).tar.gz
PKG_SOURCE_URL:=https://res.lingti666.com/router/$(PKG_VERSION)/lingti-router-$(ARCH).tar.gz?
PKG_HASH:=skip

PKG_LICENSE:=Proprietary

include $(INCLUDE_DIR)/package.mk

STRIP:=true

TAR_CMD=$(HOST_TAR) -C $(1)/ $(TAR_OPTIONS)

define Package/lingtigameacc
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=@(aarch64||arm||mips||mipsel||x86_64) +kmod-tun
  TITLE:=LingTi Game Acc
  URL:=https://game.lingti.com
endef

define Package/lingtigameacc/description
  LingTi Game Acc is a Game Accelerator which is paid service.
endef

define Build/Compile
endef

define Package/lingtigameacc/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lingti $(1)/usr/bin/lingti

	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_CONF) ./files/lingti.config $(1)/etc/config/lingtigameacc
	$(INSTALL_BIN) ./files/lingti.init $(1)/etc/init.d/lingtigameacc
endef

$(eval $(call BuildPackage,lingtigameacc))
