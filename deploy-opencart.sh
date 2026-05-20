#!/bin/bash
# ============================================================================
# deploy-opencart.sh — Deploy OpenCart 3.x on Plesk (Full Installation)
# For: OpenCart3-StrapiCMSAPI on Plesk Obsidian
# ============================================================================
# Fully deploys OpenCart 3.x on a Plesk domain from scratch.
# Downloads OpenCart, configures database, sets permissions, and optionally
# applies the Bundle Manager module + Strapi API integration.
#
# Usage:
#   bash deploy-opencart.sh <domain> [--db-name <name>] [--db-user <user>]
#   bash deploy-opencart.sh <domain> --with-bundle --strapi-url <url>
#   bash deploy-opencart.sh <domain> --skip-bundle
# ============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

LOG_DIR="/tmp/plesk-opencart-strapi"
LOG_FILE="$LOG_DIR/opencart-deploy.log"
[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"

log()   { echo "[$(date '+%H:%M:%S')]  $1" | tee -a "$LOG_FILE"; }
ok()    { echo -e "  ${GREEN}[OK]${NC}   $1"; }
warn()  { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "  ${RED}[ERR]${NC}  $1" >&2; exit 1; }
step()  { echo -e "  ${MAGENTA}[STEP]${NC} $1"; }
info()  { echo -e "  ${BLUE}[INFO]${NC} $1"; }

OPENCART_VERSION="3.0.3.10"
OPENCART_URL="https://github.com/opencart/opencart/releases/download/${OPENCART_VERSION}/opencart-${OPENCART_VERSION}.zip"
DOMAIN=""
DEPLOY_DIR=""
OPENCART_DIR=""
HTTPDOCS=""
DB_NAME=""
DB_USER=""
DB_PASS=""
WITH_BUNDLE=false
BUNDLE_BRANCH="main"
BUNDLE_REPO="https://github.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI.git"
STRAPI_URL=""
PLESK_OWNER=""
PLESK_GROUP="psacln"

print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    OpenCart 3.x — Plesk Full Deployment Script              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_footer() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              OpenCart Deployment Complete!                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ── Parse Arguments ──────────────────────────────────────────────────────

parse_args() {
    if [[ $# -lt 1 ]]; then
        print_usage
        exit 1
    fi

    DOMAIN="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --db-name)
                DB_NAME="$2"; shift 2 ;;
            --db-user)
                DB_USER="$2"; shift 2 ;;
            --db-pass)
                DB_PASS="$2"; shift 2 ;;
            --with-bundle)
                WITH_BUNDLE=true; shift ;;
            --strapi-url)
                STRAPI_URL="$2"; shift 2 ;;
            --bundle-repo)
                BUNDLE_REPO="$2"; shift 2 ;;
            --bundle-branch)
                BUNDLE_BRANCH="$2"; shift 2 ;;
            --skip-bundle)
                WITH_BUNDLE=false; shift ;;
            --help|-h)
                print_usage; exit 0 ;;
            *)
                err "Unknown argument: $1" ;;
        esac
    done

    DEPLOY_DIR="/var/www/vhosts/${DOMAIN}"
    HTTPDOCS="$DEPLOY_DIR/httpdocs"
}

print_usage() {
    echo ""
    echo "OpenCart 3.x — Plesk Full Deployment"
    echo ""
    echo "Usage: bash deploy-opencart.sh <domain> [options]"
    echo ""
    echo "Required:"
    echo "  domain                 Domain name (e.g. mystore.com)"
    echo ""
    echo "Options:"
    echo "  --db-name <name>       Database name (auto-generated if omitted)"
    echo "  --db-user <user>       Database user (auto-generated if omitted)"
    echo "  --db-pass <pass>       Database password (auto-generated if omitted)"
    echo "  --with-bundle          Install Bundle Manager + connect to Strapi"
    echo "  --strapi-url <url>     Strapi API URL (e.g. https://api.mystore.com/api)"
    echo "  --bundle-repo <url>    Bundle module repo (default: MavenMusic repo)"
    echo "  --bundle-branch <name> Bundle branch (default: main)"
    echo "  --skip-bundle          Skip Bundle Manager installation"
    echo ""
    echo "Examples:"
    echo "  # Minimal deploy"
    echo "  bash deploy-opencart.sh mystore.com"
    echo ""
    echo "  # Deploy with Bundle Manager connected to Strapi"
    echo "  bash deploy-opencart.sh mystore.com --with-bundle --strapi-url https://api.mystore.com/api"
    echo ""
    echo "  # Deploy with custom DB credentials"
    echo "  bash deploy-opencart.sh mystore.com --db-name opencart_db --db-user admin_db --db-pass MySecurePass"
}

