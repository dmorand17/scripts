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

usage(){
	echo "Usage: $(basename $0) -s <solution directory> -n <vpn name>"
    echo ""
	echo "  -h --help         Display help"
	echo "  -s --solution     Solution folder on jumphost (e.g. solutions/solution_hbc_douglasm)"
	echo "  -n --vpn          VPN Name (found from i[pf]config or netstat -rn)"
	echo "  -d --direct       Setup aws-direct client environment routing (NOT IMPLEMENTED YET)"
	echo ""
	echo "Example: $(basename $0) -s solutions/solution_hbc_douglasm -n 'Scottsdale VPN'"
	echo 
}

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
			sudo route add -host $1 -interface utun0 &> /dev/null
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

# Retrieve these from arguments
solution=""
vpn=""
aws_direct=0

if ! [[ $# -ge 4 ]]; then
	echo "Incorrect number of arguments: $#"
	usage
    exit 1
fi

# Parse out the arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            usage
            exit
            ;;
        -s | --solution)
            solution="$2"
			shift # shift over because we read out 2 values (parameter + value)
            ;;
        -n | --vpn)
            vpn="$2"
			shift
            ;;
		-d | --direct)
			aws_direct=1
			;;
		--) # End of all options
			shift
			break
			;;
		-*)
			echo "Error: Unknown option: $1" >&2
			exit 1
			;;
		*)	# No more options
			break
            ;;
    esac
    shift
done

if [[ ( $# == "--help") ||  $# == "-h" ]]; then 
	usage
	exit 0
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

#vpn='Scottsdale VPN'
if [[ $operating_sys -eq "win" ]]; then
	# echo "Retrieving IP address from windows..."
	vpn_ip=$(netsh interface ipv4 show addresses "$vpn" | sed -n -e 's/IP Address://p' | sed -e 's/ //g')
else
	vpn_ip="tun0"
fi

if [[ -z "$vpn_ip" ]]; then
	echo "Unable to retrieve IP address from $vpn_location, exiting..."
	exit 1
fi

# puppet-master-0.22.0
# Dynamically retrieves puppet master from the graviton configuration for the deployment
puppet_master=$(ssh graviton-jump-host -- "cd ~/$solution; graviton config -p ec2 | sed -n 's/^.*puppet.master.address=//p'")


# shared.cv2quofa3aoc.us-west-2.rds.amazonaws.com
# Loop over the list of shared_db ip addresses and route them
#shared_db=("52.27.229.29" "52.40.148.225" "52.42.9.133")
shared_db=()
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
echo "Building AWS Tunneling to $solution via $vpn"
echo "==================================================================================================="
echo
echo "$vpn address: $vpn_ip"
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

#ssh graviton-jump-host -- "cd ~/$solution; graviton status -p ec2" > graviton-status.tmp
graviton_status=$(ssh graviton-jump-host -- "cd ~/$solution; graviton status -p ec2" | sed -n -e 's/Status: //p' | sed s/\ //g | head -1)
#graviton_status=$(cat graviton-status.tmp | sed -n -e 's/Status: //p' | sed s/\ //g | head -1)

echo "Environment status: $graviton_status"
echo
if [ "$graviton_status" != "Running" ]; then
	echo "Running graviton resume..."
	ssh graviton-jump-host -- "cd ~/$solution; graviton resume -p ec2" > /dev/null
fi

echo "Retrieving solution nodes from graviton..."
ssh graviton-jump-host -- "cd $solution; graviton status -p ec2" | grep -A 4 --group-separator="++++++++" 'graviton.odl.io' | awk 'BEGIN {FS="\n"; RS="+++++\n"} { gsub(/^[ \t]*/,"",$1); gsub(/^[ \t]*Public IP: /,"",$5)} {print $1,$5}' > graviton_status.tmp

# Removing esc sequences that graviton puts in the output
sed -i 's/.*  //g' graviton_status.tmp

echo
echo "-----------------------------------"
echo "Routing addresses..."
echo "-----------------------------------"


# Retrieve the public IP / hostname from graviton_status
solution_nodes=$(cat graviton_status.tmp | awk -F" " '{print $1,$2}')

# Setup routing for ALL hosts retrieved from graviton status
IFS=$'\n'
for node in $solution_nodes; do
	hostname=$(echo "$node" | cut -d' ' -f1)
	ip=$(echo "$node" | cut -d' ' -f2)
	
	route_address $ip $hostname
done

rm graviton_status.tmp

########################### END MAIN ##############################
