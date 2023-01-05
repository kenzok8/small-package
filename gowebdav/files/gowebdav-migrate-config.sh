#!/bin/sh

. /lib/functions.sh

config_load "gowebdav"
config_get enable "config" "enable"
[ -z "$enable" ] || uci -q rename "gowebdav.config.enable"="enabled"

config_get root_dir "config" "root_dir"
[ -z "$root_dir" ] || uci -q rename "gowebdav.config.root_dir"="mount_dir"

config_get allow_wan "config" "allow_wan"
[ -z "$allow_wan" ] || uci -q rename "gowebdav.config.allow_wan"="public_access"

config_get enable_auth "config" "enable_auth"
config_get username "config" "username"
[ -z "$enable_auth" -a -n "$username" ] && uci -q set "gowebdav.config.enable_auth"="1"

config_get use_https "config" "use_https"
[ -z "$use_https" ] || uci -q rename "gowebdav.config.use_https"="enable_https"

[ -z "$(uci -q changes "gowebdav")" ] || uci -q commit "gowebdav"

exit 0
