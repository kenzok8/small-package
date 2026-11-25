#!/bin/sh
set -eu
prefix="${IPKG_INSTROOT:-}"
target=/usr/share/mise/mise-plugin.json
legacy="$prefix/usr/share/linkeasefull/desktop-apps.d/40-mise.json"
case "${1:-register}" in
 register)
  if [ ! -e "$legacy" ] && [ ! -L "$legacy" ]; then
   mkdir -p "${legacy%/*}"
   ln -s "$target" "$legacy"
  fi
  ;;
 remove)
  if [ -L "$legacy" ] && [ "$(readlink "$legacy")" = "$target" ]; then rm -f "$legacy"; fi
  rmdir "${legacy%/*}" 2>/dev/null || true
  ;;
 *) exit 2 ;;
esac
