include $(TOPDIR)/rules.mk

PKG_NAME:=speedtest-cli
PKG_VERSION:=2.1.3
PKG_RELEASE:=1

PYPI_NAME:=speedtest-cli
PKG_HASH:=5e2773233cedb5fa3d8120eb7f97bcc4974b5221b254d33ff16e2f1d413d90f0

PKG_MAINTAINER:=Jaymin Patel <jem.patel@gmail.com>
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

define Package/speedtest-cli
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Command line interface for testing internet bandwidth using speedtest.net
  URL:=https://github.com/sivel/speedtest-cli
  DEPENDS:=+python3-light +python3-pkg-resources +python3-xml +python3-email \
	  +python3-urllib +python3-codecs +python3-openssl
endef

define Package/speedtest-cli/description
  Command line interface for testing internet bandwidth using speedtest.net
endef

$(eval $(call Py3Package,speedtest-cli))
$(eval $(call BuildPackage,speedtest-cli))
#$(eval $(call BuildPackage,speedtest-cli-src))
