#!/bin/sh

if [ -f /usr/share/clashbackup/history ];then

HISTORY_PATH="/usr/share/clashbackup/history"
SECRET=$(uci get clashoo.config.dash_pass 2>/dev/null)
LAN_IP=$(uci get network.lan.ipaddr 2>/dev/null |awk -F '/' '{print $1}' 2>/dev/null)
PORT=$(uci get clashoo.config.dash_port 2>/dev/null)
urlencode() {
    if [ "$#" != 1 ]; then
        return 1
    fi
    printf '%s' "$1" | hexdump -v -e '1/1 "%u "' | awk '
        {
            for (i = 1; i <= NF; i++) {
                b = $i + 0
                if ((b >= 48 && b <= 57) || (b >= 65 && b <= 90) ||
                    (b >= 97 && b <= 122) || b == 45 || b == 46 ||
                    b == 95 || b == 126)
                    printf "%c", b
                else
                    printf "%%%02X", b
            }
        }'
}
cat $HISTORY_PATH |while read line
do
    if [ -z "$(echo $line |grep "#*#")" ]; then
      continue
    else
      GORUP_NAME=$(urlencode "$(echo $line |awk -F '#*#' '{print $1}')")
      NOW_NAME=$(echo $line |awk -F '#*#' '{print $3}')
      curl -H "Authorization: Bearer ${SECRET}" -H "Content-Type:application/json" -X PUT -d '{"name":"'"$NOW_NAME"'"}' http://"$LAN_IP":"$PORT"/proxies/"$GORUP_NAME" >/dev/null 2>&1
    fi
done >/dev/null 2>&1 
curl -m 5 --retry 2 -H "Authorization: Bearer ${SECRET}" -H "Content-Type:application/json" -X DELETE http://"$LAN_IP":"$PORT"/connections >/dev/null 2>&1   
fi
