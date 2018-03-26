#!/bin/bash

p12=$1
p12_name="${p12%%.*}"

echo "p12 file: $p12"
echo "Name: $p12_name"

openssl pkcs12 -in "$p12" -nocerts -out "${p12_name}"-client.key -passin pass:$2 -passout pass:$2
openssl rsa -in "$p12" -out "${p12_name}"-client.key.pem -passin pass:$2 -passout pass:$2
openssl pkcs12 -in "$p12" -clcerts -nokeys  -out "${p12_name}"-client.cer -passin pass:$2 -passout pass:$2
openssl pkcs12 -in "$p12" -cacerts -nokeys  -out "${p12_name}"-cacerts.cer -passin pass:$2 -passout pass:$2