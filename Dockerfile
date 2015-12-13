FROM httpd:latest
MAINTAINER Candid Dauth <cdauth@cdauth.eu> 

COPY custom.conf /usr/local/apache2/conf/extra/custom.conf
COPY start.sh /usr/local/bin/start.sh

RUN echo "Include conf/extra/custom.conf" >> /usr/local/apache2/conf/httpd.conf && \
	sed -ri /usr/local/apache2/conf/httpd.conf -e 's@^(\s*)(CustomLog\s)@\1#\2@g' && \
	mkdir /ssl

CMD "/usr/local/bin/start.sh"

EXPOSE 443