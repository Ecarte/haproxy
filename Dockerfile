from haproxy:1.7-alpine

RUN apk add --update \
    inotify-tools \
    bash \
    grep \
  && rm -rf /var/cache/apk/*
  
RUN mkdir -p /var/lib/haproxy
  
ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]