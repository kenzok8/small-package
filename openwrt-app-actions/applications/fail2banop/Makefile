#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_FAIL2BANOP:=$(ARCH)

PKG_NAME:=fail2banop
# use PKG_SOURCE_DATE instead of PKG_VERSION for compitable
PKG_SOURCE_DATE:=1.0.1
PKG_RELEASE:=5
ARCH_HEXCODE:=
ifeq ($(ARCH),x86_64)
ARCH_HEXCODE=8664
else ifeq ($(ARCH),aarch64)
ARCH_HEXCODE=aa64
else ifeq ($(ARCH),arm)
ARCH_HEXCODE=aa32
else ifeq ($(ARCH),mipsel)
ARCH_HEXCODE=1b0c
endif
PKG_SOURCE_VERSION:=$(ARCH_HEXCODE)
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_SOURCE_DATE).tar.gz
PKG_SOURCE_URL:=https://github.com/linkease/fail2ban-openwrt/releases/download/v${PKG_SOURCE_DATE}/
PKG_HASH:=9460debf3025dc6519ce393a405bf5dc00f1396aa698f94f768ca467a5025537

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_SOURCE_DATE)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=fail2banop - Auto ban ip if the login is failed
	PKGARCH:=all
	URL:=https://github.com/linkease/fail2ban-openwrt
endef

define Package/$(PKG_NAME)/description
  Auto ban ip if the login is failed
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/fail2banop
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/fail2banop ] && /etc/uci-defaults/fail2banop && rm -f /etc/uci-defaults/fail2banop
	exit 0
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/share/nftables.d/chain-pre/input $(1)/usr/share/nftables.d/table-post
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fail2ban_op_bin.$(PKG_ARCH_FAIL2BANOP) $(1)/usr/sbin/fail2ban_op_bin
	$(INSTALL_CONF) ./files/fail2banop.config $(1)/etc/config/fail2banop
	$(INSTALL_BIN) ./files/fail2banop.init $(1)/etc/init.d/fail2banop
	$(INSTALL_BIN) ./files/fail2banop.uci-default $(1)/etc/uci-defaults/fail2banop
	$(INSTALL_DATA) ./files/nft-hook/chain-pre/input/20-fail2banop.nft $(1)/usr/share/nftables.d/chain-pre/input/
	$(INSTALL_DATA) ./files/nft-hook/table-post/21-fail2banop.nft $(1)/usr/share/nftables.d/table-post/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
