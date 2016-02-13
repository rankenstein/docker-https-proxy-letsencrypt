#!/bin/bash

/usr/local/bin/mkconfig.sh > /usr/local/apache2/conf/extra/vhosts.conf

/usr/local/bin/httpd-foreground
