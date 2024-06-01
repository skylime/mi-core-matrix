#!/bin/bash
UUID=$(mdata-get sdc:uuid)
DDS=zones/${UUID}/data

if zfs list ${DDS} 1> /dev/null 2>&1; then
    zfs create ${DDS}/matrix_data || true
    zfs create ${DDS}/matrix_apps_config || true
    zfs create ${DDS}/pgsql || true

    if ! zfs get -o value -H mountpoint ${DDS}/matrix_data | grep -q /var/db/matrix-synapse; then
        zfs set mountpoint=/var/db/matrix-synapse ${DDS}/matrix_data
    fi
    if ! zfs get -o value -H mountpoint ${DDS}/matrix_apps_config | grep -q /opt/local/etc/matrix-synapse/apps; then
        zfs set mountpoint=/opt/local/etc/matrix-synapse/apps ${DDS}/matrix_apps_config
    fi
    if ! zfs get -o value -H mountpoint ${DDS}/pgsql | grep -q /var/pgsql; then
        zfs set compression=lz4 ${DDS}/pgsql
        zfs set mountpoint=/var/pgsql ${DDS}/pgsql
    fi
fi

chown synapse:synapse /var/db/matrix-synapse
