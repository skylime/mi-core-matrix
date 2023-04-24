#!/usr/bin/env bash

PGSQL_DUMPFILE=/var/pgsql/backup/dump.sql
PGSQL_DATADIR=/var/pgsql/data

if [ -f "${PGSQL_DUMPFILE}" ]; then
  log "removing pgsql data directory because of dump file exists"
  rm -rf ${PGSQL_DATADIR}
fi

if [ ! -d ${PGSQL_DATADIR} ]; then
	install -d -u postgres -g postgres ${PGSQL_DATADIR}
	sudo -u postgres initdb -U postgres ${PGSQL_DATADIR}
fi
