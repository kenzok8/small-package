include $(TOPDIR)/rules.mk

PKG_NAME:=geoview
PKG_VERSION:=0.0.7
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/snowie2000/geoview/tar.gz/$(PKG_VERSION)?
PKG_HASH:=1099149d24b74ba6f4d4bca18aba4ffa0e29f8b3debb7f09b5972729ed11ca9c

PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=snowie2000

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/snowie2000/geoview
GO_PKG_BUILD_PKG:=github.com/snowie2000/geoview

GO_PKG_LDFLAGS:=-s -w

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define geoview/templates
  define Package/$(1)
    TITLE:=A geofile toolkit ($(1))
    URL:=https://github.com/snowie2000/geoview
    SECTION:=net
    CATEGORY:=Network
    SUBMENU:=Web Servers/Proxies
    DEPENDS:=$$(GO_ARCH_DEPENDS)
  endef

  define Package/$(1)/description
  geoview is a handy tool to extract useful information from geo* files.

  This package contains the $(1).
  endef

  define Package/$(1)/install
	$$(call GoPackage/Package/Install/Bin,$$(PKG_INSTALL_DIR))

	$$(INSTALL_DIR) $$(1)/usr/bin
	$$(INSTALL_BIN) $$(PKG_INSTALL_DIR)/usr/bin/$(1) $$(1)/usr/bin/
  endef
endef

GEOVIEW_COMPONENTS:=geoview

$(foreach component,$(GEOVIEW_COMPONENTS), \
  $(eval $(call geoview/templates,$(component))) \
  $(eval $(call GoBinPackage,$(component))) \
  $(eval $(call BuildPackage,$(component))) \
)
