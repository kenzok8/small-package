#!/bin/bash
# --------------------------------------------------------
# Script for creating ACL file for each LuCI APP
sed -i \
-e 's?include \.\./\.\./\(lang\|devel\)?include $(TOPDIR)/feeds/packages/\1?' \
-e "s/\(PKG_HASH\|PKG_MD5SUM\|PKG_MIRROR_HASH\):=.*/\1:=skip/" \
-e 's?2. Clash For OpenWRT?3. Applications?' \
-e 's?\.\./\.\./luci.mk?$(TOPDIR)/feeds/luci/luci.mk?' \
-e 's/ca-certificates/ca-bundle/' \
*/Makefile

exit 0
