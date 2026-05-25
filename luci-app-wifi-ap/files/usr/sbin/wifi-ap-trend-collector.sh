#!/bin/sh
# 每分钟采集一次AP性能数据，写入/etc/wifi-ap/trend.json，并ubus推送
TREND_JSON="/etc/wifi-ap/trend.json"
mkdir -p /etc/wifi-ap

while true; do
  NOW=$(date "+%Y-%m-%d %H:%M")
  CPU=$(top -bn1 | grep 'CPU:' | awk '{print int($2)}')
  MEM=$(free | awk '/Mem:/ {printf("%.0f", $3/$2*100)}')
  CLIENTS_24G=$(iwinfo | grep -A10 'ESSID' | grep '2.4GHz' | wc -l)
  CLIENTS_5G=$(iwinfo | grep -A10 'ESSID' | grep '5GHz' | wc -l)
  SIGNAL=$(iwinfo | grep 'Signal' | awk '{print $2}' | head -n1)
  TMP="/tmp/trend_tmp.json"
  [ -f "$TREND_JSON" ] && cp "$TREND_JSON" "$TMP" || echo "{}" > "$TMP"
  jq --arg t "$NOW" --argjson cpu "$CPU" --argjson mem "$MEM" --argjson c24 "$CLIENTS_24G" --argjson c5 "$CLIENTS_5G" --argjson sig "$SIGNAL" \
    '. + {($t): {"cpu":$cpu,"mem":$mem,"clients_24g":$c24,"clients_5g":$c5,"signal":$sig}}' "$TMP" > "$TREND_JSON"
  # 主动推送ubus事件，便于WebSocket实时推送
  if command -v ubus >/dev/null 2>&1; then
    ubus send wifi-ap.trend_update "{\"time\":\"$NOW\",\"cpu\":$CPU,\"mem\":$MEM,\"clients_24g\":$CLIENTS_24G,\"clients_5g\":$CLIENTS_5G,\"signal\":$SIGNAL}"
  fi
  sleep 60
done
