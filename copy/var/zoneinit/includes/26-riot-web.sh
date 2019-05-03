#!/usr/bin/env bash
# Configure riot-web interface

SERVER_NAME=$(hostname)
if mdata-get matrix_server_name >/dev/null 2>&1; then
	SERVER_NAME=$(mdata-get matrix_server_name)
fi

log "Place config.json to riot-web folder"
cat > /var/www/config.json <<-EOF
{
    "default_hs_url": "https://${SERVER_NAME}",
    "default_is_url": "https://vector.im",
    "disable_guest": true,
    "disable_3pid_login": true,
    "default_federate": false,
    "disable_custom_urls": true,
    "features": {
        "feature_rich_quoting": "labs",
        "feature_pinning": "labs",
        "feature_presence_management": "labs",
        "feature_sticker_messages": "labs",
        "feature_jitsi": "labs",
        "feature_tag_panel": "enable",
        "feature_keybackup": "labs",
        "feature_custom_status": "labs",
        "feature_custom_tags": "labs",
        "feature_lazyloading": "enable",
        "feature_tabbed_settings": "labs",
        "feature_sas": "labs",
        "feature_room_breadcrumbs": "labs",
        "feature_state_counters": "labs"
    },
    "brand": "Riot",
    "branding": {
        "welcomeBackgroundUrl": "",
        "authHeaderLogoUrl": "",
        "authFooterLinks": { }
    },
    "integrations_ui_url": "",
    "integrations_rest_url": "",
    "integrations_widgets_urls": [],
    "default_theme": "dark",
    "cross_origin_renderer_url": "https://usercontent.riot.im/v1.html",
    "piwik": false,
    "welcomeUserId": "",
    "enable_presence_by_hs_url": {
        "https://matrix.org": false
    },
    "terms_and_conditions_links": []
}
EOF

log "Clean welcome.html because of disabled guest access"
gsed -in '1,/<!-- BEGIN Ansible/p;/<!-- END Ansible/,$p' \
	/var/www/welcome.html
