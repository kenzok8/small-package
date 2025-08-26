include $(TOPDIR)/rules.mk

PKG_NAME:=sub-web
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/CareyWang/sub-web.git
PKG_SOURCE_DATE:=2025-01-08
PKG_SOURCE_VERSION:=a8788c1a02e100ada38efc48ab72f390cd41d54c
PKG_MIRROR_HASH:=fe5cc55185d5bee5864a1dc40866133b273c49e19801642218daefe1b434d990

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_DEPENDS:=node/host node-yarn/host

include $(INCLUDE_DIR)/package.mk

define Package/sub-web
  SECTION:=net
  CATEGORY:=Network
  URL:=https://github.com/CareyWang/sub-web
  TITLE:=A WebUI for generating proxy subscription url
  DEPENDS:=+subconverter
  PKGARCH:=all
endef

define Package/sub-web/description
  Based on vue-cli and subconverter, for generating proxy subscription
  url automatically.
endef

define Build/Compile
	( \
		pushd "$(PKG_BUILD_DIR)"; \
		yarn install; \
		yarn build; \
		popd ; \
	)
endef

define Package/sub-web/install
	$(INSTALL_DIR) $(1)/www/sub-web
	$(CP) $(PKG_BUILD_DIR)/dist/* $(1)/www/sub-web/
endef

$(eval $(call BuildPackage,sub-web))
