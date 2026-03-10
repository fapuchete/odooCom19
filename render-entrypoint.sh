#!/bin/bash
set -e

# Render sets PORT for the web server listening port.
# The original entrypoint uses PORT for the DB port, causing a conflict.
WEB_PORT=${PORT:-8069}

# Database connection from Render environment variables
DB_HOST_VAL=${DB_HOST:-db}
DB_PORT_VAL=${DB_PORT:-5432}
DB_USER_VAL=${DB_USER:-odoo}
DB_PASSWORD_VAL=${DB_PASSWORD:-odoo}
DB_NAME_VAL=${DB_NAME:-}

# Build database connection arguments
DB_ARGS=()
DB_ARGS+=("--db_host" "$DB_HOST_VAL")
DB_ARGS+=("--db_port" "$DB_PORT_VAL")
DB_ARGS+=("--db_user" "$DB_USER_VAL")
DB_ARGS+=("--db_password" "$DB_PASSWORD_VAL")
DB_ARGS+=("--proxy-mode")

# If a specific database name is set, use it directly
if [ -n "$DB_NAME_VAL" ]; then
    DB_ARGS+=("--database" "$DB_NAME_VAL")
    # dbfilter is set via config file, not CLI in Odoo 19
    sed -i "s/^;\? *dbfilter.*/dbfilter = ^${DB_NAME_VAL}\$/" /etc/odoo/odoo.conf || true
fi

# Admin master password for the database manager
if [ -n "$ADMIN_PASSWORD" ]; then
    DB_ARGS+=("--admin_passwd" "$ADMIN_PASSWORD")
fi

# Initialize database with base module on first run
EXTRA_ARGS=()
if [ "${INIT_DB}" = "true" ]; then
    EXTRA_ARGS+=("-i" "base")
fi

case "$1" in
    -- | odoo)
        shift
        wait-for-psql.py --db_host="$DB_HOST_VAL" --db_port="$DB_PORT_VAL" --db_user="$DB_USER_VAL" --db_password="$DB_PASSWORD_VAL" --timeout=30
        exec odoo "$@" "${DB_ARGS[@]}" "${EXTRA_ARGS[@]}" --http-port="$WEB_PORT"
        ;;
    -*)
        wait-for-psql.py --db_host="$DB_HOST_VAL" --db_port="$DB_PORT_VAL" --db_user="$DB_USER_VAL" --db_password="$DB_PASSWORD_VAL" --timeout=30
        exec odoo "$@" "${DB_ARGS[@]}" "${EXTRA_ARGS[@]}" --http-port="$WEB_PORT"
        ;;
    *)
        exec "$@"
esac

exit 1
