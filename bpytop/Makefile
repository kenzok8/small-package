# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=bpytop
PKG_VERSION:=1.0.68
PKG_RELEASE:=$(AUTORELEASE)

PYPI_NAME:=bpytop
PKG_HASH:=53b66788e8d7c7abbab43c6275fa1c3b2316e56e46f7a093f2f4dfb397549bb2

PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

define Package/bpytop
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Python port of bashtop
  URL:=https://github.com/aristocratos/bpytop
  DEPENDS:=+python3-psutil +python3-setuptools
endef

define Package/bpytop/description
  Resource monitor that shows usage and stats for
  processor, memory, disks, network and processes.
endef

define Py3Package/bpytop/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/bpytop $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/share/bpytop
	$(CP) $(PKG_BUILD_DIR)/themes $(1)/usr/share/bpytop/
endef

$(eval $(call Py3Package,bpytop))
$(eval $(call BuildPackage,bpytop))
$(eval $(call BuildPackage,bpytop-src))
