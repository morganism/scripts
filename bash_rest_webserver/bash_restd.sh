#!/bin/bash

PORT=8081

rm -f HTTP_PIPE
mkfifo HTTP_PIPE
trap "rm -f HTTP_PIPE" EXIT
while true
do
  cat HTTP_PIPE | nc -l $PORT > >( 
    export HTTP_REQUEST=
    while read input
    do
      input=$(echo "$input" | tr -d '[\r\n]')

      if echo "$input" | grep -qE '^GET /' 
      then
        HTTP_REQUEST=$(echo "$input" | awk '{print $2}') # get the request part
      elif [ "x$input" = x ] # empty .. EOR
      then
        HTTP_STATUS_200="HTTP/1.1 200 OK"
        HTTP_REQ_LOC="Target:"
        HTTP_STATUS_404="HTTP/1.1 404 Not Found"

        # SCRIPT HERE

        if echo $HTTP_REQUEST | grep -qE '^/echo/'
        then
            printf "%s\n%s %s\n\n%s\n" "$HTTP_STATUS_200" "$HTTP_REQ_LOC" $HTTP_REQUEST ${HTTP_REQUEST#"/echo/"} > HTTP_PIPE
        elif echo $HTTP_REQUEST | grep -qE '^/help'
        then
            echo "Supported targets: /help /echo/something /src" > HTTP_PIPE
        elif echo $HTTP_REQUEST | grep -qE '^/src'
        then
            cat $0 > HTTP_PIPE
        else
            printf "%s\n%s %s\n\n%s\n" "$HTTP_STATUS_404" "$HTTP_REQ_LOC" $HTTP_REQUEST "Resource $HTTP_REQUEST NOT FOUND!" > HTTP_PIPE
        fi
      fi
    done
  )
done
