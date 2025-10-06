#
# Copyright (C) 2014-2014 OpenWrt.org
# Copyright (C) 2018-2019 Ycarus (Yannick Chabanois) <ycarus@zugaina.org>
#
# This is free software, licensed under the GNU General Public License v3 or later.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mptcp
PKG_VERSION:=6.1
PKG_RELEASE:=1

PKG_MAINTAINER:=Ycarus (Yannick Chabanois) <ycarus@zugaina.org>
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/mptcp
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Multipath TCP configuration scripts
  DEPENDS:=+ip +iptables +ethtool +ipcalc
  KCONFIG:=\
      CONFIG_MPTCP=y \
      CONFIG_MPTCP_IPV6=y \
      CONFIG_MPTCP_BINDER=y \
      CONFIG_MPTCP_FULLMESH=y \
      CONFIG_MPTCP_NDIFFPORTS=y \
      CONFIG_MPTCP_PM_ADVANCED=y \
      CONFIG_MPTCP_REDUNDANT=y \
      CONFIG_MPTCP_ECF=y \
      CONFIG_MPTCP_ROUNDROBIN=y \
      CONFIG_MPTCP_SCHED_ADVANCED=y \
      CONFIG_DEFAULT_FULLMESH=y \
      CONFIG_DEFAULT_MPTCP_PM="fullmesh" \
      CONFIG_DEFAULT_MPTCP_SCHED="default" \
      CONFIG_DEFAULT_NDIFFPORTS=n \
      CONFIG_DEFAULT_REDUNDANT=n \
      CONFIG_DEFAULT_ROUNDROBIN=n \
      CONFIG_DEFAULT_SCHEDULER=y \
      CONFIG_DEFAULT_BINDER=n \
      CONFIG_DEFAULT_DUMMY=n \
      CONFIG_DEFAULT_OLIA=y \
      CONFIG_DEFAULT_BALIA=n \
      CONFIG_DEFAULT_LIA=n \
      CONFIG_DEFAULT_WVEGAS=n \
      CONFIG_DEFAULT_CUBIC=n \
      CONFIG_DEFAULT_RENO=n \
      CONFIG_DEFAULT_BBR=n \
      CONFIG_TCP_CONG_BALIA=y \
      CONFIG_TCP_CONG_LIA=y \
      CONFIG_TCP_CONG_OLIA=y \
      CONFIG_TCP_CONG_WVEGAS=y \
      CONFIG_TCP_CONG_BBR=y \
      CONFIG_DEFAULT_TCP_CONG="olia" \
      CONFIG_INET_MPTCP_DIAG=y \
      CONFIG_INET_DIAG=y \
      CONFIG_IPV6=y \
      CONFIG_MPTCP_IPV6=y

  PKGARCH:=all
endef

define Package/mptcp/description
  MultiPath TCP (MPTCP) is an effort towards enabling the simultaneous use of
  several IP-addresses/interfaces by a modification of TCP that presents a regular
  TCP interface to applications, while in fact spreading data across several
  subflows. Benefits of this include better resource utilization, better throughput
  and smoother reaction to failures.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/mptcp/install
	$(INSTALL_DIR) $(1)
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,mptcp))
