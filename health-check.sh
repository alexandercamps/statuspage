#!/bin/bash

# In the original repository we'll just print the result of status checks,
# without committing. This avoids generating several commits that would make
# later upstream merges messy for anyone who forked us.
KEYSARRAY=()
URLSARRAY=()
IFS='=' 

urlsConfig="./urls.cfg"
echo "Reading $urlsConfig"
while read -r line
do
  echo "  $line"
  read -a TOKENS <<< "$line"
  KEYSARRAY+=(${TOKENS[0]})
  URLSARRAY+=(${TOKENS[1]})
done < "$urlsConfig"

echo "***********************"
echo "Starting health checks with ${#KEYSARRAY[@]} configs:"

mkdir -p logs

#RUNNING_FILE="/var/www/html/statuspage-running"
RUNNING_FILE="/f/Projetos/Frenet/src/statuspage/statuspage-running"
while [ -f $RUNNING_FILE ];
do
  for (( index=0; index < ${#KEYSARRAY[@]}; index++))
  do
    key="${KEYSARRAY[index]}"
    url="${URLSARRAY[index]}"
    echo "  $key=$url"

    for i in 1 2 3 4; 
    do
      response=$(curl --write-out '%{http_code}' --silent --output /dev/null $url)
      if [ "$response" -eq 200 ] || [ "$response" -eq 202 ] || [ "$response" -eq 301 ] || [ "$response" -eq 307 ]; then
        result="success"
      else
        result="failed"
      fi
      if [ "$result" = "success" ]; then
        break
      fi
      sleep 5
    done # for retries 4 time
    dateTime=$(date +'%Y-%m-%d %H:%M')
    echo $dateTime, $result >> "logs/${key}_report.log"
    echo "    $dateTime, $result"  
  done

  echo "Waiting for 60 seconds until next health check"
  sleep 60 # waiting for 60 seconds, after try again
done # while true end
