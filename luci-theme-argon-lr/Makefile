#
# Copyright (C) 2020-2020 liuran001
# Copyright (C) 2008-2019 Jerrykuku
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
# Copyright (C) 2019-2020 Lienol <lawlienol@gmail.com>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=Argon Theme magic version
LUCI_DEPENDS:=
PKG_VERSION:=1
PKG_RELEASE:=20201005

include $(TOPDIR)/feeds/luci/luci.mk


define Package/luci-theme-argon-lr/postinst
#!/bin/sh
sed -i ":a;$!N;s/tmpl.render.*sysauth_template.*return/local scope = { duser = default_user, fuser = user }\nlocal ok, res = luci.util.copcall\(luci.template.render_string, [[<% include\(\"themes\/\" .. theme .. \"\/sysauth\"\) %>]], scope\)\nif ok then\nreturn res\nend\nreturn luci.template.render\(\"sysauth\", scope\)/;ba" /usr/lib/lua/luci/dispatcher.lua
sed -i ":a;$!N;s/t.render.*sysauth_template.*return/local scope = { duser = h, fuser = a }\nlocal ok, res = luci.util.copcall\(luci.template.render_string, [[<% include\(\"themes\/\" .. theme .. \"\/sysauth\"\) %>]], scope\)\nif ok then\nreturn res\nend\nreturn luci.template.render\(\"sysauth\", scope\)/;ba" /usr/lib/lua/luci/dispatcher.lua
[ -f /usr/lib/lua/luci/view/themes/argon/out_header_login.htm ] && mv -f /usr/lib/lua/luci/view/themes/argon/out_header_login.htm /usr/lib/lua/luci/view/header_login.htm
rm -Rf /var/luci-modulecache
rm -Rf /var/luci-indexcache
exit 0
endef

# call BuildPackage - OpenWrt buildroot signature