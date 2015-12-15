#!/bin/bash

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

	if [ ! -z "$SSL_CHAIN" ]; then
		echo "SSLCertificateChainFile /ssl/$SSL_CHAIN.pem"
	fi
	
	if [[ "$PRESERVE_HOST" = +(1|yes|true|on) ]]; then
		echo "ProxyPreserveHost On"
	fi
	
	if [ ! -z "$SSL_FALLBACK_KEY" ]; then
		echo "<VirtualHost *:443>"
		echo "    SSLEngine on"
		echo "    SSLCertificateFile /ssl/$SSL_FALLBACK_KEY.crt"
		echo "    SSLCertificateKeyFile /ssl/$SSL_FALLBACK_KEY.key"
		
		if [ ! -z "$SSL_FALLBACK_CHAIN" ]; then
			echo "    SSLCertificateChainFile /ssl/$SSL_FALLBACK_CHAIN.pem"
		fi
		
		echo "</VirtualHost>"
	fi

	for i in ${!HOST_*}; do
		id="${i#HOST_}"
		hostname="$(echo "$id" | sed -e s/_/./g)"
		
		proxy="${!i}"
		if ! echo "$proxy" | grep -q "|"; then
			proxy="/|$proxy"
		fi
		
		varname_chain="SSL_CHAIN_$id"
		chain="${!varname_chain}"
		
		varname_nonssl="ALLOW_NONSSL_$id"
		nonssl="${!varname_nonssl}"
		
		varname_redirect="REDIRECT_$id"
		redirect="${!varname_redirect}"
		
		varname_alias="ALIAS_$id"
		alias="${!varname_alias}"
		
		varname_preserve_host="PRESERVE_HOST_$id"
		preserve_host="${!varname_preserve_host}"
		
		ifs_bkp="$IFS"
		IFS="|"
		proxy_arr=($proxy)
		IFS=ifs_bkp
		
		echo
		echo
		echo "<VirtualHost *:443>"
		
		common_conf="$(
			echo "    ServerName $hostname"
			if [ ! -z "$alias" ]; then
				echo "    ServerAlias $alias"
			fi
			
			echo
			
			for((i=${#proxy_arr[@]}-1; i>=0; i-=2)); do
				path="${proxy_arr[i-1]}"
				url="${proxy_arr[i]}"
				
				if [ ! -z "$redirect" ]; then
					echo "    RewriteEngine on"
					echo "    RewriteRule ^$(echo "$path" | sed -re 's@/+$@@')/(.*)$ $(echo "$url" | sed -re 's@/+$@@')/\$1 [R=$redirect]"
				else
					echo "    ProxyPass \"$path\" \"$url\""
					echo "    ProxyPassReverse \"$path\" \"$url\""
					if [[ "$preserve_host" = +(1|yes|true|on) ]]; then
						echo "    ProxyPreserveHost On"
					elif [[ "$preserve_host" = +(0|no|false|off) ]]; then
						echo "    ProxyPreserveHost Off"
					fi
				fi
			done
		)"
		echo "$common_conf"
		if [ -z "$redirect" ]; then
			echo "    RequestHeader add X-Forwarded-Ssl on"
			echo "    RequestHeader set X_FORWARDED_PROTO 'https'"
		fi
		
		echo
		echo "    SSLEngine on"
		echo "    SSLCertificateFile /ssl/$hostname.crt"
		echo "    SSLCertificateKeyFile /ssl/$hostname.key"
		
		if [ ! -z "$chain" ]; then
			echo "    SSLCertificateChainFile /ssl/$chain.pem"
		fi
		
		echo "</VirtualHost>"
		
		if [[ "$nonssl" = +(1|yes|true|on) ]]; then
			echo
			echo "<VirtualHost *:80>"
			echo "$common_conf"
			echo "</VirtualHost>"
		fi
	done
) > /usr/local/apache2/conf/extra/vhosts.conf

/usr/local/bin/httpd-foreground
