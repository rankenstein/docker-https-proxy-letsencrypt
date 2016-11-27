#!/bin/bash

chown acme:acme /etc/apache2/ssl

NO_SSL=1 /usr/local/bin/mkconfig.sh > /etc/apache2/conf.d/vhosts.conf

if [[ "$NO_SSL" != +(1|yes|true|on) ]]; then
	(
		su acme -c /usr/local/bin/renew-ssl.sh
		/usr/local/bin/mkconfig.sh > /etc/apache2/conf.d/vhosts.conf
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

rm -f /run/apache2/httpd.pid
httpd -D FOREGROUND
