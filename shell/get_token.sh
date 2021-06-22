#!/bin/sh
curl -sSL -k --data "grant_type=client_credentials" -H "Authorization: Basic $BASIC_AUTH_USERNAME_PASSWORD" -H "Content-Type: application/x-www-form-urlencoded" $AUTH_ENDPOINT | jq '.["access_token"]' | xargs echo -n
