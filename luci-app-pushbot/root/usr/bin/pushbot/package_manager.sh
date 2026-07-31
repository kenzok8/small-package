#!/bin/sh

get_package_version(){
    package_name="$1"

    [ -n "$package_name" ] || return 0

    # 1) apk：`apk info <pkg>` 输出 name-version（如 curl-8.21.0-r1）。
    #    注意不能用 `apk info -v`：-v 是 verbose，输出描述信息而非版本。
    if command -v apk >/dev/null 2>&1; then
        installed_pkg=$(apk info "$package_name" 2>/dev/null | head -n 1)
        if [ -n "$installed_pkg" ]; then
            version=$(echo "$installed_pkg" | sed -n "s/^${package_name}-//p")
            if [ -n "$version" ]; then
                echo "$version"
                return 0
            fi
        fi
    fi

    # 2) opkg：格式为 `pkgname - version`，取第三列。
    if command -v opkg >/dev/null 2>&1; then
        installed_pkg=$(opkg list-installed 2>/dev/null | grep -w "^${package_name}" | awk '{print $3}' | head -n 1)
        if [ -n "$installed_pkg" ]; then
            echo "$installed_pkg"
            return 0
        fi
    fi

    # 3) 命令自身检测回退：包管理器输出格式不兼容或依赖已内置进固件时，
    #    命令可用即视为依赖正常，版本号尽力提取。
    case "$package_name" in
        curl)
            if command -v curl >/dev/null 2>&1; then
                version=$(curl -V 2>/dev/null | head -n1 | awk '{print $2}')
                [ -n "$version" ] && { echo "$version"; return 0; }
                echo "installed"; return 0
            fi
            ;;
        iputils-arping)
            if command -v arping >/dev/null 2>&1; then
                version=$(arping -V 2>/dev/null | head -n1 | sed -n 's/.*iputils[-_ ]*//p')
                [ -n "$version" ] && { echo "$version"; return 0; }
                echo "installed"; return 0
            fi
            ;;
        iw)
            if command -v iw >/dev/null 2>&1; then
                version=$(iw version 2>/dev/null | awk '{print $NF}')
                [ -n "$version" ] && { echo "$version"; return 0; }
                echo "installed"; return 0
            fi
            ;;
    esac

    return 0
}
