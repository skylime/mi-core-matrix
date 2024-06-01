#!/usr/bin/env bash

SERVER_NAME=$(hostname)
MATRIX_HOME=/opt/local/etc/matrix-synapse
MATRIX_DATA=/var/db/matrix-synapse
MATRIX_CONF=${MATRIX_HOME}/config.d/

if mdata-get matrix_server_name > /dev/null 2>&1; then
    SERVER_NAME=$(mdata-get matrix_server_name)
fi

MATRIX_SIGNING_KEY_FILE=${MATRIX_HOME}/${SERVER_NAME}.signing.key

mkdir -p ${MATRIX_CONF} ${MATRIX_DATA}/log

log "Generate homeserver.yaml config"
cat > ${MATRIX_CONF}/00_default.yaml <<- EOF
server_name: "${SERVER_NAME}"
pid_file: ${MATRIX_DATA}/homeserver.pid
log_config: "${MATRIX_HOME}/${SERVER_NAME}.log.config"
media_store_path: ${MATRIX_DATA}/media_store
report_stats: false
signing_key_path: "${MATRIX_SIGNING_KEY_FILE}"
trusted_key_servers:
  - server_name: "matrix.org"
EOF

log "Install matrix synapse key signing key file"
if mdata-get matrix_signing_key > /dev/null 2>&1; then
    mdata-get matrix_signing_key > ${MATRIX_SIGNING_KEY_FILE}
else
    log "Key file doesn't exists, generating it"
    python -m synapse.app.homeserver \
        -c ${MATRIX_HOME}/homeserver.yaml \
        --generate-keys
    cat ${MATRIX_SIGNING_KEY_FILE} | mdata-put matrix_signing_key
fi

log "Add listeners information because ::1 it not working on SmartOS"
cat > ${MATRIX_CONF}/01_listeners.yaml <<- EOF
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
cat > ${MATRIX_CONF}/02_base_url.yaml <<- EOF
public_baseurl: https://${SERVER_NAME}
EOF

log "Provide own logging configuration file for homeserver"
cat > ${MATRIX_HOME}/${SERVER_NAME}.log.config <<- EOF
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
    filename: ${MATRIX_DATA}/log/homeserver.log
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

log "Add logadm rule for log files"
logadm -w ${MATRIX_DATA}'/log/homeserver.log' -A 7d -p 1d -c -N -m 640

log "Generate config file for pgsql connection"
cat > ${MATRIX_CONF}/10_database.yaml <<- EOF
database:
    name: psycopg2
    args:
        user: synapse
        password: $(mdata-get synapse_pgsql_pw)
        database: synapse
        host: localhost
        cp_min: 5
        cp_max: 10
        # Workaround: Assertion failed: section != NULL, file prof_tree.c, 
        # line 528, function profile_node_iterator
        gssencmode: disable
        sslmode: disable
EOF

if mdata-get mail_adminaddr > /dev/null 2>&1; then
    log "Generate config for admin contact details"
    cat > ${MATRIX_CONF}/50_admin.yaml <<- EOF
admin_contact: 'mailto:$(mdata-get mail_adminaddr)'
suppress_key_server_warning: true
	EOF
fi

if mdata-get mail_smarthost > /dev/null 2>&1 \
    && mdata-get mail_auth_user > /dev/null 2>&1; then
    log "Generate config for email setup"
    cat > ${MATRIX_CONF}/60_email.yaml <<- EOF
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
cat > ${MATRIX_CONF}/80_secret.yaml <<- EOF
registration_shared_secret: ${MATRIX_REGISTRATION_SHARED_SECRET}
macaroon_secret_key: ${MATRIX_MACAROON_SECRET_KEY}
EOF

log "Allow of disallow guest access"
MATRIX_ALLOW_GUEST_ACCESS=$(mdata-get matrix_allow_guest_access 2> /dev/null || echo "false")
if [[ "${MATRIX_ALLOW_GUEST_ACCESS,,}" == "true" ]]; then
    echo "allow_guest_access: true" > ${MATRIX_CONF}/81_guest.yaml
else
    echo "allow_guest_access: false" > ${MATRIX_CONF}/81_guest.yaml
fi

log "Allow or disallow registration"
MATRIX_ENABLE_REGISTRATION=$(mdata-get matrix_enable_registration 2> /dev/null || echo "false")
if [[ "${MATRIX_ENABLE_REGISTRATION,,}" == "true" ]]; then
    echo "enable_registration: true" > ${MATRIX_CONF}/82_registration.yaml
    MATRIX_REGISTRATION_REQUIRES_TOKEN=$(mdata-get matrix_registration_requires_token 2> /dev/null || echo "false")
    if [[ "${MATRIX_REGISTRATION_REQUIRES_TOKEN,,}" == "true" ]]; then
        echo "registration_requires_token: true" >> ${MATRIX_CONF}/82_registration.yaml
    fi
else
    echo "enable_registration: false" > ${MATRIX_CONF}/82_registration.yaml
fi

log "Create homeserver.yaml from include.d/ content"
cat ${MATRIX_CONF}/* > ${MATRIX_CONF}/../homeserver.yaml

log "Fix permissions for all files stored in ${MATRIX_HOME}"
chown -R synapse:synapse ${MATRIX_HOME} ${MATRIX_DATA}

if [ -f "/var/pgsql/backup/dump.sql" ]; then
    log "Require dump.sql to be imported and service startup"
    cp /etc/motd /etc/motd.clean
    cat >> /etc/motd <<- EOF
		 ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
		 ┃ Operation task required:                                           ┃
		 ┃    $ sudo -u synapse psql synapse < /var/pgsql/backup/dump.sql     ┃
		 ┃    $ mv /var/pgsql/backup/{dump.sql,dump_$(date +%Y%m%d).sql}             ┃
		 ┃    $ svcadm enable svc:/pkgsrc/matrix-synapse:default              ┃
		 ┃    $ /opt/core/bin/motd-cleanup                                    ┃
		 ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
	EOF
else
    log "Enable matrix synapse service"
    svcadm enable svc:/pkgsrc/matrix-synapse:default
fi
