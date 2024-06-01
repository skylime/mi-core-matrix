#!/usr/bin/env bash
# This script configures SSL and starts the nginx service.

SSL_HOME='/opt/local/etc/nginx/ssl/'
SVC_NAME='svc:/pkgsrc/nginx:default'

mkdir -p "${SSL_HOME}"

log "Self-signed certificate generator"
/opt/core/bin/ssl-selfsigned.sh -d ${SSL_HOME} -f nginx

log "Enable nginx+php-fpm webserver service"
svcadm enable -s ${SVC_NAME}

log "Try to obtain Let's Encrypt SSL certificate"
/opt/core/bin/ssl-generator.sh ${SSL_HOME} nginx_ssl nginx ${SVC_NAME}

log "Restart ${SVC_NAME}"
svcadm restart ${SVC_NAME}
