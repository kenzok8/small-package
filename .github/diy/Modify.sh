#!/bin/bash
# --------------------------------------------------------
# Script for creating ACL file for each LuCI APP
rm -rf ./*/.git & rm -f ./*/.gitattributes
rm -rf ./*/.svn & rm -rf ./*/.github & rm -rf ./*/.gitignore
rm -rf create_acl_for_luci.err & rm -rf create_acl_for_luci.ok
rm -rf create_acl_for_luci.warn
cp -f diy/packages/files/usr/lib/lua/luci/view/admin_status/index/links.htm my-default-settings/files/usr/lib/lua/luci/view/admin_status/index/links.htm

exit 0
