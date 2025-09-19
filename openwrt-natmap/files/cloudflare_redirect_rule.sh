#!/bin/sh

# NATMap
outter_ip=$1
outter_port=$2

get_current_rule() {
    curl --retry 10 --request GET \
    --url https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/rulesets/phases/http_request_dynamic_redirect/entrypoint \
    --header "X-Auth-Key: $CLOUDFLARE_API_KEY" \
    --header "X-Auth-Email: $CLOUDFLARE_EMAIL" \
    --header 'Content-Type: application/json'
}

currrent_rule=$(get_current_rule)

CLOUDFLARE_RULE_NAME="\"$CLOUDFLARE_RULE_NAME\""
# replace NEW_PORT with outter_port 
CLOUDFLARE_RULE_TARGET_URL=$(echo $CLOUDFLARE_RULE_TARGET_URL | sed 's/NEW_PORT/'"$outter_port"'/g')
new_rule=$(echo "$currrent_rule" | jq '.result.rules| to_entries | map(select(.value.description == '"$CLOUDFLARE_RULE_NAME"')) | .[].key')
new_rule=$(echo "$currrent_rule" | jq '.result.rules['"$new_rule"'].action_parameters.from_value.target_url.value = "'"$CLOUDFLARE_RULE_TARGET_URL"'"')

CLOUDFLARE_RULESET_ID=$(echo "$currrent_rule" | jq '.result.id' | sed 's/"//g')

body=$(echo "$new_rule" | jq '.result')
# delete last_updated
body=$(echo "$body" | jq 'del(.last_updated)')
curl --retry 10 --request PUT \
  --url https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/rulesets/$CLOUDFLARE_RULESET_ID \
  --header "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  --header "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  --header 'Content-Type: application/json' \
  --data "$body"