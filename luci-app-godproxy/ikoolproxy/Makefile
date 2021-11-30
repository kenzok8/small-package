include $(TOPDIR)/rules.mk

PKG_NAME:=ikoolproxy
PKG_VERSION:=3.8.5
PKG_RELEASE:=$(AUTORELEASE)

include $(INCLUDE_DIR)/package.mk

define Package/ikoolproxy
  SECTION:=multimedia
  CATEGORY:=Multimedia
  DEPENDS:=@(aarch64||arm||i386||mips||mipsel||x86_64)
  TITLE:=ikoolproxy bin from koolshare
  URL:=https://github.com/houzi-/CDN
endef

define Build/Compile
endef

define Package/ikoolproxy/install
	$(INSTALL_DIR) $(1)/usr/share/koolproxy

ifeq ($(ARCH),aarch64)
	$(INSTALL_BIN) ./files/aarch64 $(1)/usr/share/koolproxy/koolproxy

else ifeq ($(ARCH),arm)
	$(INSTALL_BIN) ./files/arm $(1)/usr/share/koolproxy/koolproxy

else ifeq ($(ARCH),i386)
	$(INSTALL_BIN) ./files/i386 $(1)/usr/share/koolproxy/koolproxy

else ifeq ($(ARCH),mips)
	$(INSTALL_BIN) ./files/mips $(1)/usr/share/koolproxy/koolproxy

else ifeq ($(ARCH),mipsel)
	$(INSTALL_BIN) ./files/mipsel $(1)/usr/share/koolproxy/koolproxy

else ifeq ($(ARCH),x86_64)
	$(INSTALL_BIN) ./files/x86_64 $(1)/usr/share/koolproxy/koolproxy
endif
endef

$(eval $(call BuildPackage,ikoolproxy))
