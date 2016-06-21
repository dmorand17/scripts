#!/bin/bash
 
# Create an array files that contains list of filenames
# File names will be in a separate file named "file.txt"
files=($(< file.txt))
# replace the username and password with the appropriate values
uri='ftp://<username>:<password>/'
dir='/tmp/upgrades'
 
# make a directory
mkdir -p $dir
cd $dir
 
# Read through the file and execute wget command for every filename
for file in "${files[@]}"; do
    wget "${uri}${file}"
done