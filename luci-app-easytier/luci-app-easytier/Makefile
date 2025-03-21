#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_VERSION:=2.2.4
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for EasyTier
LUCI_DEPENDS:=+kmod-tun
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-easytier

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -f /etc/config/easytier ] ; then
  echo "备份easytier配置文件/etc/config/easytier到/tmp/easytier_backup"
  echo "不重启设备之前再次安装luci-app-easytier 配置不丢失,不用重新配置"
  mv -f /etc/config/easytier /tmp/easytier_backup
fi
if [ -f /etc/easytier/config.toml ] ; then
  echo "备份easytier配置文件/etc/easytier/config.toml到/tmp/config_backup.toml"
  echo "不重启设备之前再次安装luci-app-easytier 配置不丢失,不用重新配置"
  mv -f /etc/easytier/config.toml /tmp/config_backup.toml 
fi
if [ -f /etc/easytier/et.db ] ; then
  echo "备份easytier数据库/etc/easytier/et.db到/tmp/et_backup.db"
  echo "不重启设备之前再次安装luci-app-easytier 配置不丢失,不用重新配置"
  mv -f /etc/easytier/et.db /tmp/et_backup.db
fi
if [ -f /etc/easytier/et_machine_id ] ; then
  echo "备份easytier UUID /etc/easytier/et_machine_id到/tmp/et_machine_id_backup"
  echo "不重启设备之前再次安装luci-app-easytier UUID不丢失,不用重新配置"
  mv -f /etc/easytier/et_machine_id /tmp/et_machine_id_backup
fi
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
chmod +x /etc/init.d/easytier
if [ -f /tmp/easytier_backup ] ; then
  echo "发现easytier备份配置文件/tmp/easytier_backup，开始恢复到/etc/config/easytier"
  mv -f /tmp/easytier_backup /etc/config/easytier
  echo "请前往 VPN - EasyTier 界面进行重启插件"
fi
if [ -f /tmp/config_backup.toml ] ; then
  echo "发现easytier备份配置文件/tmp/config_backup.toml，开始恢复到/etc/easytier/config.toml"
  mv -f /tmp/config_backup.toml /etc/easytier/config.toml
  echo "请前往 VPN - EasyTier 界面进行重启插件"
fi
if [ -f /tmp/et_backup.db ] ; then
  echo "发现easytier备份数据库/tmp/et_backup.db，开始恢复到/etc/easytier/et.db"
  mv -f /tmp/et_backup.db /etc/easytier/et.db
  echo "请前往 VPN - EasyTier 界面进行重启插件"
fi
if [ -f /tmp/et_machine_id_backup ] ; then
  echo "发现easytier备份UUID /tmp/et_machine_id_backup，开始恢复到/etc/easytier/et.db"
  mv -f /tmp/et_machine_id_backup /etc/easytier/et_machine_id
  echo "请前往 VPN - EasyTier 界面进行重启插件"
fi
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
