#!/bin/sh
# Called by the owning plugin and its metadata migration hook.
set -e
root="${IPKG_INSTROOT:-}"
manifest="/usr/share/fastnet/fastnet-plugin.json"
legacy="${root}/usr/share/linkeasefull/desktop-apps.d/17-fastnet.json"
[ -f "${root}${manifest}" ] || exit 0
# Replace only the exact historical metadata payload; preserve custom entries.
if [ -f "${legacy}" ] && [ ! -L "${legacy}" ] && [ "$(sha256sum "${legacy}" | cut -d ' ' -f 1)" = "9ca279c3baca876bed3a4abe23d5edd69940fcaff4db17f27237e02c24cbabef" ]; then
    rm -f "${legacy}"
fi
if [ ! -e "${legacy}" ] && [ ! -L "${legacy}" ]; then
    mkdir -p "${legacy%/*}"
    ln -s "${manifest}" "${legacy}"
fi
