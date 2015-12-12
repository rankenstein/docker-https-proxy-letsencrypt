#!/bin/bash

rm -rf /usr/local/apache2/htdocs/vhosts
mkdir /usr/local/apache2/htdocs/vhosts

(
	case "$SSL_COMPATIBILITY" in
		"intermediate")
			echo 'SSLCipherSuite "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"'
			echo 'SSLProtocol all -SSLv2 -SSLv3'
			;;
		"old")
			echo 'SSLCipherSuite "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA"'
			echo 'SSLProtocol all - SSLv2'
			;;
		*)
			echo 'SSLCipherSuite "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK"'
			echo 'SSLProtocol all -SSLv2 -SSLv3 -TLSv1'
			;;
	esac

	default_chain=$SSL_CHAIN
	
	if [ ! -z "$default_chain" ]; then
		echo "SSLCertificateChainFile /ssl/$default_chain.pem"
	fi

	for i in ${!HOST_*}; do
		id="${i#HOST_}"
		hostname="$(echo "$id" | sed -e s/_/./g)"
		
		proxy="${!i}"
		if ! echo "$proxy" | grep -q "="; then
			proxy="/|$proxy"
		fi
		
		varname_chain="SSL_CHAIN_$i"
		chain="${!varname_chain:-startssl}"
		
		docroot="/usr/local/apache2/htdocs/vhosts/$hostname"
		
		ifs_bkp="$IFS"
		IFS="|"
		proxy_arr=($proxy)
		IFS=ifs_bkp
		
		echo
		echo
		echo "<VirtualHost *:443>"
		echo "    ServerName $hostname"
		echo
		echo "    SSLEngine on"
		echo "    SSLCertificateFile /ssl/$hostname.crt"
		echo "    SSLCertificateKeyFile /ssl/$hostname.key"
		
		if [ ! -z "$chain" ]; then
			echo "    SSLCertificateChainFile /ssl/$chain.pem"
		fi
		
		echo
		echo "    DocumentRoot $docroot"
		echo "    <Directory $docroot>"
		echo "        Options +Indexes"
		echo "    </Directory>"
		echo
		
		for((i=0; i<${#proxy_arr[@]}; i+=2)); do
			path="${proxy_arr[i]}"
			url="${proxy_arr[i+1]}"
			
			mkdir -p "$docroot/$path"
			echo "    ProxyPass \"$path\" \"$url\""
			echo "    ProxyPassReverse \"$path\" \"$url\""
		done
		
		echo "</VirtualHost>"
	done
) > /usr/local/apache2/conf/extra/vhosts.conf

/usr/local/bin/httpd-foreground
