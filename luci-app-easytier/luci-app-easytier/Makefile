#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk
-include $(dir $(lastword $(MAKEFILE_LIST)))../version.mk

PKG_VERSION:=$(or $(EASYTIER_VERSION),2.5.0)
PKG_RELEASE:=2

LUCI_TITLE:=LuCI support for EasyTier
LUCI_DEPENDS:=+kmod-tun +luci-compat
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-easytier

define Package/$(PKG_NAME)/conffiles
/etc/config/easytier
/etc/easytier/
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -f /etc/config/easytier ] ; then
  echo "备份luci配置文件/etc/config/easytier到/tmp/easytier_backup"
  echo "不重启设备之前再次安装luci-app-easytier 配置不丢失,无需重新配置"
  cp -rf /etc/config/easytier /tmp/easytier_backup
fi

if ls /etc/easytier/* >/dev/null 2>&1; then
  echo "备份easytier配置目录/etc/easytier到/tmp/et_config_backup"
  echo "不重启设备之前再次安装luci-app-easytier 配置不丢失,无需重新配置"
  cp -rf /etc/easytier /tmp/et_config_backup
fi

endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
chmod +x /etc/init.d/easytier
if [ -f /tmp/easytier_backup ] ; then
  echo "发现luci备份配置文件/tmp/easytier_backup，开始恢复到/etc/config/easytier"
  rm -rf /etc/config/easytier
  mv -f /tmp/easytier_backup /etc/config/easytier
  echo "请前往 VPN - EasyTier 界面进行重启插件"
fi
if [ -d /tmp/et_config_backup ] ; then
  echo "发现easytier备份配置目录/tmp/et_config_backup，开始恢复到/etc/easytier"
  rm -rf /etc/easytier
  mv -f /tmp/et_config_backup /etc/easytier
  echo "请前往 VPN - EasyTier 界面进行重启插件"
fi
endef

$(eval $(call Build/Template,Package/$(PKG_NAME)/prerm))
$(eval $(call Build/Template,Package/$(PKG_NAME)/postinst))

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
