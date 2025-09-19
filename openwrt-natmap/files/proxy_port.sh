#!/bin/sh

outter_port=$2

echo "PROXY_PORT_CONTENT_URL $PROXY_PORT_CONTENT_URL"
content=$(curl --retry 10 -s -L $PROXY_PORT_CONTENT_URL)
if [ -z "$content" ]; then
  echo "Failed to get gist content"
  exit 1
fi

# replace port, placeholder is OUTTER_PORT
content=$(echo "$content" | sed "s/OUTTER_PORT/$outter_port/g")
#replace newline to \n
content=$(echo "$content" | awk '{printf "%s\\n", $0}')
content=$(echo "$content" | sed 's/"/\\"/g')
body="{\"files\": {\"$PROXY_PORT_GIST_FILENAME\": {\"content\": \"$content\"}}}"
# update gist content
url="https://api.github.com/gists/$PROXY_PORT_GIST_ID"
curl --retry 10 -X PATCH \
  -H "Authorization: token $PROXY_PORT_GITHUB_TOKEN" \
  -d "$body" \
  $url >/dev/null

if [ $? -eq 0 ]; then
  echo "Update gist success"
else
  echo "Update gist failed"
  exit 1
fi
