#!/bin/bash

if [ $# -ne 3 ]; then
  cat <<- EOF
    Usage: $0 <title> <priority> <message>
EOF
  exit
fi

curl -s \
  --form-string "token=ac7xvh2zrrmiv6nxqoxgjerm1hsian" \
  --form-string "user=u71pdbtm2a917erqqijm6mkbror2ht" \
  --form-string "title=$1" \
  --form-string "priority=$2" \
  --form-string "message=$3" \
  https://api.pushover.net/1/messages.json