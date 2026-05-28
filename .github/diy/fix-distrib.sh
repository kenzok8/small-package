#!/bin/sh
# fix-distrib.sh — 修复被旧版 default-settings 破坏的 /etc/openwrt_release
#
# 背景：旧 default-settings 把 DISTRIB_REVISION / DISTRIB_RELEASE 用日期串覆盖，
#       会让 apk / opkg 校验 feed 版本失败、拼 URL 404。
# 用法（在 OpenWrt 设备上以 root 运行）：
#   wget -O- https://raw.githubusercontent.com/kenzok8/small-package/main/.github/diy/fix-distrib.sh | sh
#
# 行为：
#   1. 自动 backup /etc/openwrt_release 到 /etc/openwrt_release.bak.<时间戳>
#   2. 从 /etc/os-release（未被污染）读真实的 VERSION_ID / VERSION / PRETTY_NAME
#   3. 回填 DISTRIB_RELEASE / DISTRIB_REVISION / DISTRIB_DESCRIPTION
#   4. 保留 kenzo 印记：DISTRIB_DESCRIPTION 末尾追加 " by kenzo YYYY.MM.DD"，
#      并写入独立字段 kenzo_build
#   5. 跑一次 apk/opkg update 验证

set -eu

RELEASE_FILE="/etc/openwrt_release"
OS_RELEASE="/etc/os-release"

echo "==> 检查 $RELEASE_FILE 当前状态"
if [ ! -f "$RELEASE_FILE" ]; then
    echo "    ❌ 文件不存在，无法修复" >&2
    exit 1
fi

cur_rev="$(awk -F= '/^DISTRIB_REVISION=/ {gsub(/[^a-zA-Z0-9._+-]/,"",$2); print $2}' "$RELEASE_FILE")"
cur_rel="$(awk -F= '/^DISTRIB_RELEASE=/  {gsub(/[^a-zA-Z0-9._+-]/,"",$2); print $2}' "$RELEASE_FILE")"
echo "    DISTRIB_REVISION = $cur_rev"
echo "    DISTRIB_RELEASE  = $cur_rel"

# 检测是否被日期串污染（v2026.05.29 之类）
need_fix=0
case "$cur_rev" in v[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]) need_fix=1 ;; esac
case "$cur_rel" in v[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9]) need_fix=1 ;; esac

if [ "$need_fix" -eq 0 ]; then
    echo "==> ✅ DISTRIB_* 看起来正常（不是日期串），无需修复，退出"
    exit 0
fi

echo "==> ⚠️  检测到 DISTRIB_REVISION / DISTRIB_RELEASE 被覆盖为日期串"

if [ ! -f "$OS_RELEASE" ]; then
    echo "    ❌ $OS_RELEASE 也不存在，无法恢复原值，请手动修复" >&2
    exit 1
fi

# shellcheck disable=SC1090
. "$OS_RELEASE"
release="${VERSION_ID:-${OPENWRT_RELEASE:-unknown}}"
revision="${VERSION:-${BUILD_ID:-unknown}}"
desc="${PRETTY_NAME:-OpenWrt}"

if [ "$release" = "unknown" ] || [ "$revision" = "unknown" ]; then
    echo "    ❌ 从 $OS_RELEASE 取不到 VERSION_ID/VERSION 字段，无法自动恢复" >&2
    echo "       请贴出以下文件内容人工排查：" >&2
    echo "         cat $OS_RELEASE" >&2
    exit 1
fi

echo "==> 从 $OS_RELEASE 取到真实版本："
echo "    DISTRIB_RELEASE  = $release"
echo "    DISTRIB_REVISION = $revision"
echo "    DISTRIB_DESCRIPTION 基础 = $desc"

ts="$(date +'%Y%m%d-%H%M%S')"
bak="$RELEASE_FILE.bak.$ts"
cp "$RELEASE_FILE" "$bak"
echo "==> 已备份原文件到 $bak"

kenzo_date="$(date +'%Y.%m.%d')"

# 清掉所有要重写的字段（包括可能多余的 kenzo_build）
sed -i '/^DISTRIB_REVISION=/d;/^DISTRIB_RELEASE=/d;/^DISTRIB_DESCRIPTION=/d;/^kenzo_build=/d' "$RELEASE_FILE"

# 写回正确值 + kenzo 印记
{
    echo "DISTRIB_RELEASE='$release'"
    echo "DISTRIB_REVISION='$revision'"
    echo "DISTRIB_DESCRIPTION='$desc by kenzo $kenzo_date'"
    echo "kenzo_build='v$kenzo_date'"
} >> "$RELEASE_FILE"

echo "==> ✅ $RELEASE_FILE 已修复，新内容："
grep -E "^(DISTRIB_|kenzo_)" "$RELEASE_FILE" | sed 's/^/    /'

echo
echo "==> 验证包管理器能否正常 update"
if command -v apk >/dev/null 2>&1; then
    echo "    apk update ..."
    if apk update; then
        echo "==> ✅ apk update 成功，修复完成"
    else
        echo "==> ⚠️  apk update 仍然报错，可能还有别的问题；备份在 $bak" >&2
        exit 2
    fi
elif command -v opkg >/dev/null 2>&1; then
    echo "    opkg update ..."
    if opkg update; then
        echo "==> ✅ opkg update 成功，修复完成"
    else
        echo "==> ⚠️  opkg update 仍然报错，可能还有别的问题；备份在 $bak" >&2
        exit 2
    fi
else
    echo "==> ⚠️  未检测到 apk / opkg，无法自动验证；备份在 $bak"
fi
