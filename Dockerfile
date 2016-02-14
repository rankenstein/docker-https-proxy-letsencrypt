FROM httpd:latest
MAINTAINER Candid Dauth <cdauth@cdauth.eu> 

RUN apt-get update && apt-get install -y vim curl

RUN curl -L https://github.com/kuba/simp_le/archive/master.tar.gz | tar -xz -C /usr/local/share --transform 's@^simp_le-master@simp_le@' && \
	cd /usr/local/share/simp_le && \
	./bootstrap.sh && \
	./venv.sh && \
	ln -s /usr/local/share/simp_le/venv/bin/simp_le /usr/local/bin/

COPY custom.conf /usr/local/apache2/conf/extra/custom.conf
COPY start.sh mkconfig.sh renew-ssl.sh /usr/local/bin/

RUN echo "Include conf/extra/custom.conf" >> /usr/local/apache2/conf/httpd.conf && \
	sed -ri /usr/local/apache2/conf/httpd.conf -e 's@^(\s*)(CustomLog\s)@\1#\2@g' && \
	mkdir -p /usr/local/apache2/ssl /usr/local/apache2/htdocs/.well-known/acme-challenge && \
	useradd -s /bin/bash acme && \
	chown acme:acme /usr/local/apache2/htdocs/.well-known/acme-challenge

CMD "/usr/local/bin/start.sh"

VOLUME ["/usr/local/apache2/ssl"]

EXPOSE 80 443
