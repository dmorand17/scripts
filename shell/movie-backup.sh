#!/bin/bash

DATE=$(date +"%Y%m%d")

start=`date +%s`
rsync -vaXzh --delete /home/dougie/myrepo/movies/ /home/dougie/mywd1/movies > /home/dougie/scripts/logs/backup-$DATE.log
end=`date +%s`

runtime=$((end-start))

if [ $? -eq 0 ]; then
  priority=0
  message="movie backups completed without issue"
else
  priority=1
  message="movie backups failed.  Please check the logs..."
fi

message="$message
time elapsed: $runtime seconds"

/home/dougie/scripts/pushover-curl.sh "Backup Task Complete" "$priority" "$message"
