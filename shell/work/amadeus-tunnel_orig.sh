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
#	frontend=$(nslookup frontend1.hbc-douglasm-e6430-graviton.ohop.io 2>NUL | sed -n -e '/graviton/,/Address:/p' | awk -n '/^Address: / { print $2}')

# Modify this value to 
hostname=$(hostname)

# Testing 
# hostname=testing

solution=$1
vpn_location=$2

#vpn_location='Scottsdale VPN'
vpn_ip=$(netsh interface ipv4 show addresses "$vpn_location" | sed -n -e 's/IP Address://p' | sed -e 's/ //g')

# puppet-master-0.22.0
puppet_master='52.24.170.150'
# puppet-master-0.18.0
puppet_master_018='52.25.122.161'

# shared.cv2quofa3aoc.us-west-2.rds.amazonaws.com
shared_db='52.27.229.29'

######################## FUNCTIONS ########################
route_address(){
	ip=$(nslookup $1.$solution-$hostname-graviton.ohop.io 2> /dev/null | sed -n -e '/graviton/,/Address:/p' | awk -n '/^Address: / { print $2}')
	
	if [[ -z "$ip" ]]; then
		echo "Unable to retrieve hostname '$1.$solution-$hostname-graviton-ohop-io'.  Check your hostname(s) returned from your route_53upsert script"
		return 1
	fi

	# Suppress any errors
	# route add $2 $vpn_ip 2> /dev/null

	echo "Routing $1 $ip -> $vpn_ip"
	
	# Windows Routing
	route add $ip $vpn_ip 2> /dev/null
	
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
    
	echo "Must provide a solution (ie: directory)"
	echo "  Example: amadeus-tunnel.sh 'ohop' 'Scottsdale VPN'"
	
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
echo "-----------------------------------"
echo "Routing addresses..."
echo "-----------------------------------"
route_address frontend1
route_address backend1
route_address empi1
route_address haproxy1
route_address rhapsody-ohop1
route_address rhapsody-sitespecific1