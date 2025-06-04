#!/bin/bash

commit=true

# Path to urls.cfg will come from private repo clone
urlsConfig="private-config/urls.cfg"

echo "Reading $urlsConfig"
declare -a KEYSARRAY
declare -a URLSARRAY
while IFS='=' read -r key url
do
  # skip empty lines or comments
  [[ -z "$key" || "$key" == \#* ]] && continue
  echo "  $key=$url"
  KEYSARRAY+=("$key")
  URLSARRAY+=("$url")
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

mkdir -p status

for (( index=0; index < ${#KEYSARRAY[@]}; index++ ))
do
  key="${KEYSARRAY[index]}"
  url="${URLSARRAY[index]}"
  echo "  $key=$url"

  for i in {1..3}
  do
    response=$(curl -o /dev/null -s -w '%{http_code} %{time_total}' --silent --output /dev/null "$url")
    http_code=$(echo "$response" | cut -d ' ' -f 1)
    time_total=$(echo "$response" | cut -d ' ' -f 2)
    echo "    $http_code $time_total"
    if [[ "$http_code" =~ ^(200|202|301|302|307)$ ]]; then
      result="success"
      break
    else
      result="failed"
    fi
    sleep 5
  done
  dateTime=$(date +'%Y-%m-%d %H:%M')
  if [[ $commit == true ]]
  then
    echo "$dateTime, $result, $time_total" >> "status/${key}_report.log"
    tail -2000 "status/${key}_report.log" > "status/${key}_report.log.tmp"
    mv "status/${key}_report.log.tmp" "status/${key}_report.log"
  else
    echo "    $dateTime, $result, $time_total"
  fi
done
