#!/usr/bin/env bash
# Initial setup ${APPSERVICE} configuration file if it does not exists

APPSERVICE=heisenbridge
MATRIX_HOME=/opt/local/etc/matrix-synapse

log "Create app configuration folder"
mkdir -p "${MATRIX_HOME}/apps/${APPSERVICE}"

if [ ! -f ${MATRIX_HOME}/apps/${APPSERVICE}/config.yaml ]; then
    /opt/m-app-${APPSERVICE}/env/bin/python \
        -m ${APPSERVICE} -c ${MATRIX_HOME}/apps/${APPSERVICE}/config.yaml --generate
fi

log "Create a apps entry for homeserver (expect it's required)"
mkdir -p "${MATRIX_HOME}/config.d"
grep -q "app_service_config_files:" ${MATRIX_HOME}/config.d/83_app_service_config.yaml 2> /dev/null \
    || echo "app_service_config_files:" > ${MATRIX_HOME}/config.d/83_app_service_config.yaml
echo "  - ${MATRIX_HOME}/apps/${APPSERVICE}/config.yaml" >> ${MATRIX_HOME}/config.d/83_app_service_config.yaml

log "Create homeserver.yaml from include.d/ content"
cat ${MATRIX_CONF}/* > ${MATRIX_CONF}/../homeserver.yaml

log "Fix permissions for all files stored in ${MATRIX_HOME}"
chown -R synapse:synapse ${MATRIX_HOME} ${MATRIX_DATA}

echo "Enable ${APPSERVICE} service"
svcadm enable svc:/matrix/app-${APPSERVICE}:default
