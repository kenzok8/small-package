include $(TOPDIR)/rules.mk

PKG_NAME:=sub-web
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/cmliu/SUBWEB.git
PKG_SOURCE_DATE:=2025-02-09
PKG_SOURCE_VERSION:=39932f552c116477c87241f228d3c3b7eb4e45fb
PKG_MIRROR_HASH:=skip

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=node/host

include $(INCLUDE_DIR)/package.mk

define Package/sub-web
  SECTION:=net
  CATEGORY:=Network
  URL:=https://github.com/cmliu/SUBWEB
  TITLE:=A WebUI for generating proxy subscription url
  DEPENDS:=+subconverter
  PKGARCH:=all
endef

define Package/sub-web/description
  A WebUI for generating proxy subscription url.
endef

define Build/Compile
	pushd "$(PKG_BUILD_DIR)"; \
	npm install && \
	npm run build
endef

define Package/sub-web/install
	$(INSTALL_DIR) $(1)/www/sub-web
	$(CP) $(PKG_BUILD_DIR)/dist/* $(1)/www/sub-web/
endef

$(eval $(call BuildPackage,sub-web))
