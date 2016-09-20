#!/bin/bash

currdir=$pwd

echo "User Home: $USERPROFILE"

cd "$USERPROFILE\ohop\graviton-cli-vm"
echo "Current directory: $pwd"

vagrant up

# SSH into vagrant vm
ssh -p 2222 vagrant@localhost

# Change back to regular directory once completed
cd "$currdir"

printusage() {
cat << "EOFUSAGE"
Usage:
$0 DOMAIN STATE CITY ORGANIZATION EMAIL
 Parameters:
 - DOMAIN: direct compliant domain name for organization
 - EMAIL: email address for certificate generation, not used beyond generation
EOFUSAGE
}