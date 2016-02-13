FROM httpd:latest
MAINTAINER Candid Dauth <cdauth@cdauth.eu> 

RUN apt-get update && apt-get install -y curl

RUN curl -L https://github.com/kuba/simp_le/archive/master.tar.gz | tar -xz -C /usr/local/share --transform 's@^simp_le-master@simp_le@' && \
	cd /usr/local/share/simp_le && \
	./bootstrap.sh && \
	./venv.sh

COPY custom.conf /usr/local/apache2/conf/extra/custom.conf
COPY start.sh /usr/local/bin/start.sh

RUN echo "Include conf/extra/custom.conf" >> /usr/local/apache2/conf/httpd.conf && \
	sed -ri /usr/local/apache2/conf/httpd.conf -e 's@^(\s*)(CustomLog\s)@\1#\2@g' && \
	mkdir /ssl /usr/local/apache2/acme && \
	useradd -m acme && \
	chown acme:acme /usr/local/apache2/acme

CMD "/usr/local/bin/start.sh"

EXPOSE 443