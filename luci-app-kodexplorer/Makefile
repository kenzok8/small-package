# Copyright (C) 2018-2026 Lienol <lawlienol@gmail.com>
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-kodexplorer
PKG_VERSION:=20220109
PKG_RELEASE:=3

LUCI_TITLE:=LuCI support for KodExplorer
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/config

config PACKAGE_$(PKG_NAME)_depends
	depends on PACKAGE_$(PKG_NAME)
	bool
	default y
	select PACKAGE_nginx-ssl
	select PACKAGE_unzip
	select PACKAGE_zoneinfo-asia
	select PACKAGE_php8
	select PACKAGE_php8-fastcgi
	select PACKAGE_php8-fpm
	select PACKAGE_php8-mod-curl
	select PACKAGE_php8-mod-dom
	select PACKAGE_php8-mod-gd
	select PACKAGE_php8-mod-iconv
	select PACKAGE_php8-mod-mbstring
	select PACKAGE_php8-mod-opcache
	select PACKAGE_php8-mod-pdo
	select PACKAGE_php8-mod-pdo-mysql
	select PACKAGE_php8-mod-pdo-sqlite
	select PACKAGE_php8-mod-session
	select PACKAGE_php8-mod-sqlite3
	select PACKAGE_php8-mod-xml
	select PACKAGE_php8-mod-xmlreader
	select PACKAGE_php8-mod-xmlwriter
	select PACKAGE_php8-mod-zip

endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
