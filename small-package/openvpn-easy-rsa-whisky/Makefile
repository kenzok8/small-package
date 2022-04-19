#
# Copyright (C) 2010-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_SOURCE_URL:=https://github.com/OpenVPN/easy-rsa.git
PKG_SOURCE_VERSION:=19a20046ca0110ad5435d69f481c5148726af252

PKG_NAME:=openvpn-easy-rsa
PKG_VERSION:=3.0.8
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.xz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION)
PKG_SOURCE_PROTO:=git

include $(INCLUDE_DIR)/package.mk

define Package/openvpn-easy-rsa-whisky
  TITLE:=CLI utility to build and manage a PKI CA.
  SECTION:=net
  CATEGORY:=Network
  URL:=http://openvpn.net
  SUBMENU:=VPN
  DEPENDS:=+openssl-util
  PKGARCH:=all
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/openvpn-easy-rsa-whisky/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/easyrsa3/easyrsa $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/easy-rsa/x509-types
	$(INSTALL_DATA) ./files/vars $(1)/etc/easy-rsa/vars
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/easyrsa3/openssl-easyrsa.cnf $(1)/etc/easy-rsa/openssl-easyrsa.cnf
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/easyrsa3/x509-types/* $(1)/etc/easy-rsa/x509-types/
endef

$(eval $(call BuildPackage,openvpn-easy-rsa-whisky))
