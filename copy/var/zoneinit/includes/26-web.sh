#!/usr/bin/env bash
# Configure riot-web interface

SERVER_NAME=$(hostname)
if mdata-get matrix_server_name >/dev/null 2>&1; then
	SERVER_NAME=$(mdata-get matrix_server_name)
fi

log "Modify config.json to riot-web folder"
gsed -i \
  "s/_SERVER_NAME_/${SERVER_NAME}/g" /var/www/config.json
