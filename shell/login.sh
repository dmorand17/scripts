#!/bin/bash

if [ x"$AUTH_ENDPOINT" = x ] ; then
    echo "AUTH_ENDPOINT is not exported."
    exit 1
fi

x=$(curl -sSL -k --data "grant_type=client_credentials" -H "Authorization: Basic $BASIC_AUTH_USERNAME_PASSWORD" -H "Content-Type: application/x-www-form-urlencoded" $AUTH_ENDPOINT| jq '.["access_token"]')
export bearer=${x//\"/}
echo bearer=$bearer
echo -n $bearer | xsel -b
echo "Copied to clipboard"
