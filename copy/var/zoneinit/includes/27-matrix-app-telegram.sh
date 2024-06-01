#!/usr/bin/env bash

log "create user and database for m-app-mautrix-telegram"
if ! psql -U postgres -lqt | cut -d \| -f 1 | grep -qw m-app-mautrix-telegram 2> /dev/null; then
    export PGPASSWORD=$(mdata-get pgsql_pw)
    createuser -U postgres -s m-app-mautrix-telegram
    createdb m-app-mautrix-telegram -U postgres -O m-app-mautrix-telegram \
        --encoding=UTF8 --locale=C --template=template0

    if USER_PGSQL_PW=$(/opt/core/bin/mdata-create-password.sh -m m_app_mautrix_telegram_pgsql_pw 2> /dev/null); then
        psql -U m-app-mautrix-telegram -d m-app-mautrix-telegram -c "alter user postgres with password '${USER_PGSQL_PW}';"
    fi
fi

log "create app configuartion file"
log "create app registration file"
