#!/bin/bash

replace_hostname() {
	url="$1"
	hostname="$2"

	# Take $url and replace the hostname with $hostname. Leave the port if it exists, remove user and password if it exists
	echo "$url" | sed -re "s%(://([^/]+@)?)([[][^]]+[]]|[^:/]+)%://$hostname%"
}

extract_hostname() {
	url="$1"

	# Exract the hostname from $url. If it is an IPv6 address in square brackets, remove the brackets.
	echo "$url" | sed -re "s%^([^:]+://([^/]+@)?)([[][^]]+[]]|[^:/]+).*$%\\3%" | sed -re "s%^[[](.*)[]]$%\\1%"
}

extract_path() {
	url="$1"

	# Exract the path from $url.
	echo "$url" | sed -re "s%^[^:]+://([^/]+)([^?#]*).*$%\\2%"
}

replace_protocol() {
	url="$1"
	protocol="$2"

	# Replace protocol in $url with $protocol
	echo "$url" | sed -re "s%^[^:]+://%$protocol://%"
}

remove_trailing_slash() {
	url="$1"
	
	echo "$url" | sed -re "s@/+\$@@"
}

switch_https() {
	url="$1"

	# If protocol is https, make http. If protocol is http, make https.
	proto="$(echo "$url" | cut -d: -f1)"

	case "$proto" in
		http)
			replace_protocol "$url" https
			;;
		https)
			replace_protocol "$url" http
			;;
		*)
			echo "$url"
			;;
	esac
}

get_ws_url() {
	url="$1"

	proto="$(echo "$url" | cut -d: -f1)"

	case "$proto" in
		http)
			replace_protocol "$url" ws
			;;
		https)
			replace_protocol "$url" wss
			;;
		*)
			echo "$url"
			;;
	esac
}

if [[ "$NO_SSL" != +(1|yes|true|on) ]]; then
	echo "LoadModule ssl_module modules/mod_ssl.so"
	echo "Listen 443"
	echo "SSLProxyEngine on"
	
	echo
	
	echo "<VirtualHost *:80>"
	echo "    Header always set Strict-Transport-Security \"max-age=1576800000\""
	echo
	echo "    RewriteEngine on"
	echo "    RewriteCond %{REQUEST_URI} !^/.well-known/acme-challenge/?"
	echo "    RewriteRule ^/(.*)$ https://%{HTTP_HOST}/$1"
	echo "</VirtualHost>"

	echo
	
	# From https://wiki.mozilla.org/Security/Server_Side_TLS#Apache

	case "$SSL_COMPATIBILITY" in
		"intermediate")
			echo 'SSLCipherSuite "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS"'
			echo 'SSLProtocol all -SSLv2 -SSLv3'
			;;
		"old")
			echo 'SSLCipherSuite "ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:DES-CBC3-SHA:HIGH:SEED:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!RSAPSK:!aDH:!aECDH:!EDH-DSS-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA:!SRP"'
			echo 'SSLProtocol all -SSLv2'
			;;
		*)
			echo 'SSLCipherSuite "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256"'
			echo 'SSLProtocol all -SSLv2 -SSLv3 -TLSv1'
			;;
	esac
	echo "SSLHonorCipherOrder on"
	echo "SSLCompression off"
	echo "SSLSessionTickets off"
	echo "SSLUseStapling on"
	echo "SSLStaplingResponderTimeout 5"
	echo "SSLStaplingReturnResponderErrors off"
	echo "SSLStaplingCache \"shmcb:/var/run/ocsp(128000)\""
	echo "SSLSessionCache \"shmcb:/usr/local/apache2/logs/ssl_scache(512000)\""
	echo "SSLSessionCacheTimeout 300"

	echo

	echo "SSLCertificateFile /usr/local/apache2/ssl/cert.pem"
	echo "SSLCertificateKeyFile /usr/local/apache2/ssl/key.pem"
	echo "SSLCertificateChainFile /usr/local/apache2/ssl/chain.pem"
fi

