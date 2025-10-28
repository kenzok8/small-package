#
# Copyright (C) 2008-2024 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=netdata
PKG_VERSION:=2.7.2
PKG_RELEASE:=28

PKG_MAINTAINER:=Josef Schlehofer <pepe.schlehofer@gmail.com>, Daniel Engberg <daniel.engberg.lists@pyret.net>
PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=COPYING
PKG_CPE_ID:=cpe:/a:my-netdata:netdata

PKG_SOURCE:=$(PKG_NAME)-v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/netdata/netdata/releases/download/v$(PKG_VERSION)
PKG_HASH:=skip
PKG_BUILD_DIR=$(BUILD_DIR)/$(PKG_NAME)-v$(PKG_VERSION)

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1
PKG_FIXUP:=autoreconf
PKG_BUILD_FLAGS:=no-mips16 gc-sections

PKG_BUILD_DEPENDS:=protobuf/host golang/host

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
include $(INCLUDE_DIR)/nls.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk


define Package/netdata
  SECTION:=admin
  CATEGORY:=Administration
  DEPENDS:=+zlib +libuuid +libuv +libmnl +liblz4 +libjson-c +libyaml +libopenssl +libcurl +protobuf +libzstd +libpcre2
  TITLE:=Real-time performance monitoring tool
  URL:=https://www.netdata.cloud/
  PROVIDES:=netdata-ssl
endef

define Package/netdata/description
  netdata is a highly optimized Linux daemon providing real-time performance
  monitoring for Linux systems, applications and SNMP devices over the web.

  If you want to use Python plugins install python3, python3-yaml and
  python3-urllib3
endef

TARGET_CFLAGS := $(filter-out -O%,$(TARGET_CFLAGS)) -O3
TARGET_LDFLAGS += -L$(STAGING_DIR)/usr/lib
TARGET_CFLAGS += $(FPIC)

CMAKE_OPTIONS += \
	-DCMAKE_INSTALL_PREFIX="/" \
	-DCMAKE_CROSSCOMPILING=True \
	-DProtobuf_PROTOC_EXECUTABLE=$(STAGING_DIR_HOSTPKG)/bin/protoc \
	-DENABLE_ACLK=On \
	-DENABLE_CLOUD=On \
	-DENABLE_DBENGINE=On \
	-DENABLE_EXPORTER_PROMETHEUS_REMOTE_WRITE=Off \
	-DENABLE_EXPORTER_MONGODB=Off \
	-DENABLE_H2O=Off \
	-DENABLE_LIBBACKTRACE=Off \
	-DENABLE_LOGS_MANAGEMENT_TESTS=Off \
	-DENABLE_ML=Off \
	-DENABLE_PLUGIN_APPS=Off \
	-DENABLE_PLUGIN_CGROUP_NETWORK=Off \
	-DENABLE_PLUGIN_CUPS=Off \
	-DENABLE_PLUGIN_DEBUGFS=Off \
	-DENABLE_PLUGIN_EBPF=Off \
	-DENABLE_PLUGIN_FREEIPMI=Off \
	-DENABLE_PLUGIN_LOGS_MANAGEMENT=Off \
	-DENABLE_PLUGIN_NFACCT=Off \
	-DENABLE_PLUGIN_SYSTEMD_JOURNAL=Off \
	-DENABLE_PLUGIN_XENSTAT=Off \
	-DENABLE_WEBRTC=Off

define Package/netdata/conffiles
/etc/config/netdata
/etc/netdata/
endef

define Package/netdata/install
	#netdata binary
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/netdata $(1)/usr/sbin

	#netdata libs
	$(INSTALL_DIR) $(1)/usr/lib/netdata
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/netdata/conf.d $(1)/usr/lib/netdata

	#netdata plugins
	$(INSTALL_DIR) $(1)/usr/libexec/netdata
	$(CP) $(PKG_INSTALL_DIR)/usr/libexec/netdata/charts.d $(1)/usr/libexec/netdata
	$(CP) $(PKG_INSTALL_DIR)/usr/libexec/netdata/plugins.d $(1)/usr/libexec/netdata
	$(CP) $(PKG_INSTALL_DIR)/usr/libexec/netdata/python.d $(1)/usr/libexec/netdata

	#netdata configuration
	$(INSTALL_DIR) $(1)/etc/netdata
	$(CP) $(PKG_INSTALL_DIR)/etc/netdata $(1)/etc
	$(INSTALL_DATA) ./files/netdata.conf $(1)/etc/netdata
	touch $(1)/etc/netdata/.opt-out-from-anonymous-statistics
	
	#netdata init
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/netdata.init $(1)/etc/init.d/netdata

	#netdata webdir and remove uneeded files
	$(INSTALL_DIR) $(1)/usr/share/netdata
	$(CP) $(PKG_INSTALL_DIR)/usr/share/netdata $(1)/usr/share
	rm $(1)/usr/share/netdata/web/v3/3D_PARTY_LICENSES.txt
	rm $(1)/usr/share/netdata/web/v3/LICENSE.md
	rm $(1)/usr/share/netdata/web/v3/*.LICENSE.txt
	rm -r $(1)/usr/share/netdata/web/static/*
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/netdata.init $(1)/etc/init.d/netdata
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/netdata.config $(1)/etc/config/netdata
	$(INSTALL_DIR) $(1)/etc/nginx/conf.d
	$(INSTALL_DATA) ./files/netdata.locations $(1)/etc/nginx/conf.d/netdata.locations
	$(INSTALL_DATA) ./files/netdata.htpasswd  $(1)/etc/nginx/conf.d/netdata.htpasswd
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DATA) ./files/netdata.uci-defaults $(1)/etc/uci-defaults/luci-netdata
endef

$(eval $(call BuildPackage,netdata))
