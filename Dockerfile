from haproxy:1.7-alpine

ARG ACME_PLUGIN_VERSION=0.1.1

RUN buildDeps='' runtimeDeps='python py2-pip certbot curl ca-certificates openssl tar haproxy inotify-tools lua-sec grep bash' \
  && apk add --update $buildDeps $runtimeDeps \ 
  && curl -sSL https://github.com/janeczku/haproxy-acme-validation-plugin/archive/${ACME_PLUGIN_VERSION}.tar.gz -o acme-plugin.tar.gz \
  && mkdir -p /var/lib/haproxy \
  && tar -C /var/lib/haproxy -xf acme-plugin.tar.gz --strip-components=1 --no-anchored acme-http01-webroot.lua \
  && rm *.tar.gz \
  && pip install --upgrade pip \
  && pip install supervisor \
  && apk del $buildDeps 
  
RUN mkdir -p /var/lib/haproxy

ENV SUPERVISOR_CONFIG=/etc/supervisord.conf
ENV HAPROXY_CONFIG=/etc/haproxy/haproxy.cfg
ENV LETSENCRYPT_DIR=/etc/letsencrypt
ENV HAPROXY_HOST_IP=127.0.0.1
ENV HAPROXY_HOST_PORT=80
ENV LETSENCRYPT_DOMAIN=localhost
ENV LETSENCRYPT_EMAIL=email_please.email

ADD haproxy.cfg /etc/haproxy/haproxy.cfg
ADD supervisord.conf /etc/
ADD entrypoint.sh /
ADD cert-renewal-haproxy.sh /
RUN chmod +x /entrypoint.sh \
  && chmod +x /cert-renewal-haproxy.sh \

RUN touch crontab.tmp \
    && echo '0 0 * * 0 /bin/bash /cert-renewal-haproxy.sh' > crontab.tmp \
    && crontab crontab.tmp \
    && rm -rf crontab.tmp

CMD ["/bin/bash", "-c", "supervisord --nodaemon --configuration ${SUPERVISOR_CONFIG}"]
