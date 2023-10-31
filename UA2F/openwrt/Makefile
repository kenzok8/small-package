include $(TOPDIR)/rules.mk

PKG_NAME:=UA2F
PKG_VERSION:=4.4.1
PKG_RELEASE:=1

PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILE:=LICENSE

PKG_BUILD_DIR:=$(CURDIR)/..
CMAKE_BINARY_SUBDIR:=build

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ua2f
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=Change User-Agent to Fwords on the fly.
  URL:=https://github.com/Zxilly/UA2F
  DEPENDS:= \
    +libnetfilter-conntrack \
    +libnetfilter-queue \
    +libpthread \
    +libuci \
    +USE_GLIBC:libasan \
    +(PACKAGE_nftables-json||PACKAGE_nftables-nojson):kmod-nft-queue \
    +PACKAGE_firewall:iptables-mod-conntrack-extra \
    +PACKAGE_firewall:iptables-mod-filter \
    +PACKAGE_firewall:iptables-mod-nfqueue
endef

define Package/ua2f/config
  config UA2F_CUSTOM_USER_AGENT
    bool "Enable custom User-Agent"
    depends on PACKAGE_ua2f
    default n
    help
      Enable this option to use a custom User-Agent string.

  config UA2F_USER_AGENT_STRING
    string "Custom User-Agent string"
    depends on UA2F_CUSTOM_USER_AGENT
    default "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.68"
    help
      Specify the custom User-Agent string to use when UA2F_CUSTOM_USER_AGENT is enabled.
endef

CMAKE_OPTIONS += \
	-DUA2F_VERSION_STR="$(PKG_VERSION)" \
	-DUA2F_CUSTOM_USER_AGENT=$(if $(CONFIG_UA2F_CUSTOM_USER_AGENT),ON,OFF) \
	-DUA2F_USER_AGENT_STRING=$(CONFIG_UA2F_USER_AGENT_STRING) \

define Package/ua2f/description
  Change User-agent to Fwords to prevent being checked by Dr.Com.
endef

define Package/ua2f/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ua2f $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/ua2f.config $(1)/etc/config/ua2f
	$(INSTALL_BIN) ./files/ua2f.init $(1)/etc/init.d/ua2f
	$(INSTALL_BIN) ./files/ua2f.uci $(1)/etc/uci-defaults/80-ua2f
endef

define Package/ua2f/postinst
#!/bin/sh

# check if we are on real system
[ -n "$${IPKG_INSTROOT}" ] || {
	(. /etc/uci-defaults/80-ua2f) && rm -f /etc/uci-defaults/80-ua2f
	exit 0
}
endef

$(eval $(call BuildPackage,ua2f))
