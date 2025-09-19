#!/bin/sh

text="$1"
id=$2
chat_id=$3
token=$4
function curl_proxy() {
    if [ -z "$PROXY" ]; then
        curl --retry 10 "$@"
    else
        curl --retry 10 -x $PROXY "$@"
    fi
}

curl_proxy -4 -Ss -o /dev/null -X POST \
-H 'Content-Type: application/json' \
-d '{"chat_id": "'"${IM_NOTIFY_CHANNEL_TELEGRAM_BOT_CHAT_ID}"'", "text": "'"${text}"'", "parse_mode": "HTML", "disable_notification": "false"}' \
"https://api.telegram.org/bot${IM_NOTIFY_CHANNEL_TELEGRAM_BOT_TOKEN}/sendMessage"

if [ $? -eq 0 ]; then
  echo "Send telegram bot success"
else
  echo "Send telegram bot failed"
  exit 1
fi