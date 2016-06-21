#!/bin/bash

echo "Enter Internal IP address for Patient Portal server (should be a 10.x.x.x address):"
read INTERNAL_IP

IP=$(graviton status -p ec2 frontend | sed -n -e 's/^.*Public IP: //p')
echo "Loading centos@$IP"
CONF_DIR=/opt/orionhealth/OrionHealthPlatform/connector/conf

ssh -i ~/.ssh/puppet_id_rsa centos@$IP <<- GR
	sudo su - orion

	# Comment out existing media mounts
	sed -i 's/JkMount \/media\/\* ohcp/#JkMount \/media\/\* ohcp/' $CONF_DIR/ohp-mounts.conf
	sed -i 's/JkMount \/media ohcp/#JkMount \/media ohcp/g' $CONF_DIR/ohp-mounts.conf

	# update file upload size limit
	cat >> $CONF_DIR/ohp-mod_jk.conf <<- EOT
		#Limit the file size to be uploaded
		LimitRequestBody 104857600
	EOT

	# leave orion user
	exit

	sudo su -

	# remove closing VirtualHost line
	head -n -1 /etc/httpd/conf.d/15-ohp-ssl.conf > /etc/httpd/conf.d/15-ohp-ssl.conf.tmp
	mv /etc/httpd/conf.d/15-ohp-ssl.conf.tmp /etc/httpd/conf.d/15-ohp-ssl.conf

	# Add mod_proxy entries for connections
	cat >> /etc/httpd/conf.d/15-ohp-ssl.conf <<- EOT
		ProxyRequests Off

		<Proxy *>
		Order deny,allow
		Allow from all
		</Proxy>

		SSLProxyEngine On
		ProxyPreserveHost On
		ProxyPass /patientportal https://$INTERNAL_IP:19043/patientportal
		ProxyPassReverse /patientportal https://$INTERNAL_IP:19043/patientportal
		ProxyPass /media https://$INTERNAL_IP:19043/media
		ProxyPassReverse /media https://$INTERNAL_IP:19043/media
		</VirtualHost>
	EOT

	# Add proxy load file
	cat >> /etc/httpd/conf.d/proxy.load << EOT
		LoadModule proxy_module modules/mod_proxy.so
	EOT

	# Add mod_proxy_http load file
	cat >> /etc/httpd/conf.d/proxy_http.load << EOT
		LoadModule proxy_http_module modules/mod_proxy_http.so
	EOT
	exit

	# restart apache
	sudo service httpd restart

	# leave ssh session
	exit
GR