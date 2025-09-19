#!/bin/sh

# NATMap
outter_ip=$1
outter_port=$2


current_cfg=$(curl --retry 10 -v $EMBY_URL/emby/System/Configuration?api_key=$EMBY_API_KEY)
new_cfg=$current_cfg
if [ ! -z $EMBY_USE_HTTPS ] && [ $EMBY_USE_HTTPS = '1' ]; then
    new_cfg=$(echo $current_cfg | jq ".PublicHttpsPort = $outter_port")
else
    new_cfg=$(echo $current_cfg | jq ".PublicPort = $outter_port")
fi

if [ ! -z $EMBY_UPDATE_HOST_WITH_IP ] && [ $EMBY_UPDATE_HOST_WITH_IP = '1' ]; then
    new_cfg=$(echo $new_cfg | jq ".WanDdns = \"$outter_ip\"")
fi

curl --retry 10 -X POST "$EMBY_URL/emby/System/Configuration?api_key=$EMBY_API_KEY" -H "accept: */*" -H "Content-Type: application/json" -d "$new_cfg"
