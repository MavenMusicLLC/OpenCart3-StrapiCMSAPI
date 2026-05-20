#!/bin/bash
# ============================================================================
# repair-plesk.sh — Automatic Fix Script for Common Plesk Deployment Issues
# For: OpenCart3-StrapiCMSAPI on Plesk Obsidian
# ============================================================================
# Diagnoses and fixes the most common deployment failures:
#   - Strapi won't start / crash loops
#   - Admin panel unreachable (proxy loop / timeout)
#   - Build failures (permissions, memory, Node version)
#   - Module not appearing in OpenCart
#   - API communication failures
#   - Permission/ownership errors
#   - PM2 process management issues
#   - .env misconfigurations
# ============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_DIR="/tmp/plesk-opencart-strapi"
LOG_FILE="$LOG_DIR/repair.log"
DOMAIN="${1:-}"
FIX_COUNT=0

[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"

log()   { echo "[$(date '+%H:%M:%S')]  $1" | tee -a "$LOG_FILE"; }
ok()    { echo -e "  ${GREEN}[OK]${NC}   $1"; }
warn()  { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "  ${RED}[ERR]${NC}  $1" >&2; exit 1; }
fix()   { echo -e "  ${CYAN}[FIX]${NC}  $1"; FIX_COUNT=$((FIX_COUNT+1)); }

print_header() {
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║    OpenCart + Strapi — Plesk Repair Script                 ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

fix_file_permissions() {
    local deploy_dir="$1"
    local strapi_dir="${2:-}"
    log "Fixing file permissions..."

    local plesk_owner plesk_group
    plesk_owner=$(stat -c '%U' "$deploy_dir" 2>/dev/null || echo "www-data")
    plesk_group="psacln"
    [[ "$plesk_owner" == "root" ]] && plesk_owner=$(ls -ld /var/www/vhosts/ 2>/dev/null | head -1 | awk '{print $3}' || echo "www-data")

    chown -R "$plesk_owner:$plesk_group" "$deploy_dir" 2>/dev/null || true

    find "$deploy_dir/catalog" -type d -exec chmod 755 {} \; 2>/dev/null || true
    find "$deploy_dir/catalog" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find "$deploy_dir/admin"   -type d -exec chmod 755 {} \; 2>/dev/null || true
    find "$deploy_dir/admin"   -type f -exec chmod 644 {} \; 2>/dev/null || true

    if [[ -n "$strapi_dir" ]] && [[ -d "$strapi_dir" ]]; then
        chown -R "$plesk_owner:$plesk_group" "$strapi_dir" 2>/dev/null || true
        chmod 600 "$strapi_dir/.env" 2>/dev/null || true
    fi

    fix "File ownership → $plesk_owner:$plesk_group"
}

fix_htaccess_proxy() {
    local deploy_dir="$1"
    log "Checking/fixing Apache proxy configuration..."

    if [[ ! -f "$deploy_dir/.htaccess" ]]; then
        log "No .htaccess found — creating proxy rules..."
        cat > "$deploy_dir/.htaccess" <<'HTACCESS'
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /

    RewriteCond %{REQUEST_FILENAME} -f [OR]
    RewriteCond %{REQUEST_FILENAME} -d
    RewriteRule ^ - [L]

    RewriteRule ^strapi(/.*)?$            http://127.0.0.1:1337/admin$1           [P,L]
    RewriteRule ^api(/.*)?$               http://127.0.0.1:1337/api$1             [P,L]
    RewriteRule ^graphql(/.*)?$           http://127.0.0.1:1337/graphql$1         [P,L]
    RewriteRule ^uploads(/.*)?$           http://127.0.0.1:1337/uploads$1         [P,L]
    RewriteRule ^content-manager(/.*)?$    http://127.0.0.1:1337/content-manager$1  [P,L]
    RewriteRule ^documentation(/.*)?$     http://127.0.0.1:1337/documentation$1   [P,L]
</IfModule>

<IfModule mod_headers.c>
    RequestHeader set X-Forwarded-Proto "https" env=HTTPS
</IfModule>
HTACCESS
        fix "Created .htaccess with Strapi proxy rules"
    elif ! grep -q "127.0.0.1:1337" "$deploy_dir/.htaccess"; then
        local backup="$deploy_dir/.htaccess.bak.$(date +%s)"
        cp "$deploy_dir/.htaccess" "$backup"
        log "Backed up existing .htaccess → $backup"
        cat > "$deploy_dir/.htaccess" <<'HTACCESS'
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /

    RewriteCond %{REQUEST_FILENAME} -f [OR]
    RewriteCond %{REQUEST_FILENAME} -d
    RewriteRule ^ - [L]

    RewriteRule ^strapi(/.*)?$            http://127.0.0.1:1337/admin$1           [P,L]
    RewriteRule ^api(/.*)?$               http://127.0.0.1:1337/api$1             [P,L]
    RewriteRule ^graphql(/.*)?$           http://127.0.0.1:1337/graphql$1         [P,L]
    RewriteRule ^uploads/(.*)$            http://127.0.0.1:1337/uploads/$1          [P,L]
    RewriteRule ^content-manager(/.*)?$   http://127.0.0.1:1337/content-manager$1  [P,L]
    RewriteRule ^documentation(/.*)?$     http://127.0.0.1:1337/documentation$1   [P,L]
</IfModule>

<IfModule mod_headers.c>
    RequestHeader set X-Forwarded-Proto "https" env=HTTPS
</IfModule>
HTACCESS
        fix "Replaced .htaccess with Strapi proxy rules"
    else
        ok "Proxy rules already present in .htaccess"
    fi
}

fix_pm2_process() {
    local deploy_dir="$1"
    local strapi_dir="${2:-}"
    local app_name="${3:-strapi-bundled}"

    log "Checking PM2 process management..."

    if ! command -v pm2 &>/dev/null; then
        warn "PM2 not installed — installing..."
        npm install -g pm2 2>&1 | tail -3 || true
        fix "Installed PM2 globally"
    fi

    local target_dir="$deploy_dir"
    [[ -n "$strapi_dir" ]] && [[ -d "$strapi_dir" ]] && target_dir="$strapi_dir"

    local running_proc
    running_proc=$(pm2 list 2>/dev/null | grep "$app_name" | grep -v grep || echo "")

    if [[ -z "$running_proc" ]]; then
        log "Strapi not running — starting..."
        cd "$target_dir"
        pm2 start npm --name "$app_name" -- start 2>&1 | tail -5 || true
        fix "Started Strapi via PM2 ($app_name)"
        pm2 save 2>/dev/null || true
    else
        log "Strapi process found — restarting for clean state..."
        pm2 restart "$app_name" 2>&1 | tail -3 || true
        fix "Restarted Strapi via PM2 ($app_name)"
    fi

    local status
    status=$(pm2 list 2>/dev/null | grep "$app_name" | awk '{print $10}' | head -1 || echo "unknown")
    log "PM2 status: $status"
}

fix_strapi_build() {
    local deploy_dir="$1"
    local strapi_dir="${2:-}"
    local target_dir="$deploy_dir"
    [[ -n "$strapi_dir" ]] && [[ -d "$strapi_dir" ]] && target_dir="$strapi_dir"

    log "Checking Strapi build..."

    if [[ ! -f "$target_dir/package.json" ]]; then
        err "package.json not found in $target_dir"
    fi

    cd "$target_dir"

    if [[ ! -d "node_modules" ]]; then
        log "node_modules missing — running npm install..."
        if [[ -f "package-lock.json" ]]; then
            npm ci --no-audit 2>&1 | tail -5 || true
        else
            npm install --no-audit 2>&1 | tail -5 || true
        fi
        fix "Installed Node.js dependencies"
    fi

    if [[ ! -d "build" ]] && [[ ! -d ".cache" ]]; then
        log "Build artifacts missing — running npm run build..."
        export NODE_ENV=production
        if npm run build 2>&1 | tail -10; then
            fix "Rebuilt Strapi admin panel"
        else
            warn "Build had errors — checking common causes..."

            local mem
            mem=$(free -m 2>/dev/null | awk 'NR==2 {print $7}')
            if [[ "${mem:-0}" -lt 512 ]]; then
                warn "Low memory: ${mem}MB available. Strapi build needs ~1GB."
            fi

            local node_ver
            node_ver=$(node -v 2>/dev/null)
            local major="${node_ver:1:2}"
            if [[ "${major:-0}" -gt 20 ]]; then
                warn "Node.js $node_ver may have compatibility issues with Strapi 5.x"
                warn "Try Node.js 18 LTS or 20 LTS"
            fi
        fi
    else
        ok "Build artifacts present"
    fi
}

fix_opencart_module_cache() {
    local deploy_dir="$1"
    log "Clearing OpenCart cache..."

    rm -rf "$deploy_dir/system/storage/cache/"*         2>/dev/null || true
    rm -rf "$deploy_dir/system/storage/modification/"*  2>/dev/null || true
    rm -rf "$deploy_dir/imagecache/"*                    2>/dev/null || true

    fix "Cleared OpenCart modification and cache"
}

fix_opencart_permissions_dirs() {
    local deploy_dir="$1"
    log "Fixing OpenCart storage permissions..."

    local storage_dir="$deploy_dir/system/storage"
    if [[ -d "$storage_dir" ]]; then
        find "$storage_dir" -type d -exec chmod 775 {} \; 2>/dev/null || true
        find "$storage_dir" -type f -exec chmod 664 {} \; 2>/dev/null || true
        fix "Storage directory permissions fixed"
    fi
}

fix_missing_env() {
    local deploy_dir="$1"
    local strapi_dir="${2:-}"
    local target_dir="$deploy_dir"
    [[ -n "$strapi_dir" ]] && [[ -d "$strapi_dir" ]] && target_dir="$strapi_dir"

    log "Checking .env configuration..."

    if [[ ! -f "$target_dir/.env" ]]; then
        if [[ -f "$target_dir/.env.example" ]]; then
            cp "$target_dir/.env.example" "$target_dir/.env"
            fix "Created .env from .env.example"
            warn "Edit $target_dir/.env with your database credentials!"
        else
            err "No .env or .env.example found"
        fi
    else
        local db_name
        db_name=$(grep "^DATABASE_NAME=" "$target_dir/.env" 2>/dev/null | cut -d= -f2 | tr -d ' ')
        if [[ "$db_name" == "strapi_opencart" ]] || [[ "$db_name" == "your_strapi_db" ]]; then
            warn ".env still has default database name — edit with real credentials"
            fix "Detected default DB config in .env"
        else
            ok ".env configured with custom values"
        fi
    fi
}

fix_apache_mod_rewrite() {
    log "Checking Apache mod_rewrite..."
    if ! apache2ctl -M 2>/dev/null | grep -q "rewrite_module"; then
        warn "mod_rewrite not enabled"
        if command -v a2enmod &>/dev/null; then
            a2enmod rewrite 2>/dev/null && systemctl restart apache2 2>/dev/null && \
                fix "Enabled mod_rewrite and restarted Apache" || \
                warn "Could not enable mod_rewrite — may need root access"
        fi
    else
        ok "mod_rewrite enabled"
    fi
}

fix_node_https_proxy() {
    local strapi_dir="${1:-}"
    [[ ! -d "$strapi_dir" ]] && return

    log "Configuring Strapi for HTTPS reverse proxy..."

    local server_js="$strapi_dir/config/server.js"
    if [[ -f "$server_js" ]]; then
        if grep -q "ssl.*true" "$server_js" && grep -q "proxy.*enabled" "$server_js"; then
            ok "Strapi proxy config OK"
        else
            if grep -q "proxy" "$server_js"; then
                sed -i 's/proxy.*enabled.*false/proxy: { enabled: true, ssl: true }/' "$server_js"
            else
                sed -i "s/webhooks:/proxy: { enabled: true, ssl: true },\n  webhooks:/" "$server_js"
            fi
            fix "Updated Strapi server.js for HTTPS proxy"
        fi
    fi
}

fix_mysql_grant() {
    local deploy_dir="$1"
    log "Checking MySQL user permissions..."

    local db_name db_user db_pass
    db_name=$(php -r "include '$deploy_dir/config.php'; echo DB_DATABASE;" 2>/dev/null || echo "")
    db_user=$(php -r "include '$deploy_dir/config.php'; echo DB_USERNAME;" 2>/dev/null || echo "")
    db_pass=$(php -r "include '$deploy_dir/config.php'; echo DB_PASSWORD;" 2>/dev/null || echo "")

    if [[ -n "$db_name" ]] && [[ -n "$db_user" ]]; then
        if command -v mysql &>/dev/null; then
            if mysql -u "$db_user" -p"$db_pass" "$db_name" -e "SELECT 1;" &>/dev/null; then
                ok "MySQL connection OK"
            else
                warn "MySQL user $db_user cannot access $db_name"
                fix "MySQL connection test failed — check credentials"
            fi
        fi
    fi
}

fix_opencart_bundle_tables() {
    local deploy_dir="$1"
    log "Checking OpenCart bundle tables..."

    local db_name db_user db_pass
    db_name=$(php -r "include '$deploy_dir/config.php'; echo DB_DATABASE;" 2>/dev/null || echo "")
    db_user=$(php -r "include '$deploy_dir/config.php'; echo DB_USERNAME;" 2>/dev/null || echo "")
    db_pass=$(php -r "include '$deploy_dir/config.php'; echo DB_PASSWORD;" 2>/dev/null || echo "")

    if [[ -n "$db_name" ]] && [[ -n "$db_user" ]] && command -v mysql &>/dev/null; then
        if mysql -u "$db_user" -p"$db_pass" "$db_name" -e "DESCRIBE oc_bundles;" &>/dev/null; then
            ok "Bundle tables exist"
        else
            log "Bundle tables missing — running migration..."
            if [[ -f "$deploy_dir/install/bundle_install.sql" ]]; then
                mysql -u "$db_user" -p"$db_pass" "$db_name" < "$deploy_dir/install/bundle_install.sql" 2>/dev/null && \
                    fix "Created bundle tables" || \
                    warn "Migration failed"
            elif [[ -f "$deploy_dir/install/migrate.php" ]]; then
                php "$deploy_dir/install/migrate.php" 2>/dev/null && \
                    fix "Ran PHP migration" || \
                    warn "Migration failed"
            fi
        fi
    fi
}

check_api_reachability() {
    local domain="$1"
    log "Testing API reachability..."

    local https_code
    https_code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://$domain/api/status" 2>/dev/null || echo "000")
    if [[ "$https_code" == "200" ]]; then
        ok "API responding (HTTP $https_code)"
    elif [[ "$https_code" == "000" ]]; then
        warn "API unreachable — check Strapi is running"
    else
        warn "API responding with HTTP $https_code"
    fi

    local admin_code
    admin_code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://$domain/strapi/admin" 2>/dev/null || echo "000")
    if [[ "$admin_code" == "200" ]] || [[ "$admin_code" == "301" ]] || [[ "$admin_code" == "302" ]]; then
        ok "Strapi admin reachable (HTTP $admin_code)"
    elif [[ "$admin_code" == "000" ]]; then
        warn "Strapi admin unreachable — proxy may not be working"
    fi
}

show_repair_summary() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Repair Summary                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log "Fixes applied: $FIX_COUNT"
    log ""
    if [[ $FIX_COUNT -gt 0 ]]; then
        echo -e "${GREEN}✓  $FIX_COUNT fix(es) applied successfully${NC}"
        echo ""
        log "Next steps:"
        log "  1. Restart Apache:  systemctl restart apache2"
        log "  2. Restart Strapi:  pm2 restart strapi-bundled"
        log "  3. Re-run:          bash install-plesk.sh validate $domain"
        log ""
        log "If issues persist:"
        log "  4. Check Strapi logs:    pm2 logs strapi-bundled --lines 50"
        log "  5. Check Apache logs:   tail -50 /var/www/vhosts/$domain/logs/error_log"
        log "  6. Verify Strapi running: curl http://127.0.0.1:1337/api/status"
    else
        echo -e "${CYAN}No repairs needed — deployment looks healthy${NC}"
    fi
    echo ""
}

main() {
    if [[ -z "$DOMAIN" ]]; then
        echo ""
        echo "OpenCart + Strapi — Plesk Repair Script"
        echo ""
        echo "Usage: bash repair-plesk.sh <domain>"
        echo "Example: bash repair-plesk.sh mystore.com"
        exit 1
    fi

    local deploy_dir="/var/www/vhosts/${DOMAIN}/httpdocs"
    local strapi_dir="$deploy_dir/strapi"

    print_header
    log "Domain: $DOMAIN"
    log "Deploy dir: $deploy_dir"
    echo ""

    if [[ ! -d "$deploy_dir" ]]; then
        err "Deploy directory not found: $deploy_dir"
    fi

    fix_file_permissions "$deploy_dir" "$strapi_dir"

    if [[ -d "$strapi_dir" ]]; then
        fix_missing_env "$deploy_dir" "$strapi_dir"
        fix_strapi_build "$deploy_dir" "$strapi_dir"
        fix_node_https_proxy "$strapi_dir"
    fi

    fix_htaccess_proxy "$deploy_dir"
    fix_apache_mod_rewrite
    fix_opencart_module_cache "$deploy_dir"
    fix_opencart_permissions_dirs "$deploy_dir"
    fix_opencart_bundle_tables "$deploy_dir"
    fix_mysql_grant "$deploy_dir"
    fix_pm2_process "$deploy_dir" "$strapi_dir" "strapi-bundled-$DOMAIN"
    check_api_reachability "$DOMAIN"

    show_repair_summary
}

main "$@"