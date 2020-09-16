#!/usr/bin/env bash
# Configure riot-web interface

SERVER_NAME=$(hostname)
if mdata-get matrix_server_name >/dev/null 2>&1; then
	SERVER_NAME=$(mdata-get matrix_server_name)
fi

log "Place config.json to riot-web folder"
cat > /var/www/config.json <<-EOF
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "https://${SERVER_NAME}",
            "server_name": "${SERVER_NAME}"
        },
        "m.identity_server": {
            "base_url": "https://vector.im"
        }
    },
    "disable_custom_urls": false,
    "disable_guests": false,
    "disable_login_language_selector": false,
    "disable_3pid_login": false,
    "brand": "Element",
    "integrations_ui_url": "https://scalar.vector.im/",
    "integrations_rest_url": "https://scalar.vector.im/api",
    "integrations_widgets_urls": [
        "https://scalar.vector.im/_matrix/integrations/v1",
        "https://scalar.vector.im/api",
        "https://scalar-staging.vector.im/_matrix/integrations/v1",
        "https://scalar-staging.vector.im/api",
        "https://scalar-staging.riot.im/scalar/api"
    ],
    "bug_report_endpoint_url": "https://element.io/bugreports/submit",
    "defaultCountryCode": "GB",
    "showLabsSettings": true,
    "features": {
        "feature_new_spinner": false
    },
    "default_federate": true,
    "default_theme": "light",
    "roomDirectory": {
        "servers": [
            "${SERVER_NAME}",
            "matrix.org"
        ]
    },
    "welcomeUserId": "@riot-bot:${SERVER_NAME}",
    "piwik": { },
    "enable_presence_by_hs_url": {
        "https://${SERVER_NAME}": false
    },
    "settingDefaults": {
        "breadcrumbs": true
    },
    "jitsi": { }
}
EOF

log "Clean welcome.html because of disabled guest access"
gsed -n -i '1,/<!-- BEGIN Ansible/p;/<!-- END Ansible/,$p' \
	/var/www/welcome.html
