# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NPM_NAME:=pnpm
PKG_NAME:=node-$(PKG_NPM_NAME)
PKG_VERSION:=10.17.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NPM_NAME)-$(PKG_VERSION).tgz
PKG_SOURCE_URL:=https://mirrors.tencent.com/npm/$(PKG_NPM_NAME)/-/ \
                https://registry.npmjs.org/$(PKG_NPM_NAME)/-/
PKG_HASH:=bd9ec5417641391e0acb3912b2912bd5b0385407a82da94744a7407b567fdb4f

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

HOST_BUILD_DEPENDS:=node/host
HOST_BUILD_PARALLEL:=1

PKG_BUILD_DEPENDS:=node/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

define Package/node-pnpm
  SUBMENU:=Node.js
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Fast, disk space efficient package manager
  URL:=https://pnpm.io/
  DEPENDS:=+node
endef

define Package/node-pnpm/description
 Fast, disk space efficient package manager
endef

TAR_OPTIONS+= --strip-components 1
TAR_CMD=$(HOST_TAR) -C $(1) $(TAR_OPTIONS)

NODEJS_CPU:=$(subst powerpc,ppc,$(subst aarch64,arm64,$(subst x86_64,x64,$(subst i386,ia32,$(ARCH)))))
TMPNPM:=$(shell mktemp -u XXXXXXXXXX)
HOSTTMPNPM:=$(shell mktemp -u XXXXXXXXXX)
NPM_CACHE_DIR:=$(if $(call qstrip,$(CONFIG_NODEJS_NPM_CACHE_DIR)),$(call qstrip,$(CONFIG_NODEJS_NPM_CACHE_DIR)),$(TMP_DIR))

TARGET_CFLAGS+=$(FPIC)
TARGET_CPPFLAGS+=$(FPIC)

define Build/Compile
	cd $(PKG_BUILD_DIR); \
	$(MAKE_VARS) \
	$(MAKE_FLAGS) \
	npm_config_nodedir=$(STAGING_DIR)/usr/ \
	$(if $(CONFIG_NODEJS_NPM_KEEP_CACHE), npm_config_cache=$(NPM_CACHE_DIR)/npm-cache-$(PKG_NPM_NAME),npm_config_cache=$(TMP_DIR)/npm-cache-$(TMPNPM)) \
	npm install --prefer-offline --no-audit --global-style --install-strategy=shallow --no-save --omit=dev --no-package-lock
	rm -rf $(TMP_DIR)/npm-cache-$(TMPNPM)
	rm -f $(PKG_BUILD_DIR)/node_modules/.package-lock.json
	find $(PKG_BUILD_DIR)/node_modules -type d -empty -print0 | xargs -0 -r rmdir || true
endef

define Package/node-pnpm/install
	$(INSTALL_DIR) $(1)/usr/lib/node/$(PKG_NPM_NAME)
	$(CP) $(PKG_BUILD_DIR)/{package.json,LICENSE} \
		$(1)/usr/lib/node/$(PKG_NPM_NAME)/
	$(CP) $(PKG_BUILD_DIR)/README.md \
		$(1)/usr/lib/node/$(PKG_NPM_NAME)/
	$(CP) $(PKG_BUILD_DIR)/bin \
		$(1)/usr/lib/node/$(PKG_NPM_NAME)/
	$(INSTALL_DIR) $(1)/usr/lib/node/$(PKG_NPM_NAME)/dist
	$(CP) $(PKG_BUILD_DIR)/dist/{pnpm.cjs,worker.js} \
		$(1)/usr/lib/node/$(PKG_NPM_NAME)/dist/
	$(INSTALL_DIR) $(1)/usr/bin
	$(LN) ../lib/node/$(PKG_NPM_NAME)/bin/pnpm.cjs $(1)/usr/bin/pnpm
	$(LN) ../lib/node/$(PKG_NPM_NAME)/bin/pnpx.cjs $(1)/usr/bin/pnpx
	$(INSTALL_DIR) $(1)/usr/lib/node_modules
	$(LN) ../node/$(PKG_NPM_NAME) $(1)/usr/lib/node_modules/$(PKG_NPM_NAME)
endef

define Package/node-pnpm/postrm
#!/bin/sh
rm /usr/lib/node_modules/pnpm || true
rm -rf /usr/lib/node/pnpm || true
endef

define Host/Compile
	cd $(HOST_BUILD_DIR); \
	$(HOST_MAKE_VARS) \
	npm_config_nodedir=$(STAGING_DIR)/usr/ \
	$(if $(CONFIG_NODEJS_NPM_KEEP_CACHE), npm_config_cache=$(NPM_CACHE_DIR)/host-npm-cache-$(PKG_NPM_NAME),npm_config_cache=$(TMP_DIR)/npm-cache-$(HOSTTMPNPM)) \
	npm install --prefer-offline --no-audit --global-style --install-strategy=shallow --no-save --omit=dev --no-package-lock
	rm -rf $(TMP_DIR)/npm-cache-$(HOSTTMPNPM)
	rm -f $(HOST_BUILD_DIR)/node_modules/.package-lock.json
	find $(HOST_BUILD_DIR)/node_modules -type d -empty -print0 | xargs -0 -r rmdir || true
endef

define Host/Install
	$(INSTALL_DIR) $(1)/lib/node_modules/$(PKG_NPM_NAME)
	$(CP) $(HOST_BUILD_DIR)/{package.json,LICENSE} \
		$(1)/lib/node_modules/$(PKG_NPM_NAME)/
	$(CP) $(HOST_BUILD_DIR)/README.md \
		$(1)/lib/node_modules/$(PKG_NPM_NAME)/
	$(CP) $(HOST_BUILD_DIR)/bin \
		$(1)/lib/node_modules/$(PKG_NPM_NAME)/
	$(INSTALL_DIR) $(1)/lib/node_modules/$(PKG_NPM_NAME)/dist
	$(CP) $(HOST_BUILD_DIR)/dist/{pnpm.cjs,worker.js} \
		$(1)/lib/node_modules/$(PKG_NPM_NAME)/dist/
	$(INSTALL_DIR) $(1)/bin
	$(LN) ../lib/node_modules/$(PKG_NPM_NAME)/bin/pnpm.cjs $(1)/bin/pnpm
	$(LN) ../lib/node_modules/$(PKG_NPM_NAME)/bin/pnpx.cjs $(1)/bin/pnpx
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,node-pnpm))
