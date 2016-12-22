#!/usr/bin/env bash

# This script performs the following actions:
#	* Route all nodes returned from the route53 script through the VPN connection


# Example of how to retrieve an IP address (after running route_53upsert)
#	frontend=$(nslookup frontend1.hbc-douglasm-e6430-graviton.ohop.io 2> /dev/null | sed -n -e '/graviton/,/Address:/p' | awk -n '/^Address: / { print $2}')

# Ensure script exits if any task returns a non-zero
# set -e

######################## FUNCTIONS ########################

exe() { echo "\$ $@" ; "$@" ; }

route_address(){
	# Suppress any errors
	# route add $2 $vpn_ip 2> /dev/null
	
	#echo "Retrieving IP address for $1"
	
	site_ip=$(nslookup $1 2>/dev/null | sed -nr '/Name/,+1s|Address(es)?: *||p')
	#echo "$site_ip [$1]"
	
	echo "Routing $site_ip [$1] -> $vpn_ip"
	
	case "$operating_sys" in
		win)
			# Windows Routing
			route add $site_ip $vpn_ip &> /dev/null
		;;
		nix)
			# Linux Routing
			# route add $ip gw $vpn_ip 2> /dev/null
			# sudo ip route add 99.99.99.99 dev eth0
			# ip route add $ip 255.255.255.255 $vpn_ip 2> /dev/null
			# sudo ip route add $1 dev utun1
			sudo route add $site_ip gw $vpn_ip &> /dev/null
		;;
		mac)
			# Mac Routing
			# route add $ip gw $vpn_ip 2> /dev/null
			# sudo route add -host 54.35.189.129 -interface utun0
			sudo route add -host $site_ip -interface $vpn_ip &> /dev/null
		;;
		
	esac
	
	if [ "$?" -ne "0" ]; then
		echo -e "Unable to route $1 -> $vpn_ip"
		echo -e "Check to ensure the terminal is running with Admin privilege"
		exit 1
	fi
}

######################## END FUNCTIONS ########################


########################### MAIN ##############################

if [[ $# -ne 2 ]]
then
    echo "There are not enough parameters."
    
	echo "Must provide the following parameters:"
	echo "	* Client to build routing for"
	echo "	* VPN network identifier (retrieved from running netstat -nr and review the Interface List)"
	echo
	echo "  Example: aws-client-tunnel.sh 'hbc' 'Scottsdale VPN'"
	
    exit 1
fi
echo
echo "==================================================================================================="
echo "                                         AMADEUS TUNNEL                                            "
echo "==================================================================================================="
echo 
#echo -n "Operating system: "

# Additional logic to route based on OS
case "$(uname -s)" in
   Darwin)
     #echo 'Mac OS X'
	 operating_sys='mac'
     ;;
   Linux)
     #echo 'Linux'
	 operating_sys='nix'
     ;;
   CYGWIN*|MINGW*|MSYS*)
     #echo 'MS Windows'
	 operating_sys='win'
     ;;
   # Add here more strings to compare
   # See correspondence table at the bottom of this answer
   *)
     #echo 'other OS' 
	 echo 'Unable to determine Operating system, exiting...'
	 exit 1
     ;;
esac

hostname=$(hostname)

client=$1
vpn_location=$2

vpn_ip=$(netsh interface ipv4 show addresses "$vpn_location" | sed -n -e 's/IP Address://p' | sed -e 's/ //g')

if [[ -z "$vpn_ip" ]]; then
	echo "Unable to retrieve IP address from $vpn_location, exiting..."
	exit 1
fi

# Loop over the list of shared_db ip addresses and route them
hbc_hostnames=("hbcint.orionhealthcloud.com")

echo
echo "==================================================================================================="
echo "Building Tunneling to $1 via $2"
echo "==================================================================================================="
echo
echo "$vpn_location address: $vpn_ip"
echo
echo "-----------------------------------"
echo "Routing Instances..."
echo "-----------------------------------"

for ip in "${hbc_hostnames[@]}"; do
	route_address $ip horizon_host
	# echo "$ip"
done

# Route jumphost
jumphost="jump1.us-west-2.orionhealth-saas-mgmt.com"
route_address $jumphost jumphost

########################### END MAIN ##############################