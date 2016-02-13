#!/bin/bash

mkdir -p /ssl/letsencrypt && chown acme:acme /ssl/letsencrypt

/usr/local/bin/mkconfig.sh > /usr/local/apache2/conf/extra/vhosts.conf

/usr/local/bin/httpd-foreground
