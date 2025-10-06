# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2025 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=3proxy
PKG_VERSION:=0.9.5
PKG_RELEASE:=4

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/3proxy/3proxy/tar.gz/$(PKG_VERSION)?
PKG_HASH:=6f6da51d9bba93231e12acd707bb6cf86a1ab9491dc6dd0c79750cb3641541a3

PKG_CPE_ID:=cpe:/a:3proxy:3proxy
PKG_LICENSE:=3proxy Apache-2.0 GPL-2.0-or-later LGPL-2.1-or-later
PKG_LICENSE_FILES:=copying
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/3proxy/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=tiny free proxy server
  URL:=https://3proxy.ru/
endef

define Package/3proxy
  $(call Package/3proxy/Default)
endef

define Package/3proxy/description
  3Proxy tiny free proxy server is really tiny cross-platform (Win32/Win64&Unix)
  freeware proxy servers set. It includes HTTP proxy with HTTPS and FTP support,
  SOCKSv4/SOCKSv4.5/SOCKSv5 proxy (socks/socks.exe), POP3 proxy, SMTP proxy,
  AIM/ICQ proxy (icqpr/icqpr.exe), MSN messenger / Live messenger proxy
  (msnpr/msnpr.exe), FTP proxy, caching DNS proxy, TCP and UDP portmappers.

  You can use every proxy as a standalone program (socks, proxy, tcppm, udppm,
  pop3p) or use combined program (3proxy). Combined proxy additionally supports
  features like access control, bandwidth limiting, limiting daily/weekly/monthly
  traffic amount, proxy chaining, log rotation, syslog and ODBC logging, etc.

  It's created to be small, simple and yet very functional.
endef

define Package/3proxy/conffiles
/etc/3proxy/
/etc/config/3proxy
endef

define Package/3proxy/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/3proxy $(1)/usr/bin/3proxy
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/3proxy.config $(1)/etc/config/3proxy
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/3proxy.init $(1)/etc/init.d/3proxy
endef

# 1: library name
# 2: library path
# 3: library dependencies
# 4: library description
define 3proxyLibrary
  3proxyLibs+= $(1)
  PKG_CONFIG_DEPENDS+= CONFIG_PACKAGE_3proxy-lib-$(1)

  define Package/3proxy-lib-$(1)
    $(call Package/3proxy/Default)
    TITLE+= - $(1) library
    DEPENDS+= 3proxy $(3)
  endef

  define Package/3proxy-lib-$(1)/description
    3Proxy shared library - $(1).
    $(4)
  endef

  define Package/3proxy-lib-$(1)/install
	$(INSTALL_DIR) $$(1)/usr/libexec/3proxy
	$(CP) $(PKG_BUILD_DIR)/bin/$(2).ld.so $$(1)/usr/libexec/3proxy/
  endef
endef
$(eval $(call 3proxyLibrary,pam,pamauth,+libpam,))
$(eval $(call 3proxyLibrary,pcre,PCREPlugin,,This filtering plugin can be used to create matching and replace rules with regular expressions for client's request, client and servers header and client and server data.))
$(eval $(call 3proxyLibrary,ssl,SSLPlugin,+libopenssl,This plugin can be used to decrypt and manupulate SSL/TLS traffic.))
$(eval $(call 3proxyLibrary,strings,StringsPlugin,,Allows to change replies of HTTP proxy server.))
$(eval $(call 3proxyLibrary,traffic,TrafficPlugin,,This plugin attempts to correct 3proxy computations to approximate network or link level traffic by using either fixed coefficients by port number or attempting to predict number and sizes of network packets.))
$(eval $(call 3proxyLibrary,transparent,TransparentPlugin,,This plugin can be used to implement 3proxy transparently for client for any TCP-based protocols.))

# 1: module name
# 2: module dependencies
define 3proxyModule
  3proxyMods+= $(1)
  PKG_CONFIG_DEPENDS+= CONFIG_PACKAGE_3proxy-mod-$(1)

  define Package/3proxy-mod-$(1)
    $(call Package/3proxy/Default)
    TITLE+= - $(1) standalone module
    DEPENDS+= $(2)
  endef

  define Package/3proxy-mod-$(1)/description
    3Proxy standalone module - $(1).
    This module can be used as a standalone program.
  endef

  define Package/3proxy-mod-$(1)/install
	$(INSTALL_DIR) $$(1)/usr/libexec/3proxy
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/$(1) $$(1)/usr/libexec/3proxy/
  endef
endef
$(eval $(call 3proxyModule,ftppr,))
$(eval $(call 3proxyModule,mycrypt,))
$(eval $(call 3proxyModule,pop3p,))
$(eval $(call 3proxyModule,proxy,))
$(eval $(call 3proxyModule,smtpp,))
$(eval $(call 3proxyModule,socks,))
$(eval $(call 3proxyModule,tcppm,))
$(eval $(call 3proxyModule,tlspr,))
$(eval $(call 3proxyModule,udppm,))

MAKE_FLAGS += \
	PLUGINS="$(strip \
		$(if $(CONFIG_PACKAGE_3proxy-lib-pam),PamAuth) \
		$(if $(CONFIG_PACKAGE_3proxy-lib-pcre),PCREPlugin) \
		$(if $(CONFIG_PACKAGE_3proxy-lib-ssl),SSLPlugin) \
		$(if $(CONFIG_PACKAGE_3proxy-lib-strings),StringsPlugin) \
		$(if $(CONFIG_PACKAGE_3proxy-lib-traffic),TrafficPlugin) \
		$(if $(CONFIG_PACKAGE_3proxy-lib-transparent),TransparentPlugin))" \
	-f Makefile.Linux

$(foreach lib,$(3proxyLibs),$(eval $(call BuildPackage,3proxy-lib-$(lib))))
$(foreach mod,$(3proxyMods),$(eval $(call BuildPackage,3proxy-mod-$(mod))))
$(eval $(call BuildPackage,3proxy))
