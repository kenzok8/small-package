#!/bin/bash
PKG_NAME="$1"
CURDIR="$2"
PKG_BUILD_DIR="$3"
PKG_BUILD_BIN="$PKG_BUILD_DIR/bin"
export PATH="$PATH:$PKG_BUILD_BIN"

OS=linux
ARCH=amd64
JQVERSION=1.8.1
DOCNAME=Ruleset-URI-Scheme
SHARKIMG='img/shark-taiko.gif'
SHARKAUDIO='audio/A!.mp3'

mkdir -p "$PKG_BUILD_BIN"
curl -L "https://github.com/jqlang/jq/releases/download/jq-${JQVERSION}/jq-${OS}-${ARCH}" -o "$PKG_BUILD_BIN"/jq
chmod +x "$PKG_BUILD_BIN"/jq
latest="$(curl -L https://api.github.com/repos/kpym/gm/releases/latest | jq -rc '.tag_name' 2>/dev/null)"
curl -L "https://github.com/kpym/gm/releases/download/${latest}/gm_${latest#v}_Linux_intel64.tar.gz" -o- | tar -xz -C "$PKG_BUILD_BIN"
latest="$(curl -L https://api.github.com/repos/tdewolff/minify/releases/latest | jq -rc '.tag_name' 2>/dev/null)"
curl -L "https://github.com/tdewolff/minify/releases/download/${latest}/minify_${OS}_${ARCH}.tar.gz" -o- | tar -xz -C "$PKG_BUILD_BIN"
chmod -R +x "$PKG_BUILD_BIN"

cp "$CURDIR"/docs/$DOCNAME.md "$PKG_BUILD_DIR"
pushd "$PKG_BUILD_DIR"
gm $DOCNAME.md
p=$(sed -n '/github.min.css/=' $DOCNAME.html)
{
head -n$(( $p -1 )) $DOCNAME.html
echo '<style>'
cat "$CURDIR"/docs/css/ClearnessDark.css
echo '</style>'
tail -n +$(( $p +1 )) $DOCNAME.html
} > buildin.html
popd
minify "$PKG_BUILD_DIR"/buildin.html | base64 | tr -d '\n' > "$PKG_BUILD_DIR"/base64
sed -i "s|'cmxzdHBsYWNlaG9sZGVy'|'$(cat "$PKG_BUILD_DIR"/base64)'|" "$PKG_BUILD_DIR"/htdocs/luci-static/resources/fchomo.js
# shaka audio
sed -i "s|audio/x-wav|audio/mpeg|;
		s|'UklGRiQAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQAAAAA='|'$(base64 "$CURDIR/docs/$SHARKAUDIO" | tr -d '\n')'|" \
"$PKG_BUILD_DIR"/htdocs/luci-static/resources/fchomo.js
# shaka gif
echo -n "'" > "$PKG_BUILD_DIR"/base64
base64 "$CURDIR/docs/$SHARKIMG" | tr -d '\n' >> "$PKG_BUILD_DIR"/base64
echo "'" >> "$PKG_BUILD_DIR"/base64
p=$(sed -n "/'c2hhcmstdGFpa28uZ2lm'/=" "$PKG_BUILD_DIR"/htdocs/luci-static/resources/fchomo.js)
{
head -n$(( $p -1 )) "$PKG_BUILD_DIR"/htdocs/luci-static/resources/fchomo.js
cat "$PKG_BUILD_DIR"/base64
tail -n +$(( $p +1 )) "$PKG_BUILD_DIR"/htdocs/luci-static/resources/fchomo.js
} > "$PKG_BUILD_DIR"/htdocs/luci-static/resources/fchomo.js.new
mv -f "$PKG_BUILD_DIR"/htdocs/luci-static/resources/fchomo.js.new "$PKG_BUILD_DIR"/htdocs/luci-static/resources/fchomo.js

if [ -d "$CURDIR/.git" ]; then
	config="$CURDIR/.git/config"
else
	config="$(sed "s|^gitdir:\s*|$CURDIR/|;s|$|/config|" "$CURDIR/.git")"
fi
[ -n "$(sed -En '/^\[remote /{h;:top;n;/^\[/b;s,(https?://gitcode\.(com|net)),\1,;T top;H;x;s|\n\s*|: |;p;}' "$config")" ] && {
	for d in luasrc ucode htdocs root src; do
		rm -rf "$PKG_BUILD_DIR"/$d
	done
	mkdir -p "$PKG_BUILD_DIR"/htdocs/luci-static/resources/view
	touch "$PKG_BUILD_DIR"/htdocs/luci-static/resources/view/$PKG_NAME.js
	mkdir -p "$PKG_BUILD_DIR"/root/usr/share/luci/menu.d
	touch "$PKG_BUILD_DIR"/root/usr/share/luci/menu.d/$PKG_NAME.json
}
exit 0
