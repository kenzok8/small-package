include $(TOPDIR)/rules.mk

PKG_NAME:=3ginfo
PKG_VERSION:=20250820
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/3ginfo/Default
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Information about the status of the 3G/4G/5G modem
	MAINTAINER:=Cezary Jackiewicz <cezary@eko.one.pl>
	PKGARCH:=all
endef

define Package/3ginfo-old
$(call Package/3ginfo/Default)
	DEPENDS:=+3ginfo-text-old +uhttpd
endef

define Package/3ginfo-lite
$(call Package/3ginfo/Default)
	TITLE+= (lite version)
	DEPENDS:=+comgt +@BUSYBOX_DEFAULT_AWK
endef

define Package/3ginfo-qmisignal
$(call Package/3ginfo/Default)
	TITLE+= (qmi signal)
	DEPENDS:=+uqmi +uhttpd
endef

define Package/3ginfo-text-old
$(call Package/3ginfo/Default)
	TITLE+= (text version)
	DEPENDS:=+comgt
endef

define Package/3ginfo-text-old/conffiles
/etc/config/3ginfo
endef

define Package/3ginfo
$(call Package/3ginfo/Default)
	DEPENDS:=+3ginfo-text +uhttpd
endef

define Package/3ginfo-text
$(call Package/3ginfo/Default)
	TITLE+= (text version)
	DEPENDS:=+comgt +sms-tool +modemdata
endef

define Package/3ginfo-text/conffiles
/etc/config/3ginfo
endef

define Build/Compile
endef

define Package/3ginfo-old/install
	$(CP) ./files-html-old/* $(1)
endef

define Package/3ginfo-lite/install
	$(CP) ./files-lite/* $(1)
	$(CP) ./files-text-old/usr/share/3ginfo/mccmnc.dat $(1)/usr/share/3ginfo-lite
	$(CP) ./files-text-old/usr/share/3ginfo/scripts/probeport.gcom $(1)/usr/share/3ginfo-lite
endef

define Package/3ginfo-qmisignal/install
	$(CP) ./files-qmisignal/* $(1)

	$(FIND) $(1) -type f -name '*.js' | while read src; do \
		uglifyjs "$$$$src" -o "$$$$src".1 && \
		mv "$$$$src".1 "$$$$src" || true; \
	done
endef

define Package/3ginfo-text-old/install
	$(CP) ./files-text-old/* $(1)
endef

define Package/3ginfo-text-old/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	ln -sf /usr/share/3ginfo/cgi-bin/3ginfo.sh /usr/bin/3ginfo
}
exit 0
endef

define Package/3ginfo/install
	$(CP) ./files-html/* $(1)

	$(SED) 's/?v=1/?v='${PKG_VERSION}'/g' $(1)/usr/share/3ginfo/html/index.html

	$(SED) 's/^\t*//g;s/^\s*//g;/^$$$$/d' $(1)/usr/share/3ginfo/html/index.html

	$(FIND) $(1) -type f -name '*.js' | while read src; do \
		uglifyjs "$$$$src" -o "$$$$src".1 && \
		mv "$$$$src".1 "$$$$src" || true; \
	done

	$(FIND) $(1) -type f -name '*.css' | while read src; do \
		cleancss "$$$$src" -o "$$$$src".1 && \
		mv "$$$$src".1 "$$$$src" || true; \
	done
endef

define Package/3ginfo-text/install
	$(CP) ./files-text/* $(1)
endef


$(eval $(call BuildPackage,3ginfo-old))
$(eval $(call BuildPackage,3ginfo-lite))
$(eval $(call BuildPackage,3ginfo-qmisignal))
$(eval $(call BuildPackage,3ginfo-text-old))
$(eval $(call BuildPackage,3ginfo))
$(eval $(call BuildPackage,3ginfo-text))
