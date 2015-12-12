FROM httpd:latest
MAINTAINER Candid Dauth <cdauth@cdauth.eu> 

COPY custom.conf /usr/local/apache2/conf/extra/custom.conf
COPY start.sh /usr/local/bin/start.sh

RUN echo "Include conf/extra/custom.conf" >> /usr/local/apache2/conf/httpd.conf && \
	mkdir /ssl && \
	rm -f /usr/local/apache2/htdocs/index.html

CMD "/usr/local/bin/start.sh"