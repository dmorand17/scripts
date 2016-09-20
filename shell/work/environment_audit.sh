#!/bin/bash
#VM Stabilization Audit Script
#Jesse Sparks
#Created 26 March 2015
#Modified 14 April 2015
#http://woki/display/manser/Stabilization+Starting+Points+-+Audit+Script

AUDITFILE=/tmp/audit_file.txt

#Validate script being ran by root user
user=`whoami`
if [ $user != root ]; then
     echo "This script must be run as root"
     exit
 else 
	 echo >> $AUDITFILE
fi
 
#Check to see what version of OS is installed
echo "Audit Has Started"

echo > $AUDITFILE
echo -n "Results of Audit Script for " >> $AUDITFILE
hostname >> $AUDITFILE
date +%D-%R >> $AUDITFILE
echo -n "Uptime " >> $AUDITFILE
uptime >> $AUDITFILE
echo >> $AUDITFILE

echo "OS VERSION" >> $AUDITFILE
cat /etc/*-release >> $AUDITFILE

#Check to see used/available memory
echo >> $AUDITFILE
echo "MEMORY STATISTICS in MB" >> $AUDITFILE
free -mt >> $AUDITFILE

#Check Hard Disk Available Space
echo >> $AUDITFILE
echo "VOLUME STATISTICS" >> $AUDITFILE
df -kh >> $AUDITFILE
echo >> $AUDITFILE
echo "Scanning for large home directories.  This may take a while"
echo "Top home folders by size" >> $AUDITFILE
du -hs /home/* | sort -hr | head -n 6 >> $AUDITFILE

#Where Orion Apps are running
echo >> $AUDITFILE
echo "Where Orion apps are running" >> $AUDITFILE
ps h -fu orion | awk '{print $9}' >> $AUDITFILE

#What's in the /opt/ directory?  Any Junk?
echo  >> $AUDITFILE
echo "CONTENTS OF /opt/ DIRECTORY" >> $AUDITFILE
ls -l /opt/ >> $AUDITFILE

#What's in the /opt/orionhealth directory?  Any Junk?
echo  >> $AUDITFILE
echo "CONTENTS OF /opt/orionhealth/ DIRECTORY" >> $AUDITFILE
ls -l /opt/orionhealth/ >> $AUDITFILE

#Installed Bundles
echo >> $AUDITFILE
sh /kits/MSO/scripts/bundle_versions.sh >> $AUDITFILE

#Rhapsody information
echo >> $AUDITFILE
if [ -f /opt/orionhealth/Rhapsody/version.txt ];
then
	echo -n "Rhapsody Version " >> $AUDITFILE
	cat /opt/orionhealth/Rhapsody/version.txt | cut -f 1-3 -d '.'  >> $AUDITFILE
	echo >> $AUDITFILE
	echo "Rhapsody Data Directory, Max Memory(6144), Permgen Size(192), and JMX Port(17999)" >> $AUDITFILE
	cat /opt/orionhealth/Rhapsody/rhapsody/rhapsody.properties | grep Initialisation | cut -f 2 -d '.' >> $AUDITFILE
	cat /opt/orionhealth/Rhapsody/bin/wrapper-local.conf | grep maxmemory | cut -f 3 -d '.' >> $AUDITFILE
	cat /opt/orionhealth/Rhapsody/bin/wrapper-local.conf | grep MaxPermSize | cut -f 2 -d ':' >> $AUDITFILE
	cat /opt/orionhealth/Rhapsody/bin/wrapper-local.conf | grep port | cut -f 7-8 -d '.' >> $AUDITFILE
elif [ -f /opt/orionhealth/rhapsody/version.txt ];
then
	echo -n "Rhapsody Version " >> $AUDITFILE
	cat /opt/orionhealth/rhapsody/version.txt | cut -f 1-3 -d '.'  >> $AUDITFILE
	echo >> $AUDITFILE
	echo "Rhapsody Data Directory, Max Memory(6144), Permgen Size(192), and JMX Port(17999)" >> AUDITFILE
	cat /opt/orionhealth/Rhapsody/rhapsody/rhapsody.properties | grep Initialisation | cut -f 2 -d '.' >> $AUDITFILE
	cat /opt/orionhealth/rhapsody/bin/wrapper-local.conf | grep maxmemory | cut -f 3 -d '.' >> $AUDITFILE
	cat /opt/orionhealth/rhapsody/bin/wrapper-local.conf | grep MaxPermSize | cut -f 2 -d ':' >> $AUDITFILE
	cat /opt/orionhealth/rhapsody/bin/wrapper-local.conf | grep port | cut -f 7-8 -d '.' >> $AUDITFILE
else
	echo "No Rhapsody Engine found or is installed in non-standard directory" >> $AUDITFILE
fi

echo >> $AUDITFILE
echo "All rhapsody.properties files" >> $AUDITFILE
locate rhapsody.properties >> $AUDITFILE

#OHP INFO
echo >> $AUDITFILE
if [ -f /opt/orionhealth/FrontEndPlatform/bin/wrapper-local.conf ];
then
	echo "FrontEndPlatform Version, Max Memory(4096), Permgen Size(384) and JMX Port(17999)" >> $AUDITFILE
	echo -n "Platform Version " >> $AUDITFILE
	cat /opt/orionhealth/FrontEndPlatform/bin/wrapper-local.conf | grep maxmemory | cut -f 3 -d '.' >> $AUDITFILE
	cat /opt/orionhealth/FrontEndPlatform/bin/wrapper-local.conf | grep MaxPermSize | cut -f 2 -d ':' >> $AUDITFILE
	cat /opt/orionhealth/FrontEndPlatform/bin/wrapper-local.conf | grep port | cut -f 7-8 -d '.' >> $AUDITFILE
	echo >> $AUDITFILE
	echo "If MaxBackupIndex line appears, log4j settings are not configured properly. Need to be fixed per http://woki/display/foresight/Foresight+-+Orion+Application+Log+Cleanup" >> $AUDITFILE
	cat /opt/orionhealth/FrontEndPlatform/data/configuration/log4j.properties | grep XmlAppender.MaxBackupIndex >> $AUDITFILE
	echo >> $AUDITFILE
elif [ -f /opt/orionhealth/BackEndPlatform/bin/wrapper-local.conf ];
then 
	echo "BackEndPlatform Version, Max Memory(4096) and Permgen Size(384) and JMX Port(16999)" >> $AUDITFILE
	echo -n "Platform Version " >> $AUDITFILE
	cat /opt/orionhealth/BackEndPlatform/bin/wrapper-local.conf | grep maxmemory | cut -f 3 -d '.' >> $AUDITFILE
	cat /opt/orionhealth/BackEndPlatform/bin/wrapper-local.conf | grep MaxPermSize | cut -f 2 -d ':' >> $AUDITFILE
	cat /opt/orionhealth/BackEndPlatform/bin/wrapper-local.conf | grep port | cut -f 7-8 -d '.' >> $AUDITFILE
	echo >> $AUDITFILE
	echo "If MaxBackupIndex line appears, log4j settings are not configured properly. Need to be fixed per http://woki/display/foresight/Foresight+-+Orion+Application+Log+Cleanup" >> $AUDITFILE
	cat /opt/orionhealth/BackEndPlatform/data/configuration/log4j.properties | grep XmlAppender.MaxBackupIndex >> $AUDITFILE
	echo >> $AUDITFILE
elif [ -f /opt/orionhealth/OrionHealthPlatform/bin/wrapper-local.conf ];
then 
	echo "OHP (front/back unknown) Version, Max Memory(4096) and Permgen Size(384) and JMX Port(16999 back 17999 front)" >> $AUDITFILE
	echo -n "Platform Version " >> $AUDITFILE
	cat /opt/orionhealth/OrionHealthPlatform/bin/wrapper-local.conf | grep maxmemory | cut -f 3 -d  >> $AUDITFILE
	cat /opt/orionhealth/OrionHealthPlatform/bin/wrapper-local.conf | grep MaxPermSize | cut -f 2 -d ':' >> $AUDITFILE
	cat /opt/orionhealth/OrionHealthPlatform/bin/wrapper-local.conf | grep port | cut -f 7-8 -d '.' >> $AUDITFILE
	echo >> $AUDITFILE
	echo "If MaxBackupIndex line appears, log4j settings are not configured properly. Need to be fixed per http://woki/display/foresight/Foresight+-+Orion+Application+Log+Cleanup" >> $AUDITFILE
	cat /opt/orionhealth/OrionHealthPlatform/data/configuration/log4j.properties | grep XmlAppender.MaxBackupIndex >> $AUDITFILE
	echo >> $AUDITFILE
else 
	echo "No OHP found on this node or is in non-standard location" >> $AUDITFILE
	echo >> $AUDITFILE
fi

# List of last users to login to box
echo "The last 10 users to ssh into this machine are " >> $AUDITFILE
last | grep -v root | head >> $AUDITFILE

#List all the Orion apps that are set to auto start
echo >> $AUDITFILE
echo "Which apps are set to autostart? " >> $AUDITFILE
chkconfig | grep rhapsody >> $AUDITFILE
chkconfig | grep ohp >> $AUDITFILE
chkconfig | grep hli >> $AUDITFILE

# httpd available packages
host=`hostname`
if [[ $host == *app* ]];
then
	echo >> $AUDITFILE
	echo "httpd Package information and update information if available " >> $AUDITFILE
	yum info httpd | egrep '(Available)|(Name)|(Version)|(Release)' >> $AUDITFILE
	
	if [ -f /etc/logrotate.d/httpd ];
	then break
	else
		echo >> $AUDITFILE
		echo "Missing logrotate file for httpd.  View http://woki/display/foresight/Foresight+-+Log+Rotate+Daemon+Configuration" >> $AUDITFILE
	fi
else
	break
fi

# Check the nproc limit is set
echo >> $AUDITFILE
echo "Prod Rhapsody nodes (4096), other prod nodes (2048) dev/test nodes (1024)" >> $AUDITFILE
cat /etc/security/limits.conf | grep nproc | egrep -v '(student)|(faculty)|(ftp)' >> $AUDITFILE

# Fix long ssh auth times
echo >> $AUDITFILE
echo "In order to fix slow login times, these lines should be commented out from /etc/pam.d/system-auth-ac" >> $AUDITFILE
cat /etc/pam.d/system-auth-ac | egrep '(pam_ldap.so use_first_pass)|([default=bad success=ok user_unknown=ignore] pam_ldap.so)|(pam_ldap.so use_authtok)|(pam_ldap.so)' >> $AUDITFILE
echo >> $AUDITFILE

# Check for unmounted /ws and /conductor 
if [ -f /opt/orionhealth/MSO/Apache/security/mod_jk_unmounts.conf ];
then
	echo "Unmounting bits from apache. Should have /ws and /conductor lines" >> $AUDITFILE
	cat /opt/orionhealth/MSO/Apache/security/mod_jk_unmounts.conf | grep JkUnMount >> $AUDITFILE
elif [ -f /opt/orionhealth/Core/connector/apache/conf/mod_jk.conf ];
then
	echo "Unmounting bits from apache Should have /ws and /conductor lines" >> $AUDITFILE
	cat /opt/orionhealth/Core/connector/apache/conf/mod_jk.conf | grep JkUnMount >> $AUDITFILE
else
	echo "No JkUnMount file exists or configured improperly" >> $AUDITFILE
fi

# Completion message
echo "$(tput setaf 1)Audit complete.  Results are in /tmp/audit_file.txt Would you like to view results now?$(tput sgr 0) (y/n)"
read ANSWER

if [ $ANSWER = y ];
then 
	cat /tmp/audit_file.txt
	exit
else
	exit
fi
