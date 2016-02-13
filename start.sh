#!/bin/bash

chown acme:acme /usr/local/apache2/ssl

/usr/local/bin/mkconfig.sh > /usr/local/apache2/conf/extra/vhosts.conf

su acme -c /usr/local/bin/renew-ssl.sh

(
	while true; do
		sleep 86400
		su acme -c /usr/local/bin/renew-ssl.sh
		pkill -HUP httpd
	done
) &

/usr/local/bin/httpd-foreground
