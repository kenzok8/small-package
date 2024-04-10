include $(TOPDIR)/rules.mk

PKG_NAME:=ngrokc
PKG_VERSION:=1.55
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/dosgo/ngrok-c.git
PKG_SOURCE_DATE:=2021-09-01
PKG_SOURCE_VERSION:=5da550284ed5bec7fa843c574e52b840e918fa4c
PKG_MIRROR_HASH:=f3893717333f810fb54253b1b399ac6d0eabe5c1e7f5e30fe53cdb8eecd28faf

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/ngrokc
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Secure tunnels to localhost (C++ port)
  URL:=https://github.com/dosgo/ngrok-c
  DEPENDS:=+libc +libpthread +libopenssl +libstdcpp +zlib \
    +USE_GLIBC:libatomic
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	$(CP) $(PKG_BUILD_DIR)/Makefile.openssl $(PKG_BUILD_DIR)/Makefile
endef

define Package/ngrokc/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ngrokc $(1)/usr/bin
endef

$(eval $(call BuildPackage,ngrokc))
