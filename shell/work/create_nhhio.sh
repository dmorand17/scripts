#!/bin/bash

### PARAMETERS ###
DOMAIN=$1
STATE=$2
CITY=$3
ORGANIZATION=$4
EMAIL=$5


createCert() {
	# create environment variable containing CN from command to allow it to be used to automatically set the DNS alternative name
	export CN=$DOMAIN

	# output location for certificates
	OUTPUT_LOCATION="./certs/$DOMAIN"
	mkdir $OUTPUT_LOCATION

	# generate password for key
	openssl rand -base64 12 > "$OUTPUT_LOCATION/$DOMAIN.pass"

	# additional configuration for process located in config file (config/direct.cnf)
	# create key request using details entered on command line
	openssl req -newkey rsa:2048 -subj "/C=US/ST=$STATE/L=$CITY/O=$ORGANIZATION/CN=$DOMAIN/subjectAltName=$DOMAIN/emailAddress=$EMAIL" -keyout "$OUTPUT_LOCATION/$DOMAIN.key" -nodes -config config/direct.cnf -out "$OUTPUT_LOCATION/$DOMAIN.req"

	# use request to create certificate/key signed with NH-HIO leaf certificate
	openssl ca  -policy direct_policy -extensions direct_org_cert -config config/direct.cnf -out "$OUTPUT_LOCATION/$DOMAIN.crt" -infiles "$OUTPUT_LOCATION/$DOMAIN.req"

	# export certificate as binary DER file
	openssl x509 -inform pem -in "$OUTPUT_LOCATION/$DOMAIN.crt" -outform der -out "$OUTPUT_LOCATION/$DOMAIN.der"

	# export certificate/key as p12
	openssl pkcs12 -export -in "$OUTPUT_LOCATION/$DOMAIN.crt" -inkey "$OUTPUT_LOCATION/$DOMAIN.key" -out "$OUTPUT_LOCATION/$DOMAIN.p12" -passout file:"$OUTPUT_LOCATION/$DOMAIN.pass"

	# export key as base64 encoded file
	openssl enc -e -a -in "$OUTPUT_LOCATION/$DOMAIN.p12" -out "$OUTPUT_LOCATION/$DOMAIN.p12.base64"
}


printusage() {
cat << "EOFUSAGE"
Usage:
$0 DOMAIN STATE CITY ORGANIZATION EMAIL
 Parameters:
 - DOMAIN: direct compliant domain name for organization
 - STATE: state where organization is located
 - CITY: city where organization is located
 - ORGANIZATION: organization name
 - EMAIL: email address for certificate generation, not used beyond generation
EOFUSAGE
}

######   MAIN    ######

if [[ $# -ne 5 ]]
then
    echo "There are not enough parameters."
    printusage
    exit 1
fi

echo "Started"
createCert
echo "Completed"