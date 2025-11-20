#!/bin/sh

cd /
umount -R $2 || umount -l $2
umount -l /tmp/busy

if echo "$1" | grep -q '^/dev/' ; then
	/bin/sh -i </dev/console >/dev/console 2>&1 &
fi

echo "exec /sbin/init" >&2

export -n TZ SHLVL HOSTNAME OLDPWD PWD USER LOGNAME
unset TZ SHLVL HOSTNAME OLDPWD PWD USER LOGNAME

export HOME=/ TERM=linux PATH=/sbin:/bin

exec /sbin/init </dev/null

