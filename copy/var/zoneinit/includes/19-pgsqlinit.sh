#!/usr/bin/env bash

PGSQL_DATADIR=/var/pgsql/data

if [ ! -d ${PGSQL_DATADIR} ]; then
	install -d -u postgres -g postgres ${PGSQL_DATADIR}
	sudo -u postgres initdb -U postgres ${PGSQL_DATADIR}
fi
