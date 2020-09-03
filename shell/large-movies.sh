#!/bin/bash

function list_dirs() {

    large_movies=$(du -h ~/myrepo/movies/* | sort -rh | head -n 50 | cut -f2)
    echo Checking directory $dir
    echo ---------------------------------
    while IFS= read -r movie; do
        echo "Movie: $movie"
        #echo \t $(ls -la "$movie")
    done <<< "$large_movies"
}

DATE=$(date +"%Y%m%d")

scriptname=$(basename $0)
logfilename=${scriptname%.*}

#/home/dougie/scripts/change_perms.sh "/home/dougie/mybook/sorted/tv" > /home/dougie/scripts/logs/$logfilename-$DATE.log

du -h ~/myrepo/movies/* | sort -rh | head -n 50 > /home/dougie/scripts/logs/50-largest-movies.log

list_dirs
#logger "Updating permissions on mybook and toshiba5tb tv..."


