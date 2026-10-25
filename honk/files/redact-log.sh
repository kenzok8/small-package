#!/bin/sh

exec sed -E \
	-e 's#([[:alnum:]+.-]+://)[^[:space:]"<>]+#\1[redacted]#g' \
	-e 's/([Bb]earer[[:space:]]+)[^[:space:],;]+/\1[redacted]/g' \
	-e 's/([Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]|[Tt][Oo][Kk][Ee][Nn]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Aa][Uu][Tt][Hh][Oo][Rr][Ii][Zz][Aa][Tt][Ii][Oo][Nn])[^:=]*[=:][[:space:]]*.*/\1=[redacted]/'
