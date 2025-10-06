# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=phicomm-k3screenctrl
PKG_RELEASE:=3

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/lwz322/k3screenctrl.git
PKG_SOURCE_DATE:=2020-09-18
PKG_SOURCE_VERSION:=d8896cfad4bdf39f58999f9420807f986300bada
PKG_MIRROR_HASH:=abfd3ae2bbc7979aee99e0c523e8a653e8abb81ecded8f1a2823fdc8c7e2ee07

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Hamster Tian <haotia@gmail.com>

PKG_FLAGS:=nonshared
PKG_FIXUP:=autoreconf
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS+= -D_GNU_SOURCE

define Package/phicomm-k3screenctrl
  SECTION:=utils
  CATEGORY:=Utilities
  DEPENDS:=@TARGET_bcm53xx_generic +@KERNEL_DEVMEM +@BUSYBOX_CONFIG_ARPING \
    +bc +bash +curl +coreutils +coreutils-od +jq
  TITLE:=LCD screen controller on PHICOMM K3
  URL:=https://github.com/lwz322/k3screenctrl.git
endef

define Package/phicomm-k3screenctrl/description
  K3 Screen Controller (k3screenctrl) is a program utilizing
  the LCD screen on PHICOMM K3 to display some stats.
endef

define Package/phicomm-k3screenctrl/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/k3screenctrl $(1)/usr/bin/k3screenctrl

	$(INSTALL_DIR) $(1)/lib/k3screenctrl $(1)/lib/k3screenctrl/oui
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/k3screenctrl/*.sh $(1)/lib/k3screenctrl/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/lib/k3screenctrl/oui/oui.txt $(1)/lib/k3screenctrl/oui/

	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_CONF) $(CURDIR)/files/k3screenctrl.config $(1)/etc/config/k3screenctrl
	$(INSTALL_BIN) $(CURDIR)/files/k3screenctrl.init $(1)/etc/init.d/k3screenctrl
endef

$(eval $(call BuildPackage,phicomm-k3screenctrl))
