#
# Copyright (C) 2026 iStoreOS
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=linkeasefull-web
PKG_VERSION:=0.1.37
PKG_RELEASE:=1

LINKEASE_WEB_VARIANT:=nas-full
LINKEASE_WEB_SOURCE_PATH:=web/v1/core/$(PKG_NAME)/$(PKG_VERSION)/$(LINKEASE_WEB_VARIANT)
LINKEASE_WEB_SOURCE_URLS:= \
	https://github.com/istoreos/istoreos-app-hub/releases/download/linkeasefull-web-v$(PKG_VERSION) \
	https://fw.linkease.com/binary/LinkEase/$(LINKEASE_WEB_SOURCE_PATH) \
	https://dl.istoreos.com/binary/LinkEase/$(LINKEASE_WEB_SOURCE_PATH) \
	https://fw.d4ctech.com/binary/LinkEase/$(LINKEASE_WEB_SOURCE_PATH) \
	https://fw20.koolcenter.com/binary/LinkEase/$(LINKEASE_WEB_SOURCE_PATH) \
	https://fw.koolcenter.com/binary/LinkEase/$(LINKEASE_WEB_SOURCE_PATH)

LINKEASE_WEB_ARCHIVE_DOWNLOAD:=$(PKG_NAME)-$(PKG_VERSION)-$(LINKEASE_WEB_VARIANT)-desktop-shell.web.zip
LINKEASE_WEB_RELEASE_SET_DOWNLOAD:=$(PKG_NAME)-$(PKG_VERSION)-$(LINKEASE_WEB_VARIANT)-release-set.json
LINKEASE_WEB_PACKAGE_DOWNLOAD:=$(PKG_NAME)-$(PKG_VERSION)-$(LINKEASE_WEB_VARIANT)-package.json
LINKEASE_NAS_ARCHIVE_DOWNLOAD:=$(PKG_NAME)-$(PKG_VERSION)-$(LINKEASE_WEB_VARIANT)-linkease-nas-web.zip
LINKEASE_NAS_REGISTRATION_DOWNLOAD:=$(PKG_NAME)-$(PKG_VERSION)-$(LINKEASE_WEB_VARIANT)-device-binding.json
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-$(LINKEASE_WEB_VARIANT)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
RSTRIP:=:

include $(INCLUDE_DIR)/package.mk

define Download/linkeasefull-web-archive
	URL:=$(LINKEASE_WEB_SOURCE_URLS)
	URL_FILE:=desktop-shell.web.zip
	FILE:=$(LINKEASE_WEB_ARCHIVE_DOWNLOAD)
	HASH:=455d2c5165ffcd6a9e3d6b0cf6cf7f59d3526d8b86fc2abb945e83358e492ae4
endef

define Download/linkeasefull-nas-archive
	URL:=$(LINKEASE_WEB_SOURCE_URLS)
	URL_FILE:=linkease-nas-web.zip
	FILE:=$(LINKEASE_NAS_ARCHIVE_DOWNLOAD)
	HASH:=b25737855e8014f2c90ee4af586b77d2091f21ec600438729f0cb3aeaffbbd3a
endef

define Download/linkeasefull-nas-registration
	URL:=$(LINKEASE_WEB_SOURCE_URLS)
	URL_FILE:=device-binding.json
	FILE:=$(LINKEASE_NAS_REGISTRATION_DOWNLOAD)
	HASH:=2afdedd24ceca57ff3dbc08b31e1fd1a6963370d84bd498b5ed92ed79948eaff
endef

define Download/linkeasefull-web-release-set
	URL:=$(LINKEASE_WEB_SOURCE_URLS)
	URL_FILE:=release-set.json
	FILE:=$(LINKEASE_WEB_RELEASE_SET_DOWNLOAD)
	HASH:=8af578e5899e7c06f7af3cd85b451ddba9ee2ebd7d8e73b34e72ae987c7b9847
endef

define Download/linkeasefull-web-package
	URL:=$(LINKEASE_WEB_SOURCE_URLS)
	URL_FILE:=package.json
	FILE:=$(LINKEASE_WEB_PACKAGE_DOWNLOAD)
	HASH:=d57b73cb0019fe47d3c49910b9ec644a0b88d0390b5b5aead2446be32921f976
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=LinkEase Full core Web desktop
	DEPENDS:=@(x86_64||aarch64)
	PKGARCH:=all
	URL:=https://www.linkease.com/
