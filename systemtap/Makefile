#
# Copyright (C) 2018-2025 Ycarus (Yannick Chabanois) <ycarus@zugaina.org> for OpenMPTCProuter
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=systemtap
PKG_RELEASE:=1
PKG_VERSION:=5.3

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://sourceware.org/systemtap/ftp/releases/
PKG_HASH:=966a360fb73a4b65a8d0b51b389577b3c4f92a327e84aae58682103e8c65a69a

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_DEPENDS:=systemtap/host
PKG_INSTALL:=1

PKG_LICENSE:=GPL-2.0-or-later

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk

define Package/systemtap
	SUBMENU:=System
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Simplify the gathering of information
	URL:=http://sourceware.org/systemtap/wiki
	DEPENDS:=@(LINUX_5_15||LINUX_6_1) +libelf +libdw
	MAINTAINER:=Ycarus (Yannick Chabanois) <ycarus@zugaina.org>
endef

define Package/systemtap/description
  SystemTap (stap) is a scripting language and tool for dynamically instrumenting running production Linux-based operating systems. 
endef

CONFIGURE_ARGS += --without-rpm \
            --without-nss --without-avahi --without-dyninst \
            --disable-server --disable-grapher --enable-prologues \
            --without-python2-probes \
            --disable-libvirt --disable-sqlite --disable-monitor --without-python3-probes \
            ac_cv_prog_have_javac=no \
            ac_cv_prog_have_jar=no
# --disable-translator
HOST_CONFIGURE_ARGS += --without-rpm \
            --without-nss --without-avahi --without-dyninst \
            --disable-server --disable-grapher --enable-prologues \
            --without-python2-probes \
            --disable-libvirt --disable-sqlite --disable-monitor --without-python3-probes \
            ac_cv_prog_have_javac=no \
            ac_cv_prog_have_jar=no

define Package/systemtap/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/include
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/share
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/* $(1)/usr/bin/
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/* $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/share/* $(1)/usr/share/
endef

define Host/install
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/usr/bin
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/usr/include
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/usr/lib
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/usr/share
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/* $(STAGING_DIR_HOST)/usr/bin/
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(STAGING_DIR_HOST)/usr/include/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/* $(STAGING_DIR_HOST)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/share/* $(STAGING_DIR_HOST)/usr/share/
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,systemtap))
