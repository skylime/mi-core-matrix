#!/bin/bash
UUID=$(mdata-get sdc:uuid)
DDS=zones/${UUID}/data

if zfs list ${DDS} 1>/dev/null 2>&1; then
	zfs create ${DDS}/matrix  || true
	zfs create ${DDS}/pgsql   || true

	if ! zfs get -o value -H mountpoint ${DDS}/matrix | grep -q /opt/matrix; then
		zfs set mountpoint=/opt/matrix ${DDS}/matrix
	fi
	if ! zfs get -o value -H mountpoint ${DDS}/pgsql | grep -q /var/pgsql; then
		zfs set compression=lz4 ${DDS}/pgsql
		zfs set mountpoint=/var/pgsql ${DDS}/pgsql
	fi
fi

chown matrix:matrix /opt/matrix
