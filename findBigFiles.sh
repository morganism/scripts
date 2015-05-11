#!/bin/bash
MEGS=$1
find . -type f -size +${MEGS}000k -exec ls -lh {} \; | awk '{ print $9 ": " $5 }'
