#
# Copyright (C) 2026 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

AGENTFLOW_ARCH_x86_64:=amd64
AGENTFLOW_ARCH_aarch64:=arm64
AGENTFLOW_ARCH:=$(AGENTFLOW_ARCH_$(ARCH))

AGENTFLOW_HASH_x86_64:=996ccb6580043a187e83a3558c6bb2f0ff503bafbe46b7c995cff7f77629c088
AGENTFLOW_HASH_aarch64:=6d733ebc49b095bf8670a1b655a13bb8ad98c90ced19701b67d5cdd4fe9a3db4

PKG_NAME:=agentflow
PKG_VERSION:=0.3.0
PKG_RELEASE:=2

AGENTFLOW_URL_FILE:=agentflow-linux-$(AGENTFLOW_ARCH)
AGENTFLOW_DOWNLOAD:=$(AGENTFLOW_URL_FILE)-$(AGENTFLOW_HASH_$(ARCH))
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
STRIP:=true
RSTRIP:=:

include $(INCLUDE_DIR)/package.mk

define Download/agentflow
	URL:=https://fw.koolcenter.com/binary/geili/agentflow/build/
	URL_FILE:=$(AGENTFLOW_URL_FILE)
	FILE:=$(AGENTFLOW_DOWNLOAD)
	HASH:=$(AGENTFLOW_HASH_$(ARCH))
endef

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=AgentFlow
	DEPENDS:=@(x86_64||aarch64) +git +git-http +mise
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
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/agentflow $(1)/usr/sbin/agentflow
	$(INSTALL_BIN) ./files/agentflow.init $(1)/etc/init.d/agentflow
	$(INSTALL_BIN) ./files/agentflow.uci-default $(1)/etc/uci-defaults/09-agentflow
	$(INSTALL_CONF) ./files/agentflow.config $(1)/etc/config/agentflow
endef

$(eval $(call Download,agentflow))
$(eval $(call BuildPackage,$(PKG_NAME)))
