#!/bin/bash

# Rebooting machine in 30 minutes
logger "Restarting machine in 5 minutes"
/home/dougie/scripts/pushover-curl.sh "Server Restart" "0" "Restarting dougie-desktop..."
shutdown -r 5
