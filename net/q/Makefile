include $(TOPDIR)/rules.mk

PKG_NAME:=q
PKG_VERSION:=0.19.9
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/natesales/q/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=18a68f067daccce97f2a7e4ce4c72e206eba03a1c57040f8c7488f100040d2fc

PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Milinda Brantini <C_A_T_T_E_R_Y@outlook.com>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/natesales/q
GO_PKG_LDFLAGS_X:= main.version=$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/q
  SECTION:=net
  CATEGORY:=Network
  TITLE:=A tiny command line DNS client.
  URL:=https://github.com/natesales/q
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle
endef

define Package/q/description
  A tiny command line DNS client with support for UDP, TCP, DoT, DoH, DoQ and ODoH.
endef

$(eval $(call GoBinPackage,q))
$(eval $(call BuildPackage,q))