endef

define Package/$(PKG_NAME)/description
  Architecture-independent offline desktop and independent LinkEase NAS UI.
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
set -eu
root="$${IPKG_INSTROOT:-}"
base="$${root}/usr/share/linkeasefull/web-core"
target="$(PKG_VERSION)/$(LINKEASE_WEB_VARIANT)"
current="$${base}/current"
temporary="$${base}/.current.$$$$"
test -s "$${base}/$${target}/release-set.json"
test -s "$${base}/$${target}/linkease-nas-web.zip"
test -s "$${base}/$${target}/device-binding.json"
rm -f "$${temporary}"
ln -s "$${target}" "$${temporary}"
mv -fT "$${temporary}" "$${current}"
legacy="$${root}/usr/share/linkeasefull/desktop-apps.d/device-binding.json"
if [ ! -e "$${legacy}" ] && [ ! -L "$${legacy}" ]; then
	mkdir -p "$$(dirname "$${legacy}")"
	ln -s /usr/share/linkeasefull/web-core/current/device-binding.json "$${legacy}"
fi
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
root="$${IPKG_INSTROOT:-}"
current="$${root}/usr/share/linkeasefull/web-core/current"
owned=0
if [ "$$(readlink "$${current}" 2>/dev/null)" = "$(PKG_VERSION)/$(LINKEASE_WEB_VARIANT)" ]; then
	owned=1
	rm -f "$${current}"
fi
legacy="$${root}/usr/share/linkeasefull/desktop-apps.d/device-binding.json"
if [ "$${owned}" = 1 ] && [ "$$(readlink "$${legacy}" 2>/dev/null)" = /usr/share/linkeasefull/web-core/current/device-binding.json ]; then
	rm -f "$${legacy}"
fi
exit 0
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(CP) $(DL_DIR)/$(LINKEASE_WEB_ARCHIVE_DOWNLOAD) $(PKG_BUILD_DIR)/desktop-shell.web.zip
	$(CP) $(DL_DIR)/$(LINKEASE_WEB_RELEASE_SET_DOWNLOAD) $(PKG_BUILD_DIR)/release-set.json
	$(CP) $(DL_DIR)/$(LINKEASE_WEB_PACKAGE_DOWNLOAD) $(PKG_BUILD_DIR)/package.json
	$(CP) $(DL_DIR)/$(LINKEASE_NAS_ARCHIVE_DOWNLOAD) $(PKG_BUILD_DIR)/linkease-nas-web.zip
	$(CP) $(DL_DIR)/$(LINKEASE_NAS_REGISTRATION_DOWNLOAD) $(PKG_BUILD_DIR)/device-binding.json
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/linkeasefull/web-core/$(PKG_VERSION)/$(LINKEASE_WEB_VARIANT) $(1)/usr/share/linkease/apps.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/desktop-shell.web.zip $(1)/usr/share/linkeasefull/web-core/$(PKG_VERSION)/$(LINKEASE_WEB_VARIANT)/desktop-shell.web.zip
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/release-set.json $(1)/usr/share/linkeasefull/web-core/$(PKG_VERSION)/$(LINKEASE_WEB_VARIANT)/release-set.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/package.json $(1)/usr/share/linkeasefull/web-core/$(PKG_VERSION)/$(LINKEASE_WEB_VARIANT)/package.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/linkease-nas-web.zip $(1)/usr/share/linkeasefull/web-core/$(PKG_VERSION)/$(LINKEASE_WEB_VARIANT)/linkease-nas-web.zip
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/device-binding.json $(1)/usr/share/linkeasefull/web-core/$(PKG_VERSION)/$(LINKEASE_WEB_VARIANT)/device-binding.json
	ln -sf /usr/share/linkeasefull/web-core/current/device-binding.json $(1)/usr/share/linkease/apps.d/device-binding.json
endef

$(eval $(call Download,linkeasefull-web-archive))
$(eval $(call Download,linkeasefull-web-release-set))
$(eval $(call Download,linkeasefull-web-package))
$(eval $(call Download,linkeasefull-nas-archive))
$(eval $(call Download,linkeasefull-nas-registration))
$(eval $(call BuildPackage,$(PKG_NAME)))
