#
# Copyright (C) 2026 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

AGENTFLOW_ARCH_x86_64:=amd64
AGENTFLOW_ARCH_aarch64:=arm64
AGENTFLOW_ARCH:=$(AGENTFLOW_ARCH_$(ARCH))

AGENTFLOW_HASH_x86_64:=b02c1211f3c7f288b0b25ad187ba1e74989bdde744477875a553dc9f7f7501c8
AGENTFLOW_HASH_aarch64:=938b5feca2fc942eca13b0e8c9df9ea6e7d45c0b0adba0b61f6a3da5bc2ad8d8

PKG_NAME:=agentflow
PKG_VERSION:=0.3.0
PKG_RELEASE:=1

AGENTFLOW_DOWNLOAD:=agentflow-linux-$(AGENTFLOW_ARCH)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
STRIP:=true
RSTRIP:=:

include $(INCLUDE_DIR)/package.mk

define Download/agentflow
	URL:=https://fw0.koolcenter.com/binary/geili/agentflow/build/
	FILE:=$(AGENTFLOW_DOWNLOAD)
	HASH:=$(AGENTFLOW_HASH_$(ARCH))
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=AgentFlow
	DEPENDS:=@(x86_64||aarch64) +git +mise
	URL:=https://agentflow.geili.ai/
endef

define Package/$(PKG_NAME)/description
  AgentFlow provides a Web UI for orchestrating coding agents and workflows.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/agentflow
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	$(CP) $(DL_DIR)/$(AGENTFLOW_DOWNLOAD) $(PKG_BUILD_DIR)/agentflow
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/agentflow $(1)/usr/bin/agentflow
	$(INSTALL_BIN) ./files/agentflow.init $(1)/etc/init.d/agentflow
	$(INSTALL_BIN) ./files/agentflow.uci-default $(1)/etc/uci-defaults/09-agentflow
	$(INSTALL_CONF) ./files/agentflow.config $(1)/etc/config/agentflow
endef

$(eval $(call Download,agentflow))
$(eval $(call BuildPackage,$(PKG_NAME)))
