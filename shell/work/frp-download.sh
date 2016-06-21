#!/bin/bash


printusage() {
cat << end-of-usage
Usage:
$0 ftp_username ftp_password file.txt
: Parameters:
 - ftp_username: Username for FTP site
 - ftp_password: Password for FTP site
 - file.txt: filename containing the files to download
end-of-usage
}

FILE=$3
FTP_USERNAME=$1
FTP_PASSWORD=$2

echo "File: $FILE FTPUSERNAME: $FTP_USERNAME FTPPASSWORD: $FTP_PASSWORD"

# Create an array files that contains list of filenames
# File names will be in a separate file named "file.txt"
files=($(< file.txt))


# replace the username and password with the appropriate values
uri='ftp://<username>:<password>@ftp.orion.co.nz/'
dir='/tmp/upgrades'


download_files(){
	# make a directory
	mkdir -p $dir
	cd $dir
	 
	# Read through the file and execute wget command for every filename
	for file in "${files[@]}"; do
		wget "${uri}${file}"
	done
}


#-----------------------------------------------------
#			MAIN
#-----------------------------------------------------

if [[ $# -ne 3 ]] ; then
	echo Not enough parameters
	printusage
	exit 1

fi

download_files

echo 
echo "Finished!"
