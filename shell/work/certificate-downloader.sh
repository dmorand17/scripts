#!/bin/sh
#
# usage: retrieve-cert.sh remote.host.name [port]
#
REMHOST=$1
REMPORT=${2:-443}

echo "Downloading certificate chain for $REMHOST:$REMPORT"

## echo -n | openssl s_client -connect webservice.wchnhie.org:9082 -showcerts | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | awk '/BEGIN CERTIFICATE-/ {x="certificate"++i".cer";} {print > x;}'

echo |\
openssl s_client -connect ${REMHOST}:${REMPORT} -showcerts 2>&1 |\
sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' |\
awk '/BEGIN CERTIFICATE-/ {certfile="certificate"++i".cer";} {print > certfile;}'

echo "Finished downloading certificates..."