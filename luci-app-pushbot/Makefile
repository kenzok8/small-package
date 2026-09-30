include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-pushbot
PKG_VERSION:=6.01
PKG_RELEASE:=12

PKG_MAINTAINER:=tty228 <tty228@yeah.net>  zzsj0928

# OpenWrt 23.05 的 luci.mk 版本规则只取 PKG_VERSION（忽略 PKG_RELEASE），
# 导致 GitHub Action 编译出的 ipk 没有 r 小版本（5.12 vs 5.12-r10）。
# 用 override VERSION 强制统一为 PKG_VERSION-rPKG_RELEASE。注意：必须
# 写在 include luci.mk 之前——luci.mk 末尾会立即 eval BuildPackage，
# 其 ipk 命名/control 里的 $(VERSION) 在那一刻固化，写后面就晚了。
# luci.mk 的 VERSION:= 是普通赋值（被 override 压住），且本值在新版
# luci.mk 与 i18n 子包（PKG_PO_VERSION）下与默认一致，不影响 apk/新版。
override VERSION:=$(if $(PKG_RELEASE),$(PKG_VERSION)-r$(PKG_RELEASE),$(PKG_VERSION))

LUCI_TITLE:=LuCI support for Pushbot
LUCI_PKGARCH:=all
# 核心依赖：luci-base（界面）、curl/jq（推送 JSON 解析）、iputils-arping（在线检测）
# iw（无线检测）、wrtbwmon/nlbwmon（流量统计）为可选功能，x86 上用户可选择不使用，不强制
LUCI_DEPENDS:=+luci-base +iputils-arping +curl +jq

# 汉化包（luci-i18n-*) 版本与主包保持同步
PKG_PO_VERSION:=$(PKG_VERSION)-r$(PKG_RELEASE)
# 兼容部分 luci.mk（如 immortalwrt）缺少 zh_Hans 语言定义的情况
LUCI_LANG.zh_Hans?=简体中文 (Simplified Chinese)

# 编译时自动生成"出厂默认值"备份（供"配置管理"重置使用）。
# 单一源：仅维护 root/etc/config/pushbot 与 root/usr/bin/pushbot/api/ 三个文件；
# 本行在 make 解析 Makefile 时执行 cp，把源复制到 root/usr/share/pushbot/defaults/。
# 备份目录不在 conffiles 列表 → 安装即落地、每次升级覆盖为最新默认值。
# 不用 postinst 备份的原因：/etc/config/pushbot 等是 conffile，opkg/apk 安装时
# 保留的是用户已改配置，postinst 复制到的"备份"实为用户配置而非出厂默认。
PUSHBOT_DEFAULTS_SYNC := $(shell mkdir -p root/usr/share/pushbot/defaults && \
	cp -f root/etc/config/pushbot root/usr/share/pushbot/defaults/pushbot && \
	cp -f root/usr/bin/pushbot/api/ipv4.list root/usr/bin/pushbot/api/ipv6.list \
	     root/usr/bin/pushbot/api/diy.json root/usr/share/pushbot/defaults/ && echo synced)

define Package/$(PKG_NAME)/conffiles
/etc/config/pushbot
/usr/bin/pushbot/api/diy.json
/usr/bin/pushbot/api/ipv4.list
/usr/bin/pushbot/api/ipv6.list
/usr/bin/pushbot/api/ip_blacklist
endef

define Package/$(PKG_NAME)/preinst
#!/bin/sh
# 安装/升级前保护用户 conffile（apk 系统）：
# apk 只存 conffiles/conffiles_static 清单却不据此保留用户修改（升级即覆盖），
# 故在覆盖【前】对比"设备当前 csum vs 上一版打包 csum"，不一致=用户改过→备份；
# postinst 再恢复（改过保留 / 未改更新 / 首装装初始）。
# opkg 系统原生按 conffiles 保留（10.253 已验证），此处直接跳过。
[ -d /lib/apk/packages ] || exit 0
BK=/tmp/pushbot/cf.bak
STATIC=$$(ls /lib/apk/packages/luci-app-pushbot*.conffiles_static 2>/dev/null | head -n1)
[ -n "$${STATIC}" ] || exit 0
for f in /etc/config/pushbot /usr/bin/pushbot/api/diy.json /usr/bin/pushbot/api/ipv4.list /usr/bin/pushbot/api/ipv6.list /usr/bin/pushbot/api/ip_blacklist; do
	[ -f "$${f}" ] || continue
	base=$$(awk -v p="$${f}" '$$1==p {print $$2; exit}' "$${STATIC}")
	[ -n "$${base}" ] || continue
	cur=$$(sha256sum "$${f}" | awk '{print $$1}')
	if [ "$${cur}" != "$${base}" ]; then
		mkdir -p "$${BK}$$(dirname "$${f}")"
		cp "$${f}" "$${BK}$${f}"
	fi
done
exit 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
# 公钥信任不在此处写（去冗余，同 luci-theme-liquid v0.9-r9）：
# 固件构建带 --no-scripts 不跑本脚本，故 IPKG_INSTROOT 分支是死代码；
# 公钥统一由包内 etc/uci-defaults/99-zed-apk-key-pushbot 写入 ——
# 固件场景随镜像首启执行、在线装机由 default_postinst 当次执行；
# OTA 老设备由 controller act_install 装前自举兜底。
# 恢复 preinst 备份的用户 conffile（apk 系统"改过则保留"；无备份即原生行为）
if [ -d /tmp/pushbot/cf.bak ]; then
	for f in /etc/config/pushbot /usr/bin/pushbot/api/diy.json /usr/bin/pushbot/api/ipv4.list /usr/bin/pushbot/api/ipv6.list /usr/bin/pushbot/api/ip_blacklist; do
		[ -f "/tmp/pushbot/cf.bak$${f}" ] && cp "/tmp/pushbot/cf.bak$${f}" "$${f}"
	done
	rm -rf /tmp/pushbot/cf.bak
fi
[ -n "$${IPKG_INSTROOT}" ] || {
	[ -f /tmp/pushbot/traffic_source ] && rm -f /tmp/pushbot/traffic_source
	[ -f /tmp/pushbot/nlbw_check_round ] && rm -f /tmp/pushbot/nlbw_check_round
	[ -f /tmp/pushbot/firewall_mode ] && rm -f /tmp/pushbot/firewall_mode
	[ -f /tmp/pushbot/wlan_interface ] && rm -f /tmp/pushbot/wlan_interface
	[ -f /tmp/pushbot/wireless_ifs ] && rm -f /tmp/pushbot/wireless_ifs
}
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
