#!/bin/bash

chown acme:acme /usr/local/apache2/ssl

NO_SSL=1 /usr/local/bin/mkconfig.sh > /usr/local/apache2/conf/extra/vhosts.conf

if [[ "$NO_SSL" != +(1|yes|true|on) ]]; then
	(
		su acme -c /usr/local/bin/renew-ssl.sh
		/usr/local/bin/mkconfig.sh > /usr/local/apache2/conf/extra/vhosts.conf
		pkill -HUP httpd
	) &
fi

(
	while true; do
		sleep 86400
		su acme -c /usr/local/bin/renew-ssl.sh
		pkill -HUP httpd
	done
) &

/usr/local/bin/httpd-foreground
