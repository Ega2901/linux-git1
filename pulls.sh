#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <github_username>"
  exit 1
fi

USER=$1
REPO="datamove/linux-git2"
API_URL="https://api.github.com/repos/$REPO/pulls"
MERGED_FLAG=0

function get_data {
  curl -s -H "Accept: application/vnd.github.v3+json" -G --data-urlencode "state=all" --data-urlencode "sort=created" --data-urlencode "direction=asc" --data-urlencode "page=$1" --data-urlencode "per_page=100" "$API_URL"
}

TOTAL_PAGES=$(get_data 1 | jq '. | length')

PULLS=0

for ((i=1; i<=$TOTAL_PAGES; i++)); do
  DATA=$(get_data $i)

  PULLS=$((PULLS + $(echo "$DATA" | jq --arg USER "$USER" '[.[] | select(.user.login == $USER)] | length')))

  if [ $MERGED_FLAG -eq 0 ]; then
    EARLIEST=$(echo "$DATA" | jq --arg USER "$USER" '[.[] | select(.user.login == $USER)] | first?.number')
    if [ ! -z "$EARLIEST" ]; then
      MERGED=$(echo "$DATA" | jq --arg EARLIEST "$EARLIEST" '.[] | select(.number == $EARLIEST).merged')
      if [ "$MERGED" == "true" ]; then
        MERGED_FLAG=1
      fi
    fi
  fi
done

echo "PULLS $PULLS"

echo "EARLIEST $EARLIEST"

echo "MERGED $MERGED_FLAG"

