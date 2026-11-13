#
# Copyright (C) 2026 Quickstart NetPolicy Contributors
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=quickstart-netpolicy
PKG_VERSION:=0.2.1-rc20261113
PKG_RELEASE:=1
NETPOLICY_TARGET_x86_64:=x86_64-unknown-linux-musl
NETPOLICY_TARGET_aarch64:=aarch64-unknown-linux-musl
NETPOLICY_TARGET:=$(NETPOLICY_TARGET_$(ARCH))
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(NETPOLICY_TARGET).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/quickstart-runtime-v0.17.1-rc20261028/
PKG_HASH_x86_64:=39861c6d508a900d691315b6443f274ea1e283bc3f8c9f9fa91b4e992814a372
PKG_HASH_aarch64:=ef2dd2c67ce02b945e89c9fbff66650586fb1c1410717b9306e583c4ad53e480
PKG_HASH:=$(PKG_HASH_$(ARCH))
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

ifeq ($(CONFIG_USE_APK),y)
PKG_VERSION:=$(subst -rc,_rc,$(PKG_VERSION))
endif

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

# The packaged ELF must match binarySha256 in the runtime manifest.
RSTRIP:=:

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=Quickstart native network policy engine
	URL:=https://github.com/istoreos/quickstart-netpolicy
	DEPENDS:=@(x86_64||aarch64) +ca-bundle
endef

define Package/$(PKG_NAME)/description
  Independent eBPF network-policy engine for Quickstart device rate limits.
  It uses its own binary, port, data files and kernel maps and does not replace Bandix.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/quickstart-netpolicy
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	gzip -dc $(DL_DIR)/$(PKG_SOURCE) | tar -C $(PKG_BUILD_DIR) -xf -
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d $(1)/etc/config $(1)/usr/share/quickstart-netpolicy
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/payload/quickstart-netpolicy $(1)/usr/bin/quickstart-netpolicy
	$(INSTALL_BIN) ./files/quickstart-netpolicy.init $(1)/etc/init.d/quickstart-netpolicy
	$(INSTALL_CONF) ./files/quickstart-netpolicy.config $(1)/etc/config/quickstart-netpolicy
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/manifest.json $(1)/usr/share/quickstart-netpolicy/manifest.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/payload/LICENSE $(1)/usr/share/quickstart-netpolicy/LICENSE
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/payload/NOTICE $(1)/usr/share/quickstart-netpolicy/NOTICE
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
