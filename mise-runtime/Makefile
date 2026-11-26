include $(TOPDIR)/rules.mk

PKG_NAME:=mise-runtime
PKG_VERSION:=0.1.1
PKG_RELEASE:=4
PKG_LICENSE:=GPL-3.0-only

include $(INCLUDE_DIR)/package.mk

define Package/mise-runtime
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Persistent iStoreOS language runtimes
  DEPENDS:=@(x86_64||aarch64) +mise +lua +libuci-lua +luci-lib-jsonc +luci-lib-nixio +curl +ca-bundle +tar +xz-utils +zstd +ks-cli +coreutils-stat +libstdcpp +block-mount
  EXTRA_DEPENDS:=mise (>=2026.8.14-$(if $(CONFIG_USE_APK),r)28)
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) -Wall -Wextra -Werror -o $(PKG_BUILD_DIR)/exec-user $(PKG_BUILD_DIR)/exec-user.c $(TARGET_LDFLAGS)
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) -Wall -Wextra -Werror -o $(PKG_BUILD_DIR)/python-launch-musl $(PKG_BUILD_DIR)/python-launch.c $(TARGET_LDFLAGS)
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) -static -Wall -Wextra -Werror -o $(PKG_BUILD_DIR)/python-launch-glibc $(PKG_BUILD_DIR)/python-launch.c $(TARGET_LDFLAGS)
endef

define Package/mise-runtime/install
	$(INSTALL_DIR) $(1)/usr/share/mise-runtime/lib $(1)/usr/share/mise-runtime/licenses $(1)/usr/share/mise-runtime/native/bin $(1)/usr/sbin
	$(INSTALL_DATA) ./files/lib/*.lua $(1)/usr/share/mise-runtime/lib/
	$(INSTALL_DATA) ./files/catalog.json $(1)/usr/share/mise-runtime/catalog.json
	$(INSTALL_DATA) ./files/npm.json ./files/node-loader.cjs $(1)/usr/share/mise-runtime/
	$(INSTALL_DATA) ./files/python-launch.lua ./files/python-venv.py ./files/python-openssl.cnf $(1)/usr/share/mise-runtime/
	$(INSTALL_DATA) ./files/licenses/* $(1)/usr/share/mise-runtime/licenses/
	$(INSTALL_BIN) ./files/main.lua $(1)/usr/share/mise-runtime/main.lua
	$(INSTALL_BIN) ./files/execute.lua $(1)/usr/share/mise-runtime/execute.lua
	$(INSTALL_BIN) ./files/native/bin/* $(1)/usr/share/mise-runtime/native/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/exec-user $(1)/usr/share/mise-runtime/native/bin/exec-user
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/python-launch-musl $(PKG_BUILD_DIR)/python-launch-glibc $(1)/usr/share/mise-runtime/native/bin/
	$(INSTALL_BIN) ./files/mise-runtime $(1)/usr/sbin/mise-runtime
endef

$(eval $(call BuildPackage,mise-runtime))
