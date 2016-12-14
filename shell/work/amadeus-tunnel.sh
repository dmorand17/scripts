#!/usr/bin/env bash

# This script performs the following actions:
#	* Resume solution (if necessary)
#	* Run route53_upsert script
#	* Route all nodes returned from the route53 script through the VPN connection

# This script will setup routing for all nodes deployed as part of the solution:
# Example nodes:
# 	frontend
# 	backend
# 	haproxy
# 	rhapsody_ss
# 	rhapsody_opi
# 	empi


# Example of how to retrieve an IP address (after running route_53upsert)
#	frontend=$(nslookup frontend1.hbc-douglasm-e6430-graviton.ohop.io 2> /dev/null | sed -n -e '/graviton/,/Address:/p' | awk -n '/^Address: / { print $2}')

# Ensure script exits if any task returns a non-zero
# set -e

######################## FUNCTIONS ########################

route_address(){
	# Suppress any errors
	# route add $2 $vpn_ip 2> /dev/null

	echo "Routing $1 [$2] -> $vpn_ip"

	case "$operating_sys" in
		win)
			# Windows Routing
			route add $1 $vpn_ip &> /dev/null
		;;
		nix)
			# Linux Routing
			# route add $ip gw $vpn_ip 2> /dev/null
			# sudo ip route add 99.99.99.99 dev eth0
			# ip route add $ip 255.255.255.255 $vpn_ip 2> /dev/null
			# sudo ip route add $1 dev utun1
			sudo route add $1 gw $vpn_ip &> /dev/null
		;;
		mac)
			# Mac Routing
			# route add $ip gw $vpn_ip 2> /dev/null
			# sudo route add -host 54.35.189.129 -interface utun0
			sudo route add -host $1 -interface $vpn_ip &> /dev/null
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
	echo "	* solution directory on jumphost"
	echo "	* VPN network identifier (retrieved from running netstat -nr and review the Interface List)"
	echo
	echo "  Example: amadeus-tunnel.sh 'rgrav/solution_ohop_username' 'Scottsdale VPN'"

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

# Testing
# hostname=testing

solution=$1
vpn_location=$2

#vpn_location='Scottsdale VPN'
vpn_ip=$(netsh interface ipv4 show addresses "$vpn_location" | sed -n -e 's/IP Address://p' | sed -e 's/ //g')

if [[ -z "$vpn_ip" ]]; then
	echo "Unable to retrieve IP address from $vpn_location, exiting..."
	exit 1
fi

# puppet-master-0.22.0
# Dynamically retrieves puppet master from the graviton configuration for the deployment
puppet_master=$(ssh graviton-jump-host -- "cd ~/$solution; graviton config -p ec2 | sed -n 's/^.*puppet.master.address=//p'")


# shared.cv2quofa3aoc.us-west-2.rds.amazonaws.com
# Loop over the list of shared_db ip addresses and route them
shared_db=("52.27.229.29" "52.40.148.225" "52.42.9.133")
shared_db_hostnames=("shared-12c.cv2quofa3aoc.us-west-2.rds.amazonaws.com")

# Add to shared_db array
for i in "${shared_db_hostnames[@]}"; do
	echo -n "Resolving ip for $i"
	ip=$(nslookup $i 2>/dev/null | sed -nr '/Name/,+1s|Address(es)?: *||p')
	echo " ip: $ip"
	shared_db+=($ip)
done

echo
echo "==================================================================================================="
echo "Building AWS Tunneling to $1 via $2"
echo "==================================================================================================="
echo
echo "$vpn_location address: $vpn_ip"
echo
echo "-----------------------------------"
echo "Routing shared instances..."
echo "-----------------------------------"
route_address $puppet_master puppet_master

for ip in "${shared_db[@]}"; do
	route_address $ip shared_database
	# echo "$ip"
done

echo
echo "Checking if solution running..."

ssh graviton-jump-host -- "cd ~/$solution; graviton status -p ec2" > graviton-status.tmp
graviton_status=$(cat graviton-status.tmp | sed -n -e 's/Status: //p' | sed s/\ //g | head -1)

echo "Environment status: $graviton_status"
echo
if [ "$graviton_status" != "Running" ]; then
	echo "Running graviton resume..."
	ssh graviton-jump-host -- "cd ~/$solution; graviton resume -p ec2" > /dev/null
fi

echo "Running route53_upsert..."
ssh graviton-jump-host -- "cd ~/$solution; ./resources/scripts/route53_upsert" > route53_upsert.tmp

echo
echo "-----------------------------------"
echo "Routing addresses..."
echo "-----------------------------------"

#cat route53_upsert.tmp | sed -n -e '/Public Zone/,/Route53/p' | awk -F" " '{print $0}' | awk '/^[0-9]/' | awk -F" " '{cmd="echo running " $1 " on " $2; system(cmd)}'

# Retrieve the public IP / hostname from route53_upsert
solution_nodes=$(cat route53_upsert.tmp | sed -n -e '/Public Zone/,/Route53/p' | awk -F" " '{print $0}' | awk '/^[0-9]/' | awk -F" " '{print $1,$2}')

# Setup routing for ALL hosts retrieved from route53_upsert script
IFS=$'\n'
for node in $solution_nodes; do
	ip=$(echo "$node" | cut -d' ' -f1)
	hostname=$(echo "$node" | cut -d' ' -f2)

	route_address $ip $hostname
done

rm route53_upsert.tmp
# graviton-status.tmp

########################### END MAIN ##############################
