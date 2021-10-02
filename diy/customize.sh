#!/bin/bash
# --------------------------------------------------------
# Script to compile and create files for each openwrt
# --------------------------------------------------------
#1. Modify default IP
sed -i 's/192.168.1.1/192.168.3.1/g' openwrt/package/base-files/files/bin/config_generate

date=`date +%m.%d`
date1=`date +%h`
sed -i "s/DISTRIB_DESCRIPTION=\"0penwrt'\"/g" package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_REVISION=\"$date'\"/g" package/base-files/files/etc/openwrt_release
sed -i "s/%C=\"$date1'\"/g" package/base-files/files/etc/openwrt_version
sed -i "s/ %D %V, %C=\"v_$date1 by kenzo'\"/g"  package/base-files/files/etc/banner
#Lean设置
sed -i "s/LuCI Master=\"kenzo'\"/g" package/lean/default-settings/files/zzz-default-settings
sed -i "s/luciversion=\"$date1'\"/g" package/lean/default-settings/files/zzz-default-settings
#ctc设置
sed -i "s/LuCI openwrt-18.06 branch=\"kenzo'\"/g" package/emortal/default-settings/files/zzz-default-settings
sed -i "s/LuCI openwrt-21.02 branch=\"kenzo'\"/g" package/emortal/default-settings/files/zzz-default-settings
sed -i "s/luciversion=\"$date1'\"/g" package/emortal/default-settings/files/zzz-default-settings
#Lienol设置
sed -i "s/17.01 Lienol=\"kenzo'\"/g" package/default-settings/files/zzz-default-settings
sed -i "s/luciversion=\"$date1'\"/g" package/default-settings/files/zzz-default-settings

# 修改自定义固件名,增加编译日期(by:kenzo）
sed -i "s/IMG_PREFIX:=$(VERSION_DIST_SANITIZED)=\"IMG_PREFIX:=$date-$(VERSION_DIST_SANITIZED)'\"/g" include/image.mk


exit
