include $(TOPDIR)/rules.mk

LUCI_TITLE:=Nginx Reverse Proxy Manager
LUCI_DEPENDS:=+nginx-ssl +acme +luci-lib-ipkg +luci-compat +curl +socat
PKG_NAME:=luci-app-nginx-proxy
PKG_VERSION:=2.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Your Name <vison.v@gmail.com>

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
    ( . /etc/uci-defaults/luci-nginx-proxy ) && rm -f /etc/uci-defaults/luci-nginx-proxy
    exit 0
}
endef

# call BuildPackage - OpenWrt buildroot signature
