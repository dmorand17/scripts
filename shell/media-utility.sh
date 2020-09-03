#!/bin/bash

DATE=$(date +"%Y%m%d")

scriptname=$(basename $0)
logfilename=${scriptname%.*}

#echo "scriptname $scriptname"
#echo "logfilename $logfilename"

#/home/dougie/scripts/change_perms.sh "/home/dougie/mybook/sorted/tv" > /home/dougie/scripts/logs/$logfilename-$DATE.log

logger "Updating permissions on mybook and toshiba5tb tv..."

/home/dougie/scripts/change_perms.sh "/home/dougie/toshiba5tb/media/"
/home/dougie/scripts/change_perms.sh "/home/dougie/mytoshiba1/media/"
/home/dougie/scripts/change_perms.sh "/home/dougie/myrepo/movies/"
/home/dougie/scripts/change_perms.sh "/home/dougie/buffalo/media/"
