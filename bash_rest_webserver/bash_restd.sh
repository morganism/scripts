#!/bin/bash

PORT=8081

rm -f HTTP_PIPE
mkfifo HTTP_PIPE
trap "rm -f HTTP_PIPE" EXIT
while true
do
  cat HTTP_PIPE | nc -l $PORT > >( 
    export HTTP_REQUEST=
    while read line
    do
      line=$(echo "$line" | tr -d '[\r\n]')

      if echo "$line" | grep -qE '^GET /' 
      then
        HTTP_REQUEST=$(echo "$line" | cut -d ' ' -f2) # get the request part
      elif [ "x$line" = x ] # empty .. EOR
      then
        HTTP_STATUS_200="HTTP/1.1 200 OK"
        HTTP_REQ_LOC="REST Loc:"
        HTTP_STATUS_404="HTTP/1.1 404 Not Found"

        # ANY SCRIPT HERE

        if echo $HTTP_REQUEST | grep -qE '^/echo/'
        then
            printf "%s\n%s %s\n\n%s\n" "$HTTP_STATUS_200" "$HTTP_REQ_LOC" $HTTP_REQUEST ${HTTP_REQUEST#"/echo/"} > HTTP_PIPE
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
