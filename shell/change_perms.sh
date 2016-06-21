#!/bin/bash
#  This script will change the permissions to 751 so that the plex user 
#  can properly read the files in tv / movies 
#

echo "---------------------------"
echo "    Updating permissions"
echo "---------------------------"
for i in $@;
do
	echo "updating $i"
	chmod +rx -R $i
done