# ── Pre-flight Checks ──────────────────────────────────────────────────────

preflight_checks() {
    step "Running pre-flight checks..."

    if [[ ! -d "$DEPLOY_DIR" ]]; then
        err "Plesk domain not found: $DEPLOY_DIR"
    fi

    if [[ -n "$(ls -A "$HTTPDOCS" 2>/dev/null)" ]]; then
        warn "httpdocs is not empty. This script will install OpenCart into httpdocs."
        warn "Existing files will be preserved but may conflict."
        read -p "Continue? (y/N): " -n 1 -r </dev/tty
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            err "Aborted. Empty httpdocs first: rm -rf $HTTPDOCS/*"
        fi
    fi

    detect_owner

    if ! command -v php &>/dev/null; then
        err "PHP not found"
    fi

    local php_ver
    php_ver=$(php -r 'echo PHP_VERSION;' 2>/dev/null)
    local php_major
    php_major=$(php -r 'echo PHP_MAJOR_VERSION;' 2>/dev/null)
    log "PHP $php_ver"
    if [[ "$php_major" -lt 7 ]]; then
        err "PHP 7+ required (found $php_ver)"
    fi

    for ext in pdo_mysql gd curl json mbstring zip openssl; do
        if ! php -m 2>/dev/null | grep -qi "$ext"; then
            warn "PHP extension '$ext' not loaded"
        fi
    done

    if ! command -v unzip &>/dev/null; then
        err "unzip not found (apt install unzip)"
    fi

    if ! command -v curl &>/dev/null; then
        err "curl not found"
    fi

    ok "Pre-flight checks passed"
}

detect_owner() {
    PLESK_OWNER=$(stat -c '%U' "$DEPLOY_DIR" 2>/dev/null || echo "www-data")
    PLESK_GROUP="psacln"
    if [[ "$PLESK_OWNER" == "root" ]]; then
        PLESK_OWNER=$(ls -ld /var/www/vhosts/ 2>/dev/null | head -1 | awk '{print $3}' || echo "www-data")
    fi
    log "Plesk owner: $PLESK_OWNER"
}

# ── Database Setup ───────────────────────────────────────────────────────

setup_database() {
    step "Setting up MySQL database..."

    if [[ -z "$DB_NAME" ]]; then
        DB_NAME="oc_$(echo "$DOMAIN" | tr '.' '_' | tr '-' '_')"
    fi
    if [[ -z "$DB_USER" ]]; then
        DB_USER="${DB_NAME}"
    fi
    if [[ -z "$DB_PASS" ]]; then
        DB_PASS=$(openssl rand -base64 24 2>/dev/null || node -e "process.stdout.write(require('crypto').randomBytes(18).toString('base64'))")
    fi

    log "Database: $DB_NAME"
    log "User: $DB_USER"

    if command -v mysql &>/dev/null; then
        if mysql -u root -e "USE $DB_NAME;" 2>/dev/null; then
            warn "Database '$DB_NAME' already exists"
        else
            mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" 2>/dev/null && \
                ok "Database created" || warn "Could not create DB as root — create manually in Plesk"
        fi

        if mysql -u root -e "SELECT 1 FROM mysql.user WHERE User='$DB_USER';" 2>/dev/null | grep -q 1; then
            ok "Database user exists"
        else
            mysql -u root -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" 2>/dev/null && \
                ok "User created" || warn "Could not create user — create manually in Plesk"
        fi

        mysql -u root -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';" 2>/dev/null && \
            mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null && \
            ok "Privileges granted" || warn "Could not grant privileges — do manually in Plesk"

    elif command -v mariadb &>/dev/null; then
        if mariadb -u root -e "USE $DB_NAME;" 2>/dev/null; then
            ok "Database exists"
        else
            mariadb -u root -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" 2>/dev/null && \
                ok "Database created" || warn "Create database in Plesk panel"
        fi
    else
        warn "MySQL CLI not available — create database manually in Plesk"
        warn "Database name: $DB_NAME"
        warn "Database user: $DB_USER"
        warn "Database password: $DB_PASS"
    fi

    save_db_info
}

