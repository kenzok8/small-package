include $(TOPDIR)/rules.mk

PKG_NAME:=ddns-scripts-dnspod
PKG_VERSION:=1.0.3
PKG_RELEASE:=8

PKG_LICENSE:=GPLv2
PKG_MAINTAINER:=Small_5

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=DDNS extension for Dnspod.com/Dnspod.cn
	PKGARCH:=all
	DEPENDS:=+ddns-scripts +curl +jsonfilter
endef

define Package/$(PKG_NAME)/description
	Dynamic DNS Client scripts extension for Dnspod.com/Dnspod.cn
endef

define Build/Configure
endef

define Build/Compile
	$(CP) ./*.sh $(PKG_BUILD_DIR)
	# remove comments, white spaces and empty lines
	for FILE in `find $(PKG_BUILD_DIR) -type f`; do \
		$(SED) 's/^[[:space:]]*//' \
		-e '/^#[[:space:]]\|^#$$$$/d' \
		-e 's/[[:space:]]#[[:space:]].*$$$$//' \
		-e 's/[[:space:]]*$$$$//' \
		-e '/^\/\/[[:space:]]/d'	\
		-e '/^[[:space:]]*$$$$/d'	$$$$FILE; \
	done
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/ddns
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/*.sh $(1)/usr/lib/ddns
	$(INSTALL_DIR) $(1)/usr/share/ddns/default
	$(INSTALL_DATA) ./*.json $(1)/usr/share/ddns/default
endef

define Package/$(PKG_NAME)/prerm
	#!/bin/sh
	[ -z "$${IPKG_INSTROOT}" ] && /etc/init.d/ddns stop >/dev/null 2>&1
	exit 0 # suppress errors
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
