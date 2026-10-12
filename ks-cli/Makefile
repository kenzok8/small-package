# This is free software, licensed under the GNU General Public License v3.

include $(TOPDIR)/rules.mk

PKG_ARCH_KS_CLI:=$(ARCH)

PKG_NAME:=ks-cli
PKG_VERSION:=0.8.4
PKG_RELEASE:=1

PKG_SOURCE:=ks-cli-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/kspeeder/docker_kspeeder/releases/download/v$(PKG_VERSION)/
PKG_HASH:=3393b7d6982ac7f10937abefa4d598cf009cf298c74d70a919287d49015c01e8

PKG_BUILD_DIR:=$(BUILD_DIR)/ks-cli-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=KSpeeder command-line client
	DEPENDS:=@(arm||x86_64||aarch64)
	URL:=https://www.kspeeder.com/
endef

define Package/$(PKG_NAME)/description
  Command-line client for KSpeeder downloads, diagnostics and service control.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ks-cli.$(PKG_ARCH_KS_CLI) $(1)/usr/bin/ks-cli
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
