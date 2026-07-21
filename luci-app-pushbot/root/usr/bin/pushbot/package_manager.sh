#!/bin/sh

get_package_version(){
    package_name="$1"

    [ -n "$package_name" ] || return 0

    if command -v apk >/dev/null 2>&1; then
        installed_pkg=$(apk info -v "$package_name" 2>/dev/null | head -n 1)
        if [ -n "$installed_pkg" ]; then
            echo "$installed_pkg" | sed -n "s/^${package_name}-//p"
            return 0
        fi
    fi

    if command -v opkg >/dev/null 2>&1; then
        installed_pkg=$(opkg list-installed 2>/dev/null | grep -w "^${package_name}" | awk '{print $3}' | head -n 1)
        if [ -n "$installed_pkg" ]; then
            echo "$installed_pkg"
            return 0
        fi
    fi

    return 0
}
