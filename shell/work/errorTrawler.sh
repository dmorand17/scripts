#!/bin/bash
# This script runs the error trawler tool in Rhapsody.  You must pass:
# Maximum search size, 
# Destination directory, 
# Whether the messages should be removed from the queue,
# and throttling rate.
# When run, the script will invoke the trawler to remove all error messages up to and including the current date.
# You must provide credentials for a Rhapsody user that as the correct permissions to access the REST API. 
# Provide the credentials by creating a file called errorTrawler.conf in the same directory as this script.
# The file should contain the following:
# username:{the username of your errortrawler user}
# password:{the password for your errortralwer user}
#
# More details can be found at the following WOKI page
# http://woki/display/~AdamS/Error+Trawler 

# Script parameters
# parameter 1 - maxSearchSize - integer -
# parameter 2 - directory - string - 
# parameter 3 - removeFromQueue - boolean -
# parameter 4 - throttle - integer 
# parameter 5 - verbose - boolean
maxSearchSize=$1
directory=$2
removeFromQueue=$3
throttle=$4
verbose=$5

result=""

function log {
  echo "$(date): $1" >> /var/log/errorTrawler
}

# Reads the credentials from a configuration file
function getErrorTrawlerUsername {
	errorTrawlerUser=$(awk '{ print $1}' ./errorTrawler.conf | grep "username" | cut -d: -f2)
	echo $errorTrawlerUser
}

function getErrorTrawlerPassword {
	errorTrawlerPassword=$(awk '{ print $1}' ./errorTrawler.conf | grep "password" | cut -d: -f2)
	echo $errorTrawlerPassword
}

function invokeRemove {
	#Poke the options page to populate the CSRF token for this session.
	curl -u $1:$2 -I -s http://localhost:8081/errorTrawler/options
	#Invoke the run command via the REST API
	result=$(curl -u $1:$2 -H "Content-Type: application/json" -H "Accept: application/json" -d "$json" -POST http://localhost:8081/errorTrawler/remove)
}

log "============================================"
log "Error trawler script starting."
#Get the current time as Seconds since UNIX epoch
timestamp=$(date +%s)
#Set JSON data for the request.
json='{"maxSearchSize":'$maxSearchSize',"directory":"'$directory'","removeFromQueue":'$removeFromQueue', "endTime":'$timestamp', "throttle":'$throttle'}'
log "Running Rhapsody error trawler. maxSearchSize:{'$maxSearchSize'}, directory:{'$directory'}, removeFromQueue:{'$removeFromQueue'}, endTime:{'$timestamp'}, throttle:{'$throttle'}"

errorTrawlerUser=$(getErrorTrawlerUsername)
errorTrawlerPassword=$(getErrorTrawlerPassword)

invokeRemove $errorTrawlerUser $errorTrawlerPassword

log "Rhapsody response: $result"
log "Error trawler script ends."
log "============================================"