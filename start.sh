#!/bin/bash

mkdir -p /ssl/letsencrypt && chown acme:acme /ssl/letsencrypt

/usr/local/bin/mkconfig.sh > /usr/local/apache2/conf/extra/vhosts.conf

su acme -c /usr/local/bin/renew-ssl.sh

(
	while true; do
		sleep 86400
		su acme -c /usr/local/bin/renew-ssl.sh
	done
) &

/usr/local/bin/httpd-foreground
