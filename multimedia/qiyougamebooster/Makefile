# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qiyougamebooster
PKG_VERSION:=1.2.0
PKG_RELEASE:=1

PKG_LICENSE:=Proprietary
PKG_MAINTAINER:=qiyouacc, Internet1235

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=QiYou Game Booster
  DEPENDS:=@(aarch64||arm||mips||mipsel||i386||x86_64) +curl +ip-full +kmod-tun
  URL:=https://www.qiyou.cn
endef

define Package/$(PKG_NAME)/description
  Play console games online with less lag and more stability
  — now supporting PS, Switch, Xbox, PC, and mobile.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/qiyougamebooster
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(CURDIR)/files/qiyougamebooster.sh $(1)/usr/bin/qiyougamebooster.sh

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/qiyougamebooster.init $(1)/etc/init.d/qiyougamebooster

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/qiyougamebooster.config $(1)/etc/config/qiyougamebooster
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
