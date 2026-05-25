include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-wifi-ap
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=liyinghao2009 <liyinghao2009@163.com>
URL:=https://github.com/liyinghao2009/luci-app-wifi-ac.git
LUCI_TITLE:=LuCI Support for WiFi AP
LUCI_PKGARCH:=all

# 依赖（OpenWrt官方包名，避免重复和冗余）
LUCI_DEPENDS:=+luci-base +luci +netcat +avahi-daemon +curl +wget +jq +coreutils +logrotate +iwinfo +ubus +uhttpd +uhttpd-mod-ubus +jsonfilter

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=$(LUCI_TITLE)
  DEPENDS:=$(LUCI_DEPENDS)
  PKGARCH:=$(LUCI_PKGARCH)
  CONFFILES:=/etc/config/wifi-ap
endef

define Package/$(PKG_NAME)/description
LuCI Web UI for WiFi AP集中管理，支持自动发现、远程命令、固件升级、日志、趋势采集等。
endef

define Package/$(PKG_NAME)/install
	# LuCI 控制器、模型、CBI、视图
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/wifi-ap
	$(CP) ./luasrc/controller/wifi-ap.lua $(1)/usr/lib/lua/luci/controller/
	$(CP) ./luasrc/model/cbi/wifi-ap.lua $(1)/usr/lib/lua/luci/model/cbi/
	$(CP) ./luasrc/view/wifi-ap/*.htm $(1)/usr/lib/lua/luci/view/wifi-ap/

	# 前端静态资源
	$(INSTALL_DIR) $(1)/www/luci-static/resources
	$(CP) ./htdocs/luci-static/resources/wifi-ap.js $(1)/www/luci-static/resources/
	$(CP) ./htdocs/luci-static/resources/wifi-ap.css $(1)/www/luci-static/resources/

	# 配置文件
	$(INSTALL_DIR) $(1)/etc/config
	$(CP) ./files/etc/config/wifi-ap $(1)/etc/config/ 2>/dev/null || true

	# 日志轮转
	$(INSTALL_DIR) $(1)/etc/logrotate.d
	$(CP) ./files/etc/logrotate.d/wifi-ap $(1)/etc/logrotate.d/

	# 守护进程、服务脚本
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) ./files/etc/init.d/wifi-ap $(1)/etc/init.d/
	$(CP) ./files/usr/bin/wifi-ap $(1)/usr/bin/
	$(CP) ./files/usr/sbin/ap-set-bridge-ip.sh $(1)/usr/sbin/
	$(CP) ./files/usr/sbin/wifi-ap-firmware-upload.sh $(1)/usr/sbin/
	$(CP) ./files/usr/sbin/wifi-ap-log-clean.sh $(1)/usr/sbin/
	$(CP) ./files/usr/sbin/wifi-ap-trend-collector.sh $(1)/usr/sbin/

	# 其它配置/密钥
	$(INSTALL_DIR) $(1)/etc/wifi-ap
	$(CP) ./files/etc/wifi-ap/* $(1)/etc/wifi-ap/

endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
set -e
chmod +x $${IPKG_INSTROOT}/usr/bin/wifi-ap
chmod +x $${IPKG_INSTROOT}/usr/sbin/ap-set-bridge-ip.sh
chmod +x $${IPKG_INSTROOT}/usr/sbin/wifi-ap-firmware-upload.sh
chmod +x $${IPKG_INSTROOT}/usr/sbin/wifi-ap-log-clean.sh
chmod +x $${IPKG_INSTROOT}/usr/sbin/wifi-ap-trend-collector.sh
chmod +x $${IPKG_INSTROOT}/etc/init.d/wifi-ap
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
