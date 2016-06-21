#!/bin/bash

DATE=$(date +"%Y%m%d")

scriptname=$(basename $0)
logfilename=${scriptname%.*}

#echo "scriptname $scriptname"
#echo "logfilename $logfilename"

#/home/dougie/scripts/change_perms.sh "/home/dougie/mybook/sorted/tv" > /home/dougie/scripts/logs/$logfilename-$DATE.log
/home/dougie/scripts/change_perms.sh "/home/dougie/mybook/sorted/tv"
