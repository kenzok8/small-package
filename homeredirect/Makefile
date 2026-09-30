#
# Copyright (c) 2020 xiaoqingfeng (xiaoqingfengatgm@gmail.com)
# Feed site - https://github.com/xiaoqingfengATGH/feeds-xiaoqingfeng
# This is free software, licensed under the GNU General Public License v3.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=HomeRedirect
PKG_VERSION:=2.0
PKG_RELEASE:=1
PKG_DATE:=20260930

PKG_MAINTAINER:=xiaoqingfeng <xiaoqingfengatgm@gmail.com>
PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Port forwarding utility for HomeLede.
  DEPENDS:=+socat
  PKGARCH:=all
  URL:=https://github.com/xiaoqingfengATGH/feeds-xiaoqingfeng
endef

define Package/$(PKG_NAME)/config
help
	$(PKG_NAME)
	Version: $(PKG_VERSION)-$(PKG_RELEASE)
	Port forwarding utility for HomeLede. Support TCP/UDP ipv4 & ipv6.
endef

define Package/$(PKG_NAME)/description
Port forwarding utility for HomeLede. Support TCP/UDP ipv4 & ipv6.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/homeredirect
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) files/etc/init.d/homeredirect $(1)/etc/init.d
	$(INSTALL_CONF) files/etc/config/homeredirect $(1)/etc/config
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	rm -f /etc/homeredirect/firewall.include
	rm -f /etc/homeredirect/script.sh
	uci -q batch <<-EOF >/dev/null
		delete firewall.homeredirect
		delete ucitrack.@homeredirect[-1]
		add ucitrack homeredirect
		set ucitrack.@homeredirect[-1].init=homeredirect
		commit ucitrack
		commit firewall
	EOF
	rm -rf /tmp/luci-*cache
}
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/homeredirect stop >/dev/null 2>&1
	uci -q batch <<-EOF >/dev/null
		delete ucitrack.@homeredirect[-1]
		delete firewall.homeredirect
		commit ucitrack
	EOF
	# remove generated per-rule firewall rules (hr_ prefixed)
	for s in $$(uci -q show firewall | sed -n "s/^firewall\.\(hr_[A-Za-z0-9_]*\)=rule$$/\1/p"); do
		uci -q delete "firewall.$$s"
	done
	uci -q commit firewall
	/etc/init.d/firewall reload >/dev/null 2>&1
}
exit 0
endef

define Build/Configure
endef

define Build/Prepare
endef

define Build/Compile
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
