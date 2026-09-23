#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=AgentFlow
PKG_VERSION:=1.0.1
PKG_RELEASE:=5
LUCI_DEPENDS:=+agentflow +luci-compat +luci-lib-taskd +luci-lib-linkeaseauth +linkease-app-entry
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

define Package/luci-app-agentflow/conffiles
/etc/config/agentflow
endef

define Package/luci-app-agentflow/postrm
#!/bin/sh
rm -f /tmp/luci-indexcache
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
