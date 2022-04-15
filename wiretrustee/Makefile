include $(TOPDIR)/rules.mk

PKG_NAME:=wiretrustee
PKG_VERSION:=0.5.1
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/wiretrustee/wiretrustee/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=4aa10123356aa1a89774fa571096fd594221ff8a236579b21035302bc1a24dc0

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/wiretrustee/wiretrustee
GO_PKG_BUILD_PKG:=github.com/wiretrustee/wiretrustee/client/...
GO_PKG_LDFLAGS:=-s -w
GO_PKG_LDFLAGS_X:=main.Version=v$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/wiretrustee
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=Connect your devices into a single secure private WireGuard®-based mesh network
  URL:=https://github.com/wiretrustee/wiretrustee
  DEPENDS:=$(GO_ARCH_DEPENDS)
endef

define Package/wiretrustee/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))

	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/client $(1)/usr/bin/wiretrustee

	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) $(CURDIR)/files/wiretrustee.init $(1)/etc/init.d/wiretrustee
endef

$(eval $(call GoBinPackage,wiretrustee))
$(eval $(call BuildPackage,wiretrustee))
