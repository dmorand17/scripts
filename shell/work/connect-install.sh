#!/bin/bash
#
#	CONNECT Certificate Setup Script
#
#	Author: Doug Morand
#	Date:	05/21/2015
#

#set -x # echo on
#set -o # prints shell input as they are read

CURRDIR=$PWD
LOGFILE=$CURRDIR/connect-install.log

#Validate script being ran by root user
user=`whoami`
if [ $user != orion ]; then
     echo "This script must be run as orion"
     exit
 else 
	 echo >> $LOGFILE
fi


#set -e # Exit script if any command fails to run

echo ---------------------------------
echo     CONNECT Certificate Setup    
echo ---------------------------------
echo 
echo "Logging to -> $LOGFILE"

#echo Glassfish installation directory: $AS_HOME

if [[ -z "$AS_HOME" ]]; then
	exit 1
else
	echo Application Home is set [$AS_HOME]
fi

printusage() {
cat << end-of-usage
Usage:
$0 password
: Parameters:
 - PASSWORD: Password of the keystore
end-of-usage
}

# Default,Entered
set(){
	if [[ -n $2 ]]; then
        	echo $2
	else
		echo $1
        fi
}

checkfailure(){
	if [[ $? -ne 0 ]] ; then
		echo "Failure running last command exiting..."
		exit 1
	else
		echo "continuing..."
	fi
}

create-internal-key(){
	# Setup the variables needed to generate the private key

	# Default pw = changeit
	pw="changeit"
	echo 
	echo "Enter the internal keypass/storepass pw > " 
	echo "[changeit]"
	echo -n "> "
	read pwentered

	pw=$(set $pw $pwentered)
	echo "Password: $pw"	

	dname=$HOSTNAME
	echo "Enter the connect hostname"
	echo "[$HOSTNAME]"
	echo -n "> "
	read dnameentered
	
	dname=$(set $dname $dnameentered)
	echo "Domain name=$dname"

        gatewayPassword=""
        echo "Enter the gateway.jks password"
	echo "	Can be found in domain.xml: <system-property name="javax.net.ssl.keyStorePassword" value="exchange"></system-property>"
        echo -n "> "
        read gatewayPassword

	# Verify if the private key is already created and added to gateway.jks
	internalTrust=$(keytool -list -keystore cacerts.jks -keypass $gatewayPassword -storepass $gatewayPassword | grep '^internal.*trustedCertEntry, $')
        internalGateway=$(keytool -list -keystore gateway.jks -keypass $gatewayPassword -storepass $gatewayPassword | grep '^internal.*PrivateKeyEntry, $')
	
        # Check if the internal alias is already in key store
        if [[ -n "$internalGateway"  ]] ; then
                echo "'internal' alias found in gateway.jks exiting..."
		exit 1
        fi

	# Check if the internal alias is already in trust store
	if [[ -n "$internalTrust"  ]] ; then
		echo "internal alias found in cacerts.jks exiting..."	
		exit 1
	fi

	echo 
	# Create self-signed certificate
	echo "creating connect.jks"
	keytool -genkey -keyalg RSA -keysize 1024 -keystore connect.jks -keypass $pw -storepass $pw -validity 730 -alias internal -dname "cn=$dname" 
	echo -e "connect.jks created\n"
	
	# Export the private key to a p12 file
	echo "creating p12"
	keytool -importkeystore -srckeystore connect.jks -destkeystore connect.p12 -deststoretype PKCS12 -srcalias internal -deststorepass $gatewayPassword -destkeypass $gatewayPassword -srckeypass $pw -srcstorepass $pw
	echo -e "p12 created\n"

	# Import p12 into gateway.jks
	echo "importing p12 into gateway.jks"
	keytool -v -importkeystore -srckeystore connect.p12 -srcstoretype PKCS12 -alias internal -destkeystore gateway.jks -deststoretype JKS -deststorepass $gatewayPassword -destkeypass $gatewayPassword -srckeypass $gatewayPassword -srcstorepass $gatewayPassword
	echo -e "p12 imported\n"

	# Export the internal cert
	echo "exporting internal certificate"
	keytool -export -rfc -alias internal -file $dname.cer -keystore gateway.jks -keypass $gatewayPassword -storepass $gatewayPassword
	echo -e "internal certificate exported\n"

	# Import internal certificate
	echo "importing internal certificate into truststore"
	keytool -import -v -trustcacerts -alias internal -noprompt -file $dname.cer -keystore cacerts.jks -storepass $gatewayPassword -keypass $gatewayPassword
	echo -e "internal certificate added to truststore\n"

	# Cleanup files
	echo "Cleaning up installation files..."
	rm connect.jks connect.p12
}

#-----------------------------------------------------
#			MAIN
#-----------------------------------------------------

if [[ $# -ne 1 ]] ; then
	echo Not enough parameters
	printusage
	exit 1

fi

create-internal-key
echo 
echo "Finished!"