save_db_info() {
    local db_info_file="$LOG_DIR/db-${DOMAIN}.info"
    cat > "$db_info_file" <<EOF
# OpenCart Database Info — $DOMAIN
# Generated: $(date)
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_HOST=localhost
EOF
    chmod 600 "$db_info_file"
    log "DB info saved to: $db_info_file"
}

# ── Download OpenCart ────────────────────────────────────────────────────

download_opencart() {
    step "Downloading OpenCart $OPENCART_VERSION..."
    local tmp_zip="/tmp/opencart-${OPENCART_VERSION}.zip"

    if [[ -f "$tmp_zip" ]]; then
        ok "OpenCart archive already downloaded"
    else
        curl -sL --max-time 120 -o "$tmp_zip" "$OPENCART_URL" || \
            err "Failed to download OpenCart from $OPENCART_URL"
        ok "Downloaded OpenCart $OPENCART_VERSION"
    fi

    step "Extracting OpenCart to httpdocs..."
    unzip -q -o "$tmp_zip" -d "$HTTPDOCS" 2>/dev/null || err "Failed to extract OpenCart"

    local upload_dir="$HTTPDOCS/upload"
    if [[ -d "$upload_dir" ]]; then
        mv "$upload_dir"/* "$HTTPDOCS/" 2>/dev/null || true
        rm -rf "$upload_dir"
    fi

    local opencart_admin="${HTTPDOCS}/admin"
    if [[ -d "$opencart_admin" ]] && [[ -d "$HTTPDOCS/opencart" ]]; then
        mv "$HTTPDOCS/opencart/"* "$HTTPDOCS/" 2>/dev/null || true
        rm -rf "$HTTPDOCS/opencart"
    fi

    ok "OpenCart extracted"
}

# ── Configure OpenCart ─────────────────────────────────────────────────────

configure_opencart() {
    step "Configuring OpenCart..."

    local config_php="$HTTPDOCS/config.php"
    local admin_config="$HTTPDOCS/admin/config.php"

    if [[ ! -f "$config_php" ]]; then
        err "config.php not found after extraction"
    fi

    local https_url="https://${DOMAIN}"

    cat > "$config_php" <<EOF
<?php
// HTTP
define('HTTP_SERVER', '$https_url/');

// HTTPS
define('HTTPS_SERVER', '$https_url/');

// DIR
define('DIR_APPLICATION', '$HTTPDOCS/catalog/');
define('DIR_SYSTEM', '$HTTPDOCS/system/');
define('DIR_IMAGE', '$HTTPDOCS/image/');
define('DIR_STORAGE', '$HTTPDOCS/storage/');
define('DIR_LANGUAGE', '$HTTPDOCS/catalog/language/');
define('DIR_TEMPLATE', '$HTTPDOCS/catalog/view/theme/');
define('DIR_CONFIG', '$HTTPDOCS/system/config/');
define('DIR_CACHE', '$HTTPDOCS/system/storage/cache/');
define('DIR_DOWNLOAD', '$HTTPDOCS/system/storage/download/');
define('DIR_LOGS', '$HTTPDOCS/system/storage/logs/');
define('DIR_MODIFICATION', '$HTTPDOCS/system/storage/modification/');
define('DIR_UPLOAD', '$HTTPDOCS/system/storage/upload/');

// DB
define('DB_DRIVER', 'pdo');
define('DB_HOSTNAME', 'localhost');
define('DB_USERNAME', '$DB_USER');
define('DB_PASSWORD', '$DB_PASS');
define('DB_DATABASE', '$DB_NAME');
define('DB_PORT', '3306');
define('DB_PREFIX', 'oc_');
EOF
    ok "config.php created"

    if [[ -f "$admin_config" ]]; then
        cat > "$admin_config" <<EOF
<?php
// HTTP
define('HTTP_SERVER', '$https_url/admin/');
define('HTTP_CATALOG', '$https_url/');

// HTTPS
define('HTTPS_SERVER', '$https_url/admin/');
define('HTTPS_CATALOG', '$https_url/');

// DIR
define('DIR_APPLICATION', '$HTTPDOCS/admin/');
define('DIR_SYSTEM', '$HTTPDOCS/system/');
define('DIR_IMAGE', '$HTTPDOCS/image/');
define('DIR_STORAGE', '$HTTPDOCS/storage/');
define('DIR_LANGUAGE', '$HTTPDOCS/admin/language/');
define('DIR_TEMPLATE', '$HTTPDOCS/admin/view/template/');
define('DIR_CONFIG', '$HTTPDOCS/system/config/');
define('DIR_CACHE', '$HTTPDOCS/system/storage/cache/');
define('DIR_DOWNLOAD', '$HTTPDOCS/system/storage/download/');
define('DIR_LOGS', '$HTTPDOCS/system/storage/logs/');
define('DIR_MODIFICATION', '$HTTPDOCS/system/storage/modification/');
define('DIR_UPLOAD', '$HTTPDOCS/system/storage/upload/');

// DB
define('DB_DRIVER', 'pdo');
define('DB_HOSTNAME', 'localhost');
define('DB_USERNAME', '$DB_USER');
define('DB_PASSWORD', '$DB_PASS');
define('DB_DATABASE', '$DB_NAME');
define('DB_PORT', '3306');
define('DB_PREFIX', 'oc_');
EOF
        ok "admin/config.php created"
    else
        warn "admin/config.php not found — OpenCart may not support auto-config"
    fi
}

# ── Permissions ────────────────────────────────────────────────────────────

fix_permissions() {
    step "Fixing file permissions..."

    chown -R "$PLESK_OWNER:$PLESK_GROUP" "$HTTPDOCS" 2>/dev/null || true

    find "$HTTPDOCS" -type d -exec chmod 755 {} \; 2>/dev/null || true
    find "$HTTPDOCS" -type f -exec chmod 644 {} \; 2>/dev/null || true

    mkdir -p "$HTTPDOCS/system/storage/cache"
    mkdir -p "$HTTPDOCS/system/storage/logs"
    mkdir -p "$HTTPDOCS/system/storage/modification"
    mkdir -p "$HTTPDOCS/system/storage/upload"
    mkdir -p "$HTTPDOCS/image/catalog"
    mkdir -p "$HTTPDOCS/storage"

    chown -R "$PLESK_OWNER:$PLESK_GROUP" "$HTTPDOCS/system/storage" 2>/dev/null || true
    chown -R "$PLESK_OWNER:$PLESK_GROUP" "$HTTPDOCS/image" 2>/dev/null || true
    chown -R "$PLESK_OWNER:$PLESK_GROUP" "$HTTPDOCS/storage" 2>/dev/null || true

    chmod -R 775 "$HTTPDOCS/system/storage/cache" 2>/dev/null || true
    chmod -R 775 "$HTTPDOCS/system/storage/logs" 2>/dev/null || true
    chmod -R 775 "$HTTPDOCS/system/storage/modification" 2>/dev/null || true
    chmod -R 775 "$HTTPDOCS/system/storage/upload" 2>/dev/null || true

    ok "Permissions fixed"
}

# ── Storage Symlink ────────────────────────────────────────────────────────

setup_storage_symlink() {
    step "Setting up storage symlink..."

    local storage_target="$HTTPDOCS/storage"
    local storage_link="$HTTPDOCS/system/storage"

    if [[ -L "$storage_link" ]]; then
        ok "Storage symlink already exists"
    elif [[ -d "$storage_link" ]] && [[ ! -L "$storage_link" ]]; then
        warn "Storage is a real directory — moving to $storage_target"
        mv "$storage_link" "$storage_target" 2>/dev/null || true
        ln -sf "$storage_target" "$storage_link" && ok "Symlink created" || warn "Could not create symlink"
    else
        ln -sf "$storage_target" "$storage_link" && ok "Symlink created" || warn "Could not create symlink"
    fi

    chown -L "$PLESK_OWNER:$PLESK_GROUP" "$storage_target" 2>/dev/null || true
}

# ── Apache Config ─────────────────────────────────────────────────────────

configure_apache() {
    step "Configuring Apache for OpenCart..."

    local vhost_file="/var/www/vhosts/$DOMAIN/conf/vhost.conf"
    local vhost_dir
    vhost_dir=$(dirname "$vhost_file")
    [[ ! -d "$vhost_dir" ]] && mkdir -p "$vhost_dir"

    cat > "$vhost_file" <<EOF
<Directory $HTTPDOCS>
    AllowOverride All
    Options -Indexes +FollowSymLinks
    Require all granted
</Directory>

# Prevent access to sensitive files
<FilesMatch "\.(env|log|sql|sh|htaccess|htpasswd|git|gitignore|md)$">
    Require all denied
</FilesMatch>

# Security headers
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
</IfModule>

# Disable directory listing
Options -Indexes
EOF
    ok "Apache vhost config written"

    if command -v apachectl &>/dev/null; then
        apachectl configtest 2>/dev/null && ok "Apache config valid" || warn "Apache config test failed"
    fi
}

restart_apache() {
    step "Restarting Apache..."
    if systemctl restart apache2 2>/dev/null; then
        ok "Apache restarted"
    elif systemctl restart httpd 2>/dev/null; then
        ok "Apache restarted"
    else
        warn "Could not restart Apache — restart manually"
    fi
}

# ── SSL / Let's Encrypt ──────────────────────────────────────────────────

enable_ssl() {
    step "Checking SSL certificate..."

    if [[ -f "/var/www/vhosts/$DOMAIN/conf/ssl.vhost.conf" ]]; then
        ok "SSL already configured"
        return
    fi

    warn "SSL not yet configured"
    info "To enable free SSL via Let's Encrypt:"
    info "  Plesk → Websites & Domains → $DOMAIN → SSL/TLS"
    info "  → Let's Encrypt → select domains → Install"
    info ""
    info "After installing SSL, re-run this script:"
    info "  bash deploy-opencart.sh $DOMAIN --skip-bundle"
}

# ── Bundle Manager Installation ────────────────────────────────────────────

install_bundle_module() {
    step "Installing Bundle Manager module..."

    if [[ ! -d "$HTTPDOCS/opencart-module" ]]; then
        info "Cloning Bundle Manager repository..."
        git clone -b "$BUNDLE_BRANCH" --depth 1 "$BUNDLE_REPO" "$HTTPDOCS/opencart-module" 2>/dev/null || \
            warn "Could not clone bundle repo — clone manually"
    fi

    if [[ -d "$HTTPDOCS/opencart-module" ]]; then
        if [[ -d "$HTTPDOCS/opencart-module/catalog" ]]; then
            cp -r "$HTTPDOCS/opencart-module/catalog/"* "$HTTPDOCS/catalog/" 2>/dev/null && ok "Catalog files copied" || true
        fi
        if [[ -d "$HTTPDOCS/opencart-module/admin" ]]; then
            cp -r "$HTTPDOCS/opencart-module/admin/"* "$HTTPDOCS/admin/" 2>/dev/null && ok "Admin files copied" || true
        fi
        if [[ -d "$HTTPDOCS/opencart-module/install" ]]; then
            mkdir -p "$HTTPDOCS/install"
            cp -r "$HTTPDOCS/opencart-module/install/"* "$HTTPDOCS/install/" 2>/dev/null && ok "Install scripts copied" || true
        fi
    fi

    run_bundle_migration

    if [[ -n "$STRAPI_URL" ]]; then
        configure_strapi_url
    elif [[ -n "$STRAPI_URL" ]]; then
        warn "No Strapi URL provided — set STRAPI_API_URL manually in config.php"
    fi

    clear_opencart_cache
}

run_bundle_migration() {
    step "Running Bundle Manager database migration..."

    if [[ -f "$HTTPDOCS/install/migrate.php" ]]; then
        php "$HTTPDOCS/install/migrate.php" 2>&1 | tail -5 && ok "Migration complete" || warn "Migration had warnings"
    elif [[ -f "$HTTPDOCS/install/bundle_install.sql" ]]; then
        if command -v mysql &>/dev/null; then
            mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$HTTPDOCS/install/bundle_install.sql" 2>/dev/null && \
                ok "SQL migration applied" || warn "SQL migration failed or already applied"
        else
            warn "MySQL CLI not available — run bundle_install.sql via phpMyAdmin"
        fi
    else
        info "No migration script in bundle module — OpenCart will auto-create tables on first module access"
    fi

    create_opencart_admin "$DB_NAME" "admin" "Geau@3x\$"
}

configure_strapi_url() {
    step "Configuring Strapi API URL..."
    if ! grep -q "STRAPI_API_URL" "$HTTPDOCS/config.php" 2>/dev/null; then
        echo "" >> "$HTTPDOCS/config.php"
        echo "// Bundle Manager — Strapi CMS Integration" >> "$HTTPDOCS/config.php"
        echo "define('STRAPI_API_URL', '$STRAPI_URL');" >> "$HTTPDOCS/config.php"
        ok "STRAPI_API_URL set to $STRAPI_URL"
    else
        ok "STRAPI_API_URL already configured"
    fi
}

clear_opencart_cache() {
    step "Clearing OpenCart cache..."
    rm -rf "$HTTPDOCS/system/storage/cache/"*        2>/dev/null || true
    rm -rf "$HTTPDOCS/system/storage/modification/"* 2>/dev/null || true
    ok "Cache cleared"
}

# ── Final Checks ──────────────────────────────────────────────────────────

final_checks() {
    step "Running final checks..."

    local passed=0
    local failed=0

    [[ -f "$HTTPDOCS/index.php" ]] && passed=$((passed+1)) || failed=$((failed+1))
    [[ -f "$HTTPDOCS/config.php" ]] && passed=$((passed+1)) || failed=$((failed+1))
    [[ -f "$HTTPDOCS/admin/config.php" ]] && passed=$((passed+1)) || failed=$((failed+1))
    [[ -d "$HTTPDOCS/catalog/controller/module" ]] && passed=$((passed+1)) || failed=$((failed+1))
    [[ -d "$HTTPDOCS/system/storage" ]] && passed=$((passed+1)) || failed=$((failed+1))
    [[ -d "$HTTPDOCS/image/catalog" ]] && passed=$((passed+1)) || failed=$((failed+1))
    [[ -f "$HTTPDOCS/.htaccess" ]] || [[ ! -f "$HTTPDOCS/config.php" ]] || true

    if [[ $failed -eq 0 ]]; then
        ok "All $passed checks passed"
    else
        warn "$passed passed, $failed failed"
    fi
}

# ── Main ────────────────────────────────────────────────────────────────

main() {
    print_header
    parse_args "$@"

    log "Domain: $DOMAIN"
    log "Deploy dir: $HTTPDOCS"
    log "OpenCart version: $OPENCART_VERSION"
    echo ""

    preflight_checks

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Step 1 — Database Setup${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    setup_database

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Step 2 — Download OpenCart${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    download_opencart

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Step 3 — Configure OpenCart${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    configure_opencart

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Step 4 — Storage & Permissions${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fix_permissions
    setup_storage_symlink

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Step 5 — Apache Configuration${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    configure_apache
    restart_apache
    enable_ssl

    if $WITH_BUNDLE; then
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}  Step 6 — Bundle Manager Module${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        install_bundle_module
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Step 7 — Final Validation${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    final_checks

    print_footer

    log "Installation URLs:"
    log "  Storefront: https://$DOMAIN"
    log "  Admin:      https://$DOMAIN/admin"
    log ""
    log "Database credentials (save these!):"
    log "  Host:     localhost"
    log "  Database: $DB_NAME"
    log "  User:     $DB_USER"
    log "  Password: $DB_PASS"
    log ""
    log "OpenCart Admin Setup:"
    log "  1. Visit https://$DOMAIN/admin"
    log "  2. Set admin username/password"
    log "  3. Enable SSL in OpenCart Admin → System → Settings → Server"
    log ""

    if $WITH_BUNDLE; then
        log "Bundle Manager:"
        log "  1. Extensions → Extensions → Modules → Bundle Manager → Install"
        log "  2. Edit → Set API URL: $STRAPI_URL"
        log "  3. Status: Enabled"
        log "  4. Design → Layouts → Product → add Bundle Product"
        log "  5. Extensions → Modifications → Refresh"
    fi

    log ""
    log "Log file: $LOG_FILE"
    log "DB info: /tmp/plesk-opencart-strapi/db-${DOMAIN}.info"
}

main "$@"
create_admin_user() {
    local DB_NAME="$1"
    local DB_USER="$2"
    local DB_PASS="$3"
    local ADMIN_USER="${4:-admin}"
    local ADMIN_PASS="${5:-Geau@3x\$}"
    
    log "Creating admin user..."
    
    local salt=$(openssl rand -hex(8) 2>/dev/null || head -c 8 /dev/urandom | od -An -tx1 | tr -d ' ')
    local password_hash=$(echo -n "$salt$ADMIN_PASS" | sha512sum | awk '{print $1}')
    local ip=$(curl -s ifconfig.me 2>/dev/null || echo "127.0.0.1")
    
    mysql -u root "$DB_NAME" <<EOF 2>/dev/null || warn "Could not create admin user"
INSERT INTO \`oc_user\` (\`user_id\`, \`user_group_id\`, \`username\`, \`salt\`, \`password\`, \`firstname\`, \`lastname\`, \`email\`, \`image\`, \`code\`, \`ip\`, \`status\`, \`date_added\`) 
VALUES (1, 1, '$ADMIN_USER', '$salt', '$password_hash', 'Admin', 'User', 'admin@example.com', '', '', '$ip', 1, NOW());
EOF
    ok "Admin user '$ADMIN_USER' created with password '$ADMIN_PASS'"
}

create_opencart_admin() {
    local DB_NAME="$1"
    local ADMIN_USER="${2:-admin}"
    local ADMIN_PASS="${3:-Geau@3x\$}"
    
    log "Creating OpenCart admin user..."
    
    local salt=$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')
    local password=$(php -r "echo hash('sha512', '$salt$ADMIN_PASS');")
    
    mysql -u root "$DB_NAME" <<EOSQL 2>/dev/null || warn "Could not create admin user"
INSERT INTO \`oc_user\` (\`user_group_id\`, \`username\`, \`salt\`, \`password\`, \`firstname\`, \`lastname\`, \`email\`, \`code\`, \`ip\`, \`status\`, \`date_added\`)
VALUES (1, '$ADMIN_USER', '$salt', '$password', 'Admin', 'User', 'admin@example.com', '', '0.0.0.0', 1, NOW())
ON DUPLICATE KEY UPDATE username='$ADMIN_USER', salt='$salt', password='$password';
EOSQL
    
    ok "Admin: $ADMIN_USER / $ADMIN_PASS"
}
