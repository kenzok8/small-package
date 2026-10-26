include $(TOPDIR)/rules.mk

PKG_NAME:=kai-agent
PKG_VERSION:=0.0.28
PKG_RELEASE:=1
PKG_SOURCE:=kai-agent-bundle-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/kai-runtime-v$(PKG_VERSION)/
PKG_HASH:=49e67263c918d7f93a58a8c753642af19d98f1c144d2b5462ea4352b65612e7a
PKG_BUILD_DIR:=$(BUILD_DIR)/kai-agent-bundle-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	TITLE:=KAI OpenCode Agent bundle
	URL:=https://github.com/linkease/kai-skills
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