if [[ "$PRESERVE_HOST" = +(1|yes|true|on) ]]; then
	echo "ProxyPreserveHost On"
fi

for i in ${!HOST_*}; do
	id="${i#HOST_}"
	hostname="$(echo "$id" | sed -e s/_/./g)"
	
	proxy="${!i}"
	if ! echo "$proxy" | grep -q "|"; then
		proxy="/|$proxy"
	fi
	
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
	
	common_conf="$(
		echo "    ServerName $hostname"
		if [ ! -z "$alias" ]; then
			echo "    ServerAlias $alias"
		fi

		echo
		echo "    RewriteEngine on"
		
		for((i=$[${#proxy_arr[@]}-2]; $i>=0; i-=2)); do
			path="$(remove_trailing_slash "${proxy_arr[i]}")"
			url="$(remove_trailing_slash "${proxy_arr[i+1]}")"
		
			echo

			if [ ! -z "$redirect" ]; then
				echo "    RewriteCond %{REQUEST_URI} !^/.well-known/acme-challenge/?"
				echo "    RewriteRule ^$path(/.*)?$ $url\$1 [R=$redirect]"
			else
				echo "    RewriteRule ^$path$ \$0/ [R=permanent]"

				echo "    RewriteCond %{HTTP:Upgrade} =websocket"
				echo "    RewriteRule ^$path(/.*)?$ $(get_ws_url "$url")\$1 [P]"
				echo "    RewriteCond %{HTTP:Upgrade} !=websocket"
				echo "    RewriteCond %{REQUEST_URI} !^/.well-known/acme-challenge/?"
				echo "    RewriteRule ^$path(/.*)?$ $url\$1 [P]"

				if [[ "$preserve_host" = +(1|yes|true|on) ]]; then
					echo
					echo "    ProxyPreserveHost On"
				elif [[ "$preserve_host" = +(0|no|false|off) ]]; then
					echo
					echo "    ProxyPreserveHost Off"
				fi

				echo
				echo "    <Location \"$path/\">"

				if [[ "$preserve_host" = +(1|yes|true|on) || "$PRESERVE_HOST" = +(1|yes|true|on) ]]; then
					replaced_url="$(replace_hostname "$url" "$hostname")"
					echo "        ProxyPassReverse \"$replaced_url/\""
					echo "        ProxyPassReverse \"$(switch_https "$replaced_url")/\""
				else
					echo "        ProxyPassReverse \"$url/\""
					echo "        ProxyPassReverse \"$(switch_https "$url")/\""

					url_hostname="$(extract_hostname "$url")"
					if [[ "$url_hostname" != "$hostname" ]]; then
						echo "        ProxyPassReverseCookieDomain \"$url_hostname\" \"$hostname\""
					fi
				fi

				url_path="$(extract_path "$url")"
				if [[ "$url_path" != "$path" ]]; then
					echo "        ProxyPassReverseCookiePath \"$url_path/\" \"$path/\""
					echo "        ProxyPassReverse \"$url_path/\"" # For broken redirects
				fi

				echo "    </Location>"
			fi
		done
	)"

	echo

	if [[ "$NO_SSL" != +(1|yes|true|on) ]]; then
		echo
		echo "<VirtualHost *:443>"
		echo "    SSLEngine on"
		echo
		echo "$common_conf"

		if [ -z "$redirect" ]; then
			echo
			echo "    RequestHeader add X-Forwarded-Ssl on"
			echo "    RequestHeader set X-Forwarded-Proto 'https'"
			echo "    RequestHeader set X-Forwarded-Port '443'"
		fi

		if [[ "$nonssl" != +(1|yes|true|on) ]]; then
			echo
			echo "    Header always set Strict-Transport-Security \"max-age=1576800000\""
		fi

		echo "</VirtualHost>"
	fi
	
	if [[ "$NO_SSL" = +(1|yes|true|on) || "$nonssl" = +(1|yes|true|on) ]]; then
		echo
		echo "<VirtualHost *:80>"
		echo "$common_conf"
		echo "</VirtualHost>"
	fi
done
