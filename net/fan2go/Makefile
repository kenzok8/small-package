include $(TOPDIR)/rules.mk

PKG_NAME:=fan2go
PKG_VERSION:=0.11.1
PKG_RELEASE:=2

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/markusressel/fan2go/tar.gz/$(PKG_VERSION)?
PKG_HASH:=02baca96ed1be6824e9bf6ca33198f94cc9319af44e04677a7f9c55c60abb319

PKG_LICENSE:=AGPL-3.0
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Dee.H.Y <dongfengweixiao@hotmail.com>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/markusressel/fan2go
GO_PKG_LDFLAGS_X:=$(GO_PKG)/cmd/global.Version=$(PKG_VERSION)
GO_PKG_TAGS:=netgo,disable_nvml

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/fan2go
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=dynamic fan speed control
  URL:=https://github.com/markusressel/fan2go
  DEPENDS:=$(GO_ARCH_DEPENDS) +libsensors
endef

define Package/fan2go/description
  A simple daemon providing dynamic fan speed control based on
  temperature sensors.
endef

define Package/fan2go/conffiles
/etc/fan2go/fan2go.db
/etc/fan2go/fan2go.yaml
endef

define Package/fan2go/install
	$(call GoPackage/Package/Install/Bin,$(1))

	$(INSTALL_DIR) $(1)/etc/fan2go
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/fan2go.yaml $(1)/etc/fan2go/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/fan2go.init $(1)/etc/init.d/fan2go
endef

define Package/fan2go/postinst
#!/bin/sh
touch "$${IPKG_INSTROOT}/etc/sensors3.conf"
exit 0
endef

define Package/fan2go/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -s "/etc/sensors3.conf" ] || rm -f "/etc/sensors3.conf"
fi
exit 0
endef

$(eval $(call GoBinPackage,fan2go))
$(eval $(call BuildPackage,fan2go))
