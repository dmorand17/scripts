#!/usr/bin/env bash

prefix=$1

echo "Starting tunnel for XXX"
echo "Tunnel Commands:"
echo "    tcheck: check status of tunnel"
echo "    texit:  shutdown tunnel"
#ldap_ip=host unix.stackexchange.com | awk '/has address/ { print $4 }'
rhap_ss_ip=$(dig +short rhapsody-sitespecific1.solution-xxx-douglasm-graviton-jump-host-scottsdale.ohop.io)
rhap_oh_ip=$(dig +short rhapsody-ohop1.solution-xxx-douglasm-graviton-jump-host-scottsdale.ohop.io)
oracle="shared.cv2quofa3aoc.us-west-2.rds.amazonaws.com"

ssh -M -S ~/.jumphost-socket \
	-fnNT \
	-D 1084 \
	-L 0.0.0.0:10521:$oracle:1521 \
	-L 0.0.0.0:13041:$rhap_oh_ip:3041 \
	-L 0.0.0.0:23041:$rhap_ss_ip:3041 \
	-L 0.0.0.0:30005:$rhap_ss_ip:30005 \
	ext-tunnel

#	-L 0.0.0.0:10636:$ldap_ip:636 \
