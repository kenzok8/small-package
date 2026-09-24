# luci-app-linkeasefull-embed

Registers OpenWrt LuCI as a LinkEaseFull desktop module without using an iframe.
It is installed by the `app-meta-linkeasefull` product bundle while remaining
separate from the independently installable `linkeasefull` runtime package.

This package installs:

- `/usr/share/linkeasefull/openwrt-luci/openwrt-luci.json`
- `/usr/share/linkeasefull/desktop-apps.d/15-openwrt-luci.json`
- `/www/luci-static/linkeasefull-embed/embed-prelude.js`
- `/www/luci-static/linkeasefull-embed/embed.css`

The package deliberately does not install LuCI network protocol handlers or
modify `/www/luci-static/resources/protocol/`. Protocol support belongs to the
firmware and its LuCI protocol packages; this package is limited to embedding
the firmware-provided LuCI UI in LinkEaseFull.

The desktop manifest uses the builtin `LuciContainer` component with
`isolation=scoped-dom-css`. That default scopes common Vue/React mount points,
redirects dynamic styles and portal nodes into the LuCI container, and scopes CSS
to `.le-luci-document`.

Users can create additional LuCI plugin desktop entries from LinkEaseFull by
adding a name, an icon URL, and a LuCI URL under `/cgi-bin/luci/...`. Content-only
plugin entries, such as DDNSTO, should use `contentOnly=true` so the LuCI menu is
hidden and only the plugin content is shown.
