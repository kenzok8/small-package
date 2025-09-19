#!/bin/sh

text="$1"
token=$2

curl --retry 10 -4 -Ss -X POST \
-H 'Content-Type: application/json' \
-d '{"token": "'"${IM_NOTIFY_CHANNEL_PUSHPLUS_TOKEN}"'", "content": "'"${text}"'", "title": "NATMap"}' \
"http://www.pushplus.plus/send"

if [ $? -eq 0 ]; then
  echo "Send pushplus success"
else
  echo "Send pushplus failed"
  exit 1
fi