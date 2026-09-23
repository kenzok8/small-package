include $(TOPDIR)/rules.mk

PKG_NAME:=kai-agent
PKG_VERSION:=0.0.23
PKG_RELEASE:=2
PKG_SOURCE:=kai-agent-bundle-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/kai-runtime-v$(PKG_VERSION)/
PKG_HASH:=8c1af22149f9b3d1fa2c38bab016d2b046319ece8b1c84b8b5f5a0190aeacf52
PKG_BUILD_DIR:=$(BUILD_DIR)/kai-agent-bundle-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	TITLE:=KAI OpenCode Agent bundle
	URL:=https://github.com/linkease/linkease-skills
endef

define Package/$(PKG_NAME)/description
  Versioned local OpenCode instructions and skills for KAI on iStoreOS.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/kai/agent-bundles/$(PKG_VERSION)
	$(CP) $(PKG_BUILD_DIR)/agents $(1)/usr/share/kai/agent-bundles/$(PKG_VERSION)/
	$(CP) $(PKG_BUILD_DIR)/skills $(1)/usr/share/kai/agent-bundles/$(PKG_VERSION)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/home-prompts.json $(1)/usr/share/kai/agent-bundles/$(PKG_VERSION)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/manifest.json $(1)/usr/share/kai/agent-bundles/$(PKG_VERSION)/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/opencode.json $(1)/usr/share/kai/agent-bundles/$(PKG_VERSION)/
	$(LN) agent-bundles/$(PKG_VERSION) $(1)/usr/share/kai/agent
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
