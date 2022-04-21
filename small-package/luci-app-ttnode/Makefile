include $(TOPDIR)/rules.mk
PKG_NAME:=luci-app-ttnode
PKG_VERSION:=0.3
PKG_RELEASE:=20210904

PKG_MAINTAINER:=jerrykuku <jerrykuku@qq.com>

LUCI_TITLE:=Luci for ttnode Automatic collection Script 
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luasocket +lua-md5 +lua-cjson +luasec

define Package/$(PKG_NAME)/conffiles
/etc/config/ttnode
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
