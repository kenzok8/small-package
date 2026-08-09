include $(TOPDIR)/rules.mk

PKG_NAME:=UA2F
PKG_VERSION:=5.2.0
PKG_RELEASE:=1

PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILE:=LICENSE

PKG_BUILD_DIR:=$(CURDIR)/..
CMAKE_BINARY_SUBDIR:=build

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ua2f
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=Change User-Agent to Fwords on the fly.
  URL:=https://github.com/Zxilly/UA2F
  DEPENDS:= \
    +libnetfilter-conntrack \
    +libnetfilter-queue \
    +(mips||mipsel):libatomic \
    +libpthread \
    +libuci \
    +ip-full \
    +USE_GLIBC:libasan \
    +(PACKAGE_nftables-json||PACKAGE_nftables-nojson):kmod-nft-queue \
    +(PACKAGE_nftables-json||PACKAGE_nftables-nojson):kmod-nft-tproxy \
    +PACKAGE_firewall:iptables-mod-conntrack-extra \
    +PACKAGE_firewall:iptables-mod-filter \
    +PACKAGE_firewall:iptables-mod-nfqueue \
    +PACKAGE_firewall:iptables-mod-tproxy
endef

define Package/ua2f/config
  config UA2F_CUSTOM_USER_AGENT
    bool "Enable custom User-Agent"
    depends on PACKAGE_ua2f
    default n
    help
      Enable this option to use a custom User-Agent string.

  config UA2F_USER_AGENT_STRING
    string "Custom User-Agent string"
    depends on UA2F_CUSTOM_USER_AGENT
    default "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.68"
    help
      Specify the custom User-Agent string to use when UA2F_CUSTOM_USER_AGENT is enabled.

  config UA2F_ENABLE_LIBBACKTRACE
    bool "Enable libbacktrace support"
    depends on PACKAGE_ua2f
    default y
    help
      Enable this option to use libbacktrace for better error reporting.
      This will increase the binary size but provide more detailed error information.

endef

CMAKE_OPTIONS += \
	-DUA2F_VERSION_STR="$(PKG_VERSION)" \
	-DUA2F_CUSTOM_USER_AGENT=$(if $(CONFIG_UA2F_CUSTOM_USER_AGENT),ON,OFF) \
	-DUA2F_USER_AGENT_STRING=$(CONFIG_UA2F_USER_AGENT_STRING) \
	-DUA2F_ENABLE_BACKTRACE=$(if $(CONFIG_UA2F_ENABLE_LIBBACKTRACE),ON,OFF) \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo

# The QEMU workflow creates this marker inside the mounted feed. Keep coverage
# instrumentation out of release packages while allowing the SDK build to
# retain matching .gcno files and its cross-gcov executable on the host.
ifneq ($(wildcard $(PKG_BUILD_DIR)/openwrt/.ua2f-coverage-build),)
CMAKE_OPTIONS += -DUA2F_ENABLE_COVERAGE=ON
UA2F_COVERAGE_BUILD:=1
UA2F_COVERAGE_DIR:=$(PKG_BUILD_DIR)/.pkgdir/openwrt-coverage
UA2F_GCOV_WRAPPER:=$(TOOLCHAIN_DIR)/bin/$(TARGET_CROSS)gcov
UA2F_GCOV_BINARY:=$(dir $(UA2F_GCOV_WRAPPER)).$(notdir $(UA2F_GCOV_WRAPPER)).bin
endif

STRIP:=true

define Package/ua2f/description
  Change User-agent to Fwords to prevent being detected.
endef

define Package/ua2f/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/ua2f $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d
	$(INSTALL_BIN) ./files/ua2f.config $(1)/etc/config/ua2f
	$(INSTALL_BIN) ./files/ua2f.init $(1)/etc/init.d/ua2f

	$(if $(UA2F_COVERAGE_BUILD),rm -rf $(UA2F_COVERAGE_DIR))
	$(if $(UA2F_COVERAGE_BUILD),$(INSTALL_DIR) $(UA2F_COVERAGE_DIR)/objects/CMakeFiles/ua2f.dir)
	$(if $(UA2F_COVERAGE_BUILD),cd $(PKG_BUILD_DIR)/build/CMakeFiles/ua2f.dir && find . -name '*.gcno' -exec cp -fp --parents '{}' $(UA2F_COVERAGE_DIR)/objects/CMakeFiles/ua2f.dir/ \;)
	$(if $(UA2F_COVERAGE_BUILD),$(INSTALL_DIR) $(UA2F_COVERAGE_DIR)/toolchain/bin)
	$(if $(UA2F_COVERAGE_BUILD),$(INSTALL_DIR) $(UA2F_COVERAGE_DIR)/host/lib)
	$(if $(UA2F_COVERAGE_BUILD),$(INSTALL_BIN) $(UA2F_GCOV_WRAPPER) $(UA2F_COVERAGE_DIR)/toolchain/bin/$(notdir $(UA2F_GCOV_WRAPPER)))
	$(if $(UA2F_COVERAGE_BUILD),$(INSTALL_BIN) $(UA2F_GCOV_BINARY) $(UA2F_COVERAGE_DIR)/toolchain/bin/$(notdir $(UA2F_GCOV_BINARY)))
	$(if $(UA2F_COVERAGE_BUILD),$(INSTALL_BIN) $(STAGING_DIR_HOST)/lib/ld-linux-x86-64.so.2 $(UA2F_COVERAGE_DIR)/host/lib/)
	$(if $(UA2F_COVERAGE_BUILD),$(INSTALL_BIN) $(STAGING_DIR_HOST)/lib/libc.so.6 $(UA2F_COVERAGE_DIR)/host/lib/)
	$(if $(UA2F_COVERAGE_BUILD),$(INSTALL_BIN) $(STAGING_DIR_HOST)/lib/runas.so $(UA2F_COVERAGE_DIR)/host/lib/)
endef

define Package/ua2f/postinst
#!/bin/sh

# check if we are on real system
[ -n "$${IPKG_INSTROOT}" ] || {
	uci -q delete firewall.ua2f

	if [ -z "$(command -v nft)" ]; then
		uci -q batch <<-EOF >/dev/null
			set firewall.ua2f=include
			set firewall.ua2f.type=script
			set firewall.ua2f.path=/var/etc/ua2f.include
			set firewall.ua2f.reload=1
		EOF
	fi

	uci -q commit firewall
	exit 0
}
endef

$(eval $(call BuildPackage,ua2f))
