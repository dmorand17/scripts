#!/usr/bin/env bash

# This script will setup routing 

# Servers to setup routing on
# 	frontend
# 	backend
# 	haproxy
# 	rhapsody_ss
# 	rhapsody_opi
# 	empi

# Example of how to retrieve an IP address (after running route_53upsert)
#	frontend=$(nslookup frontend1.hbc-douglasm-e6430-graviton.ohop.io 2> /dev/null | sed -n -e '/graviton/,/Address:/p' | awk -n '/^Address: / { print $2}')

hostname=$(hostname)

# Testing 
# hostname=testing

solution=$1
vpn_location=$2

#vpn_location='Scottsdale VPN'
vpn_ip=$(netsh interface ipv4 show addresses "$vpn_location" | sed -n -e 's/IP Address://p' | sed -e 's/ //g')

if [[ -z "$vpn_ip" ]]; then
	echo "Unable to retrieve IP address from $vpn_location ... Exiting"
	exit 1
fi

# puppet-master-0.22.0
puppet_master='52.24.170.150'
# puppet-master-0.18.0
puppet_master_018='52.25.122.161'

# shared.cv2quofa3aoc.us-west-2.rds.amazonaws.com
shared_db='52.27.229.29'

######################## FUNCTIONS ########################
route_address(){
	# Suppress any errors
	# route add $2 $vpn_ip 2> /dev/null

	echo "Routing $1 [$2] -> $vpn_ip"
	
	# Windows Routing
	route add $1 $vpn_ip &> /dev/null
	
	# Linux Routing
	# route add $ip gw $vpn_ip 2> /dev/null
	# sudo ip route add 99.99.99.99 dev eth0
	# ip route add $ip 255.255.255.255 $vpn_ip 2> /dev/null
	
	if [ "$?" -ne "0" ]; then
		echo -e "Unable to route $ip -> $vpn_ip"
	fi
}
######################## FUNCTIONS ########################


######################## MAIN ########################
if [[ $# -ne 2 ]]
then
    echo "There are not enough parameters."
    
	echo "Must provide the remote solution directory (ie: rgrav/solution_ohop_username"
	echo "  Example: amadeus-tunnel.sh 'rgrav/solution_ohop_username' 'Scottsdale VPN'"
	
    exit 1
fi
echo "-----------------------------------"
echo "Building VPN routes for $solution"
echo "-----------------------------------"
echo
echo "$vpn_location address: $vpn_ip"
echo
echo "-----------------------------------"
echo "Routing shared instances..."
echo "-----------------------------------"
echo "Routing puppet-master $puppet_master -> $vpn_ip"
route add $puppet_master $vpn_ip 2> /dev/null
echo "Routing shared_db $shared_db -> $vpn_ip"
route add $shared_db $vpn_ip 2> /dev/null
echo
echo "Running route53_upsert remotely..."
ssh graviton-jump-host -- "cd ~/$solution; ./resources/scripts/route53_upsert" > route53_upsert.tmp
echo
echo "-----------------------------------"
echo "Routing addresses..."
echo "-----------------------------------"


echo ""
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