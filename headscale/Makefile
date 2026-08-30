#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=headscale
PKG_VERSION:=0.29.3
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/juanfont/headscale/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=9c2b6020b51a1d53641fe8e282fd849b4d00eca8945fef93d63454655a90ba0d

PKG_LICENSE:=BSD-3-clause
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/juanfont/headscale
GO_PKG_BUILD_PKG:=$(GO_PKG)/cmd/headscale
GO_PKG_LDFLAGS:=-s -w
GO_PKG_LDFLAGS+= \
	-X '$(GO_PKG)/hscontrol/types.version=v$(PKG_VERSION)'

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/headscale
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=A Tailscale control server
  URL:=https://github.com/juanfont/headscale
  DEPENDS:=$(GO_ARCH_DEPENDS)
endef

define Package/headscale/description
An open source, self-hosted implementation of the Tailscale control server.
endef

define Package/headscale/conffiles
/etc/headscale/config.yaml
/etc/headscale/db.sqlite
/etc/headscale/derp.yaml
/etc/headscale/noise_private.key
/etc/headscale/derp_server_private.key
endef

define Package/headscale/install
	$(call GoPackage/Package/Install/Bin,$(1))

	$(INSTALL_DIR) $(1)/etc/headscale
	touch $(1)/etc/headscale/db.sqlite
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/config-example.yaml $(1)/etc/headscale/config.yaml
	$(SED) 's#/var/lib/headscale#/etc/headscale#g' $(1)/etc/headscale/config.yaml
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/derp-example.yaml $(1)/etc/headscale/derp.yaml
endef

$(eval $(call GoBinPackage,headscale))
$(eval $(call BuildPackage,headscale))
