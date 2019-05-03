#!/usr/bin/env bash

SERVER_NAME=$(hostname)
MATRIX_HOME=/opt/matrix
MATRIX_CONF=${MATRIX_HOME}/conf.d

mkdir -p ${MATRIX_CONF} ${MATRIX_HOME}/log

if mdata-get matrix_server_name >/dev/null 2>&1; then
	SERVER_NAME=$(mdata-get matrix_server_name)
fi

log "Generate homeserver.yaml config"
sudo -u matrix \
generate_config \
	--config-dir ${MATRIX_HOME} \
	--data-dir ${MATRIX_HOME}/data \
	--server-name ${SERVER_NAME} \
	--report-stats no \
	--output-file ${MATRIX_HOME}/homeserver.yaml

log "Install matrix synapse key signing key file"
MATRIX_SIGNING_KEY_FILE=${MATRIX_HOME}/${SERVER_NAME}.signing.key
if mdata-get matrix_signing_key >/dev/null 2>&1; then
	mdata-get matrix_signing_key > ${MATRIX_SIGNING_KEY_FILE}
else
	log "Key file doesn't exists, generating it"
	sudo -u matrix \
		python -m synapse.app.homeserver \
	                  -c ${MATRIX_HOME}/homeserver.yaml \
	                  --generate-keys
	cat ${MATRIX_SIGNING_KEY_FILE} | mdata-put matrix_signing_key
fi

log "Add listeners information because ::1 it not working on SmartOS"
cat > ${MATRIX_CONF}/listeners.yaml <<-EOF
listeners:
  - port: 8008
    tls: false
    bind_addresses: ['127.0.0.1']
    type: http
    x_forwarded: true

    resources:
      - names: [client, federation]
        compress: false
EOF

log "Additional base_url needed based on the server_name"
cat > ${MATRIX_CONF}/base_url.yaml <<-EOF
public_baseurl: https://${SERVER_NAME}
EOF

log "Provide own logging configuration file for homeserver"
cat > ${MATRIX_HOME}/${SERVER_NAME}.log.config <<-EOF
version: 1
formatters:
  precise:
   format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(request)s- %(message)s'
filters:
  context:
    (): synapse.util.logcontext.LoggingContextFilter
    request: ""
handlers:
  file:
    class: logging.handlers.RotatingFileHandler
    formatter: precise
    filename: ${MATRIX_HOME}/log/homeserver.log
    maxBytes: 104857600
    backupCount: 10
    filters: [context]
    encoding: utf8
  console:
    class: logging.StreamHandler
    formatter: precise
    level: WARN
loggers:
    synapse:
        level: INFO
    synapse.storage.SQL:
        level: INFO
root:
    level: INFO
    handlers: [file, console]
EOF

log "Generate config file for pgsql connection"
cat > ${MATRIX_CONF}/database.yaml <<-EOF
database:
    name: psycopg2
    args:
        user: synapse
        password: $(mdata-get synapse_pgsql_pw)
        database: synapse
        host: localhost
        cp_min: 5
        cp_max: 10
EOF

if mdata-get mail_adminaddr >/dev/null 2>&1; then
log "Generate config for admin contact details"
cat > ${MATRIX_CONF}/admin.yaml <<-EOF
admin_contact: 'mailto:$(mdata-get mail_adminaddr)'
EOF
fi

if mdata-get mail_smarthost >/dev/null 2>&1 && \
   mdata-get mail_auth_user >/dev/null 2>&1; then
log "Generate config for email setup"
cat > ${MATRIX_CONF}/email.yaml <<-EOF
email:
    enable_notifs: true
    smtp_host: $(mdata-get mail_smarthost)
    smtp_port: 25
    smtp_user: $(mdata-get mail_auth_user)
    smtp_pass: $(mdata-get mail_auth_pass)
    require_transport_security: True
    notif_from: "Matrix %(app)s Home Server <noreply@${SERVER_NAME}>"
    notif_template_html: notif_mail.html
    notif_template_text: notif_mail.txt
EOF
fi

log "Generate and store secrets for matrix server"
MATRIX_REGISTRATION_SHARED_SECRET=$(/opt/core/bin/mdata-create-password.sh -m matrix_registration_shared_secret)
MATRIX_MACAROON_SECRET_KEY=$(/opt/core/bin/mdata-create-password.sh -m matrix_macaroon_secret_key)
cat > ${MATRIX_CONF}/secret.yaml <<-EOF
registration_shared_secret: ${MATRIX_REGISTRATION_SHARED_SECRET}
macaroon_secret_key: ${MATRIX_MACAROON_SECRET_KEY}
EOF

log "Allow of disallow guest access"
MATRIX_ALLOW_GUEST_ACCESS=$(mdata-get matrix_allow_guest_access 2>/dev/null || echo "false")
if [[ "${MATRIX_ALLOW_GUEST_ACCESS,,}" == "true" ]]; then
	echo "allow_guest_access: true" > ${MATRIX_CONF}/guest.yaml
else
	echo "allow_guest_access: false" > ${MATRIX_CONF}/guest.yaml
fi

log "Allow or disallow registration"
MATRIX_ENABLE_REGISTRATION=$(mdata-get matrix_enable_registration 2>/dev/null || echo "false")
if [[ "${MATRIX_ENABLE_REGISTRATION,,}" == "true" ]]; then
	echo "enable_registration: true" > ${MATRIX_CONF}/registration.yaml
else
	echo "enable_registration: false" > ${MATRIX_CONF}/registration.yaml
fi

log "Fix permissions for all files stored in ${MATRIX_HOME}"
chown -R matrix:matrix ${MATRIX_HOME}

log "Enable matrix synapse service"
svcadm enable svc:/application/matrix-synapse:default
