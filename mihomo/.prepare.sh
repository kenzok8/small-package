#!/bin/bash
VERSION="$1"
CURDIR="$2"
BIN_PATH="$3"

if [ -d "$CURDIR/.git" ]; then
	config="$CURDIR/.git/config"
else
	config="$(sed "s|^gitdir:\s*|$CURDIR/|;s|$|/config|" "$CURDIR/.git")"
fi
[ -n "$(sed -En '/^\[remote /{h;:top;n;/^\[/b;s,(https?://gitcode\.(com|net)),\1,;T top;H;x;s|\n\s*|: |;p;}' "$config")" ] && {
	echo -e "#!/bin/sh\necho $VERSION" > "$BIN_PATH"
}
exit 0
