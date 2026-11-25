#!/bin/sh
# npm invokes this adapter explicitly; arbitrary lifecycle HTTP downloads keep
# their own destinations. Git URL and command classification belong to ks-cli.
if [ "${OPENCLAWMGR_ACCELERATED:-0}" = 1 ]; then
	exec ks-cli git "$@"
fi
exec git "$@"
