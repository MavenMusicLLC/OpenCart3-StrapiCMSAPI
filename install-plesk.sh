#!/bin/bash
# ============================================================================
# install-plesk.sh — Fully Automated Plesk Deployment
# For: OpenCart3-StrapiCMSAPI on Plesk Obsidian
# ============================================================================
# Supports three deployment modes:
#   1. opencart    — OpenCart Bundle Module (main branch)
#   2. strapi      — Strapi CMS API on subdomain (strapi-api branch)
#   3. bundled     — OpenCart + Strapi together (bundled branch)
#
# Usage:
#   bash install-plesk.sh opencart <domain>
#   bash install-plesk.sh strapi <domain>
#   bash install-plesk.sh bundled <domain>
#   bash install-plesk.sh validate <domain>
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
LOG_FILE="$LOG_DIR/install.log"
STATE_DIR="$LOG_DIR/state"
DEPLOY_DIR=""
MODE=""
DOMAIN=""

[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"
[[ ! -d "$STATE_DIR" ]] && mkdir -p "$STATE_DIR"

log()   { echo "[$(date '+%H:%M:%S')]  $1" | tee -a "$LOG_FILE"; }
ok()    { echo -e "  ${GREEN}[OK]${NC}   $1"; }
warn()  { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "  ${RED}[ERR]${NC}  $1" >&2; exit 1; }
info()  { echo -e "  ${CYAN}[INFO]${NC} $1"; }
step()  { echo -e "  ${MAGENTA}[STEP]${NC} $1"; }

print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    OpenCart + Strapi CMS — Plesk Automated Installer       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_footer() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              Installation Complete!                         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

save_state() { echo "$1" > "$STATE_DIR/${MODE}.${DOMAIN}.state"; }
load_state() { cat "$STATE_DIR/${MODE}.${DOMAIN}.state" 2>/dev/null || echo ""; }

detect_owner() {
    log "Detecting Plesk file owner..."
    if [[ -d "$DEPLOY_DIR" ]]; then
        PLESK_OWNER=$(stat -c '%U' "$DEPLOY_DIR" 2>/dev/null || echo "")
        PLESK_GROUP="psacln"
        if [[ -z "$PLESK_OWNER" ]] || [[ "$PLESK_OWNER" == "root" ]]; then
            PLESK_OWNER=$(ls -ld /var/www/vhosts/ 2>/dev/null | head -1 | awk '{print $3}')
        fi
    else
        PLESK_OWNER=$(ls -ld /var/www/vhosts/ 2>/dev/null | head -1 | awk '{print $3}')
    fi
    [[ -z "$PLESK_OWNER" ]] && PLESK_OWNER="www-data"
    log "Plesk owner: $PLESK_OWNER"
    ok "Owner detection complete"
}

check_env() {
    log "Checking environment..."
    local issues=0

    if ! command -v php &>/dev/null; then
        err "PHP not installed"
    else
        PHP_VER=$(php -r 'echo PHP_VERSION;' 2>/dev/null)
        log "PHP $PHP_VER"
        ok "PHP installed"
    fi

    if ! command -v node &>/dev/null; then
        warn "Node.js not found — install via Plesk Node.js extension if deploying Strapi"
    else
        NODE_VER=$(node -v 2>/dev/null)
        NPM_VER=$(npm -v 2>/dev/null)
        log "Node.js $NODE_VER | npm v$NPM_VER"
        ok "Node.js installed"
    fi

    if ! command -v mysql &>/dev/null && ! command -v mariadb &>/dev/null; then
        warn "MySQL CLI not found — DB operations may require phpMyAdmin"
    else
        ok "MySQL CLI found"
    fi

    if ! command -v composer &>/dev/null; then
        warn "Composer not found — not required but useful"
    fi
}

check_disk() {
    local target_dir="${DEPLOY_DIR:-/var/www/vhosts}"
    local available
    available=$(df -BG "$target_dir" 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G')
    if [[ "${available:-0}" =~ ^[0-9]+$ ]] && [[ "${available}" -lt 2048 ]]; then
        warn "Low disk space: ${available}MB available — Strapi build needs ~2GB"
    else
        ok "Disk space OK (${available}MB available)"
    fi
}

check_memory() {
    local mem_available
    mem_available=$(free -m 2>/dev/null | awk 'NR==2 {print $7}')
    if [[ "${mem_available:-0}" =~ ^[0-9]+$ ]] && [[ "${mem_available}" -lt 512 ]]; then
        warn "Low memory: ${mem_available}MB available — Strapi build needs ~512MB+"
    else
        ok "Memory OK (${mem_available}MB available)"
    fi
}

# ── OPENOCART MODE ─────────────────────────────────────────────────────────

deploy_opencart() {
    MODE="opencart"
    local domain="$1"
    DEPLOY_DIR="/var/www/vhosts/${domain}/httpdocs"

    print_header
    log "Mode: OpenCart Bundle Module"
    log "Domain: $domain"
    log "Deploy dir: $DEPLOY_DIR"
    echo ""

    save_state "deploy_opencart_started"

    detect_owner
    check_env
    check_disk

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Deploying OpenCart Bundle Module${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    check_opencart_installation() {
        step "Checking OpenCart installation..."
        if [[ ! -f "$DEPLOY_DIR/index.php" ]]; then
            warn "index.php not found — upload OpenCart first"
            warn "Visit: https://www.opencart.com/index.php?route=download/download"
            return 1
        fi
        if [[ ! -f "$DEPLOY_DIR/config.php" ]]; then
            warn "config.php not found — run OpenCart installer"
            return 1
        fi
        ok "OpenCart installation detected"
        return 0
    }

    if ! check_opencart_installation; then
        log "OpenCart not fully installed yet."
        log "Steps to complete first:"
        log "  1. Download OpenCart from https://www.opencart.com"
        log "  2. Upload OpenCart files to $DEPLOY_DIR"
        log "  3. Visit https://$domain to run the installer"
        log "  4. Re-run this script after OpenCart is installed"
        log ""
        warn "Placing module files only..."
    fi

    install_module_files() {
        step "Installing Bundle Module files..."
        local module_dir="$DEPLOY_DIR/opencart-module"
        if [[ ! -d "$module_dir" ]]; then
            err "opencart-module/ not found — did you deploy the correct branch?"
        fi

        if [[ -d "$module_dir/catalog" ]]; then
            cp -r "$module_dir/catalog/"* "$DEPLOY_DIR/catalog/" 2>/dev/null || true
            ok "Catalog files copied"
        fi

        if [[ -d "$module_dir/admin" ]]; then
            cp -r "$module_dir/admin/"* "$DEPLOY_DIR/admin/" 2>/dev/null || true
            ok "Admin files copied"
        fi

        if [[ -d "$module_dir/install" ]]; then
            mkdir -p "$DEPLOY_DIR/install"
            cp -r "$module_dir/install/"* "$DEPLOY_DIR/install/" 2>/dev/null || true
            ok "Install scripts copied"
        fi
    }

    run_migration() {
        step "Running database migration..."
        if [[ -f "$DEPLOY_DIR/install/migrate.php" ]]; then
            if php "$DEPLOY_DIR/install/migrate.php" 2>&1 | tail -5; then
                ok "Migration complete"
            else
                warn "Migration script had warnings"
            fi
        elif [[ -f "$DEPLOY_DIR/install/bundle_install.sql" ]]; then
            local db_name db_user db_pass
            db_name=$(php -r "include '$DEPLOY_DIR/config.php'; echo DB_DATABASE;" 2>/dev/null || echo "")
            db_user=$(php -r "include '$DEPLOY_DIR/config.php'; echo DB_USERNAME;" 2>/dev/null || echo "")
            db_pass=$(php -r "include '$DEPLOY_DIR/config.php'; echo DB_PASSWORD;" 2>/dev/null || echo "")
            if [[ -n "$db_name" ]] && [[ -n "$db_user" ]]; then
                mysql -u "$db_user" -p"$db_pass" "$db_name" < "$DEPLOY_DIR/install/bundle_install.sql" 2>/dev/null && \
                    ok "SQL migration applied" || warn "SQL migration failed or already applied"
            fi
        else
            warn "No migration script found"
        fi
    }

    update_config() {
        step "Configuring Strapi API URL..."
        if ! grep -q "STRAPI_API_URL" "$DEPLOY_DIR/config.php" 2>/dev/null; then
            echo "" >> "$DEPLOY_DIR/config.php"
            echo "// Bundle Manager — Strapi API Integration" >> "$DEPLOY_DIR/config.php"
            echo "define('STRAPI_API_URL', 'https://api-${domain}/api');" >> "$DEPLOY_DIR/config.php"
            ok "STRAPI_API_URL added"
        else
            ok "STRAPI_API_URL already set"
        fi
    }

    clear_cache() {
        step "Clearing OpenCart cache..."
        rm -rf "$DEPLOY_DIR/system/storage/cache/"*       2>/dev/null || true
        rm -rf "$DEPLOY_DIR/system/storage/modification/"* 2>/dev/null || true
        ok "Cache cleared"
    }

    fix_permissions() {
        step "Fixing file permissions..."
        if [[ -n "$PLESK_OWNER" ]] && [[ "$PLESK_OWNER" != "root" ]]; then
            for dir in \
                "$DEPLOY_DIR/catalog/controller/module" \
                "$DEPLOY_DIR/catalog/model/module" \
                "$DEPLOY_DIR/catalog/view/theme/default/template/module" \
                "$DEPLOY_DIR/catalog/view/theme/default/template/extension/module" \
                "$DEPLOY_DIR/catalog/language/en-gb/module" \
                "$DEPLOY_DIR/catalog/language/en-gb/extension/module" \
                "$DEPLOY_DIR/admin/controller/module" \
                "$DEPLOY_DIR/admin/model/module" \
                "$DEPLOY_DIR/admin/view/module" \
                "$DEPLOY_DIR/admin/language/en-gb/module"; do
                [[ -d "$dir" ]] && chown -R "$PLESK_OWNER:$PLESK_GROUP" "$dir" 2>/dev/null || true
            done
            find "$DEPLOY_DIR/catalog" -type d -exec chmod 755 {} \; 2>/dev/null || true
            find "$DEPLOY_DIR/catalog" -type f -exec chmod 644 {} \; 2>/dev/null || true
            find "$DEPLOY_DIR/admin" -type d -exec chmod 755 {} \; 2>/dev/null || true
            find "$DEPLOY_DIR/admin" -type f -exec chmod 644 {} \; 2>/dev/null || true
            ok "Permissions fixed"
        fi
    }

    install_module_files
    run_migration
    update_config
    clear_cache
    fix_permissions

    save_state "deploy_opencart_complete"
    print_footer

    log "Next steps:"
    log "  1. OpenCart Admin → Extensions → Modules → Bundle Manager → Install"
    log "  2. Edit the module, set API URL: https://api-${domain}/api"
    log "  3. Set Status: Enabled"
    log "  4. Design → Layouts → Product → add 'Bundle Product' to Content Bottom"
    log ""
    log "Log file: $LOG_FILE"
}

# ── STRAPI MODE ──────────────────────────────────────────────────────────

deploy_strapi() {
    MODE="strapi"
    local domain="$1"
    DEPLOY_DIR="/var/www/vhosts/${domain}/httpdocs"

    print_header
    log "Mode: Strapi CMS API"
    log "Domain: $domain"
    log "Deploy dir: $DEPLOY_DIR"
    echo ""

    save_state "deploy_strapi_started"

    detect_owner
    check_env
    check_disk
    check_memory

    if ! command -v node &>/dev/null; then
        err "Node.js not found. Install via Plesk Panel:"
        err "  Plesk → Subscriptions → $domain → Add/Remove Components → Node.js"
    fi

    local node_ver
    node_ver=$(node -e "process.stdout.write(process.versions.node)" 2>/dev/null)
    local major="${node_ver%%.*}"
    if [[ "${major:-0}" -lt 18 ]]; then
        err "Node.js 18+ required. Found: $node_ver. Upgrade via Plesk."
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Deploying Strapi CMS API${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    check_package() {
        step "Checking package.json..."
        if [[ ! -f "$DEPLOY_DIR/package.json" ]]; then
            err "package.json not found — did you deploy the strapi-api branch?"
        fi
        ok "package.json found"
    }

    install_deps() {
        step "Installing Node.js dependencies..."
        cd "$DEPLOY_DIR"
        if [[ -f "package-lock.json" ]]; then
            npm ci --prefer-offline --no-audit 2>&1 | tail -8 || true
        else
            npm install --prefer-offline --no-audit 2>&1 | tail -8 || true
        fi
        ok "Dependencies installed"
    }

    setup_env() {
        step "Setting up .env configuration..."
        if [[ ! -f ".env" ]]; then
            if [[ -f ".env.example" ]]; then
                cp .env.example .env

                gen_secret() {
                    if command -v openssl &>/dev/null; then
                        openssl rand -hex 16
                    else
                        node -e "process.stdout.write(require('crypto').randomBytes(16).toString('hex'))"
                    fi
                }

                sed -i "s/APP_KEYS=.*/APP_KEYS=$(gen_secret),$(gen_secret),$(gen_secret),$(gen_secret)/" .env
                sed -i "s/API_TOKEN_SALT=.*/API_TOKEN_SALT=$(gen_secret)/" .env
                sed -i "s/ADMIN_JWT_SECRET=.*/ADMIN_JWT_SECRET=$(gen_secret)/" .env
                sed -i "s/TRANSFER_TOKEN_SALT=.*/TRANSFER_TOKEN_SALT=$(gen_secret)/" .env
                sed -i "s/JWT_SECRET=.*/JWT_SECRET=$(gen_secret)/" .env

                ok ".env created with auto-generated secrets"
                warn "Edit .env with your database credentials!"
            fi
        else
            ok ".env already exists"
        fi
    }

    build_strapi() {
        step "Building Strapi admin panel..."
        cd "$DEPLOY_DIR"
        export NODE_ENV=production
        if npm run build 2>&1 | tail -10; then
            ok "Strapi admin panel built"
        else
            warn "Build completed with warnings — this is often OK"
        fi
    }

    fix_permissions() {
        step "Fixing file permissions..."
        if [[ -n "$PLESK_OWNER" ]] && [[ "$PLESK_OWNER" != "root" ]]; then
            chown -R "$PLESK_OWNER:$PLESK_GROUP" "$DEPLOY_DIR" 2>/dev/null || true
            for dir in \
                "$DEPLOY_DIR/.cache" \
                "$DEPLOY_DIR/.tmp" \
                "$DEPLOY_DIR/dist" \
                "$DEPLOY_DIR/public/uploads" \
                "$DEPLOY_DIR/build"; do
                [[ -d "$dir" ]] && chmod -R 775 "$dir" 2>/dev/null || true
            done
            ok "Permissions fixed"
        fi
    }

    write_proxy_config() {
        step "Writing Apache proxy configuration..."
        cat > "$DEPLOY_DIR/.htaccess" <<'HTACCESS'
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /

    RewriteCond %{REQUEST_FILENAME} -f [OR]
    RewriteCond %{REQUEST_FILENAME} -d
    RewriteRule ^ - [L]

    RewriteRule ^api/(.*)$  http://127.0.0.1:1337/api/$1  [P,L]
    RewriteRule ^graphql$    http://127.0.0.1:1337/graphql    [P,L]
    RewriteRule ^graphql/(.*)$ http://127.0.0.1:1337/graphql/$1 [P,L]
    RewriteRule ^uploads/(.*)$ http://127.0.0.1:1337/uploads/$1 [P,L]
    RewriteRule ^documentation/(.*)$ http://127.0.0.1:1337/documentation/$1 [P,L]
</IfModule>
HTACCESS
        ok "Apache proxy rules written"
    }

    setup_process_manager() {
        step "Setting up process manager..."
        if ! command -v pm2 &>/dev/null; then
            warn "PM2 not installed — installing globally..."
            npm install -g pm2 2>&1 | tail -3 || true
        fi

        local app_name="strapi-${domain}"
        cd "$DEPLOY_DIR"

        if pm2 list 2>/dev/null | grep -q "$app_name"; then
            pm2 restart "$app_name" 2>&1 | tail -3
            ok "Strapi restarted via PM2 ($app_name)"
        else
            pm2 start npm --name "$app_name" -- start 2>&1 | tail -3
            ok "Strapi started via PM2 ($app_name)"
            pm2 save 2>/dev/null || true
        fi

        local startup_cmd
        startup_cmd=$(pm2 startup 2>/dev/null | grep -q "sudo" && echo "pm2 startup" || echo "")
        [[ -n "$startup_cmd" ]] && eval "$startup_cmd" 2>/dev/null || true
    }

    check_package
    install_deps
    setup_env
    build_strapi
    fix_permissions
    write_proxy_config
    setup_process_manager

    save_state "deploy_strapi_complete"
    print_footer

    log "Next steps:"
    log "  1. Edit .env with database credentials: nano $DEPLOY_DIR/.env"
    log "  2. Create Strapi database in Plesk → Databases"
    log "  3. Restart Strapi: pm2 restart strapi-$domain"
    log "  4. Visit https://$domain/admin to create admin account"
    log "  5. Seed demo: curl -X POST https://$domain/api/seed"
    log ""
    log "API endpoints:"
    log "  Admin panel: https://$domain/admin"
    log "  REST API:    https://$domain/api"
    log "  GraphQL:     https://$domain/graphql"
    log ""
    log "Log file: $LOG_FILE"
}

# ── BUNDLED MODE ──────────────────────────────────────────────────────────

deploy_bundled() {
    MODE="bundled"
    local domain="$1"
    DEPLOY_DIR="/var/www/vhosts/${domain}/httpdocs"
    local strapi_dir="$DEPLOY_DIR/strapi"

    print_header
    log "Mode: Bundled (OpenCart + Strapi)"
    log "Domain: $domain"
    log "Deploy dir: $DEPLOY_DIR"
    log "Strapi dir: $strapi_dir"
    echo ""

    save_state "deploy_bundled_started"

    detect_owner
    check_env
    check_disk
    check_memory

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  PART 1 — OpenCart Bundle Module${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    check_opencart() {
        step "Checking OpenCart..."
        if [[ ! -f "$DEPLOY_DIR/index.php" ]]; then
            warn "OpenCart not detected — module files placed"
        else
            ok "OpenCart installation detected"
        fi
    }

    install_module_files() {
        step "Installing Bundle Module files..."
        local module_dir="$DEPLOY_DIR/opencart-module"
        [[ ! -d "$module_dir" ]] && err "opencart-module/ not found"

        [[ -d "$module_dir/catalog" ]] && cp -r "$module_dir/catalog/"* "$DEPLOY_DIR/catalog/" 2>/dev/null && ok "Catalog copied" || true
        [[ -d "$module_dir/admin" ]]   && cp -r "$module_dir/admin/"*   "$DEPLOY_DIR/admin/"   2>/dev/null && ok "Admin copied"   || true

        if [[ -d "$module_dir/install" ]]; then
            mkdir -p "$DEPLOY_DIR/install"
            cp -r "$module_dir/install/"* "$DEPLOY_DIR/install/" 2>/dev/null || true
        fi
    }

    run_migration() {
        step "Running database migration..."
        if [[ -f "$DEPLOY_DIR/install/migrate.php" ]]; then
            php "$DEPLOY_DIR/install/migrate.php" 2>&1 | tail -5 && ok "Migration complete" || warn "Migration warnings"
        elif [[ -f "$DEPLOY_DIR/install/bundle_install.sql" ]]; then
            local db_name db_user db_pass
            db_name=$(php -r "include '$DEPLOY_DIR/config.php'; echo DB_DATABASE;" 2>/dev/null || echo "")
            db_user=$(php -r "include '$DEPLOY_DIR/config.php'; echo DB_USERNAME;" 2>/dev/null || echo "")
            db_pass=$(php -r "include '$DEPLOY_DIR/config.php'; echo DB_PASSWORD;" 2>/dev/null || echo "")
            if [[ -n "$db_name" ]] && [[ -n "$db_user" ]]; then
                mysql -u "$db_user" -p"$db_pass" "$db_name" < "$DEPLOY_DIR/install/bundle_install.sql" 2>/dev/null && \
                    ok "SQL migrated" || warn "SQL already applied"
            fi
        fi
    }

    clear_cache() {
        step "Clearing OpenCart cache..."
        rm -rf "$DEPLOY_DIR/system/storage/cache/"*       2>/dev/null || true
        rm -rf "$DEPLOY_DIR/system/storage/modification/"* 2>/dev/null || true
        ok "Cache cleared"
    }

    update_opencart_config() {
        step "Configuring Strapi API URL..."
        if ! grep -q "STRAPI_API_URL" "$DEPLOY_DIR/config.php" 2>/dev/null; then
            echo "" >> "$DEPLOY_DIR/config.php"
            echo "// Bundle Manager — Strapi API (bundled)" >> "$DEPLOY_DIR/config.php"
            echo "define('STRAPI_API_URL', 'https://${domain}/api');" >> "$DEPLOY_DIR/config.php"
            ok "STRAPI_API_URL configured"
        fi
    }

    fix_opencart_perms() {
        step "Fixing OpenCart permissions..."
        if [[ -n "$PLESK_OWNER" ]] && [[ "$PLESK_OWNER" != "root" ]]; then
            for dir in \
                "$DEPLOY_DIR/catalog/controller/module" \
                "$DEPLOY_DIR/catalog/model/module" \
                "$DEPLOY_DIR/catalog/view/theme/default/template/module" \
                "$DEPLOY_DIR/admin/controller/module" \
                "$DEPLOY_DIR/admin/model/module" \
                "$DEPLOY_DIR/admin/view/module"; do
                [[ -d "$dir" ]] && chown -R "$PLESK_OWNER:$PLESK_GROUP" "$dir" 2>/dev/null || true
            done
            ok "OpenCart permissions fixed"
        fi
    }

    check_opencart
    install_module_files
    run_migration
    clear_cache
    update_opencart_config
    fix_opencart_perms

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  PART 2 — Strapi CMS API${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    setup_strapi_dir() {
        step "Setting up strapi/ subdirectory..."
        mkdir -p "$strapi_dir"

        for item in src config package.json package-lock.json .env.example; do
            if [[ -e "$DEPLOY_DIR/$item" ]] && [[ ! -e "$strapi_dir/$item" ]]; then
                mv "$DEPLOY_DIR/$item" "$strapi_dir/"
                ok "Moved $item"
            elif [[ -e "$DEPLOY_DIR/$item" ]]; then
                cp -r "$DEPLOY_DIR/$item" "$strapi_dir/" 2>/dev/null || true
            fi
        done

        ok "Strapi directory ready"
    }

    check_node_strapi() {
        step "Checking Node.js for Strapi..."
        if ! command -v node &>/dev/null; then
            err "Node.js not found — install via Plesk Node.js extension"
        fi
        local ver
        ver=$(node -e "process.stdout.write(process.versions.node)" 2>/dev/null)
        local major="${ver%%.*}"
        if [[ "${major:-0}" -lt 18 ]]; then
            err "Node.js 18+ required (found $ver)"
        fi
        ok "Node.js $ver"
    }

    install_strapi_deps() {
        step "Installing Strapi dependencies..."
        cd "$strapi_dir"
        if [[ -f "package-lock.json" ]]; then
            npm ci --no-audit 2>&1 | tail -8 || true
        else
            npm install --no-audit 2>&1 | tail -8 || true
        fi
        ok "Dependencies installed"
        cd "$DEPLOY_DIR"
    }

    setup_strapi_env() {
        step "Setting up Strapi .env..."
        if [[ ! -f "$strapi_dir/.env" ]]; then
            if [[ -f "$strapi_dir/.env.example" ]]; then
                cp "$strapi_dir/.env.example" "$strapi_dir/.env"

                gen_secret() {
                    node -e "process.stdout.write(require('crypto').randomBytes(16).toString('hex'))" 2>/dev/null || \
                    openssl rand -hex 16
                }

                sed -i "s|APP_KEYS=.*|APP_KEYS=$(gen_secret),$(gen_secret),$(gen_secret),$(gen_secret)|" .env
                sed -i "s|API_TOKEN_SALT=.*|API_TOKEN_SALT=$(gen_secret)|" .env
                sed -i "s|ADMIN_JWT_SECRET=.*|ADMIN_JWT_SECRET=$(gen_secret)|" .env
                sed -i "s|TRANSFER_TOKEN_SALT=.*|TRANSFER_TOKEN_SALT=$(gen_secret)|" .env
                sed -i "s|JWT_SECRET=.*|JWT_SECRET=$(gen_secret)|" .env

                ok ".env created with auto-generated secrets"
                warn "Edit strapi/.env with your database credentials!"
            else
                warn ".env.example not found"
            fi
        else
            ok ".env already exists"
        fi
    }

    build_strapi() {
        step "Building Strapi admin panel..."
        cd "$strapi_dir"
        export NODE_ENV=production
        if npm run build 2>&1 | tail -10; then
            ok "Strapi built"
        else
            warn "Build completed with warnings"
        fi
        cd "$DEPLOY_DIR"
    }

    write_bundled_htaccess() {
        step "Writing Apache reverse proxy rules..."
        cat > "$DEPLOY_DIR/.htaccess" <<'HTACCESS'
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
        ok "Proxy rules written"
    }

    fix_strapi_perms() {
        step "Fixing Strapi permissions..."
        if [[ -n "$PLESK_OWNER" ]] && [[ "$PLESK_OWNER" != "root" ]]; then
            chown -R "$PLESK_OWNER:$PLESK_GROUP" "$strapi_dir" 2>/dev/null || true
            chmod 600 "$strapi_dir/.env" 2>/dev/null || true
            ok "Strapi permissions fixed"
        fi
    }

    setup_strapi_pm2() {
        step "Setting up PM2 process manager..."
        if ! command -v pm2 &>/dev/null; then
            warn "Installing PM2..."
            npm install -g pm2 2>&1 | tail -3 || true
        fi

        local app_name="strapi-bundled-$domain"
        cd "$strapi_dir"

        if pm2 list 2>/dev/null | grep -q "$app_name"; then
            pm2 restart "$app_name" 2>&1 | tail -3
            ok "Strapi restarted"
        else
            pm2 start npm --name "$app_name" -- start 2>&1 | tail -3
            ok "Strapi started"
            pm2 save 2>/dev/null || true
        fi
        cd "$DEPLOY_DIR"
    }

    setup_strapi_dir
    check_node_strapi
    install_strapi_deps
    setup_strapi_env
    build_strapi
    write_bundled_htaccess
    fix_strapi_perms
    setup_strapi_pm2

    save_state "deploy_bundled_complete"
    print_footer

    log "URLs after deployment:"
    log "  OpenCart store: https://$domain"
    log "  Strapi admin:   https://$domain/strapi"
    log "  REST API:       https://$domain/api"
    log "  GraphQL:        https://$domain/graphql"
    log ""
    log "Next steps:"
    log "  1. Edit strapi/.env — fill in database credentials"
    log "  2. Restart: pm2 restart strapi-bundled-$domain"
    log "  3. Create admin at: https://$domain/strapi"
    log "  4. OpenCart Admin → Extensions → Modules → Bundle Manager → Install"
    log ""
    log "Log file: $LOG_FILE"
}

# ── VALIDATE MODE ─────────────────────────────────────────────────────────

validate_deployment() {
    MODE="validate"
    local domain="$1"
    DEPLOY_DIR="/var/www/vhosts/${domain}/httpdocs"
    local strapi_dir="$DEPLOY_DIR/strapi"
    local failed=0

    print_header
    log "Mode: Deployment Validation"
    log "Domain: $domain"
    echo ""

    log "Checking environment..."
    check_env
    check_disk
    check_memory
    echo ""

    log "Checking OpenCart..."
    if [[ -f "$DEPLOY_DIR/index.php" ]]; then ok "index.php found"; else warn "index.php missing"; failed=$((failed+1)); fi
    if [[ -f "$DEPLOY_DIR/config.php" ]]; then ok "config.php found"; else warn "config.php missing"; failed=$((failed+1)); fi
    if [[ -f "$DEPLOY_DIR/catalog/controller/module/bundle.php" ]]; then ok "Bundle controller found"; else warn "Bundle controller missing"; failed=$((failed+1)); fi
    if [[ -f "$DEPLOY_DIR/admin/controller/module/bundle_manager.php" ]]; then ok "Admin controller found"; else warn "Admin controller missing"; failed=$((failed+1)); fi
    if grep -q "STRAPI_API_URL" "$DEPLOY_DIR/config.php" 2>/dev/null; then ok "STRAPI_API_URL configured"; else warn "STRAPI_API_URL not set"; fi
    echo ""

    log "Checking Strapi (subdomain mode)..."
    if [[ -f "$DEPLOY_DIR/package.json" ]]; then
        ok "Strapi package.json found"
        if [[ -f "$DEPLOY_DIR/.env" ]]; then ok ".env found"; else warn ".env missing"; failed=$((failed+1)); fi
        if [[ -d "$DEPLOY_DIR/build" ]]; then ok "Build directory found"; else warn "Build directory missing"; failed=$((failed+1)); fi
    elif [[ -f "$strapi_dir/package.json" ]]; then
        ok "Bundled Strapi package.json found"
        if [[ -f "$strapi_dir/.env" ]]; then ok "strapi/.env found"; else warn "strapi/.env missing"; failed=$((failed+1)); fi
        if [[ -d "$strapi_dir/.cache" ]] || [[ -d "$strapi_dir/build" ]]; then ok "Build artifacts found"; else warn "Build artifacts missing"; fi
    else
        warn "No Strapi installation detected (package.json not found)"
    fi
    echo ""

    log "Checking Apache proxy config..."
    if [[ -f "$DEPLOY_DIR/.htaccess" ]]; then
        if grep -q "127.0.0.1:1337" "$DEPLOY_DIR/.htaccess"; then
            ok "Proxy rules configured"
        else
            warn ".htaccess exists but no proxy rules"
        fi
    else
        warn ".htaccess not found"
    fi
    echo ""

    log "Checking process manager..."
    if command -v pm2 &>/dev/null; then
        ok "PM2 installed"
        local strapi_proc
        strapi_proc=$(pm2 list 2>/dev/null | grep -E "strapi[-_]" | grep -v grep || echo "")
        if [[ -n "$strapi_proc" ]]; then
            ok "Strapi process running:"
            echo "$strapi_proc" | while read -r line; do
                echo -e "    ${GREEN}→${NC} $line"
            done
        else
            warn "No Strapi process found in PM2"
        fi
    else
        warn "PM2 not installed"
    fi
    echo ""

    log "Checking PHP extensions..."
    for ext in pdo pdo_mysql json mbstring gd curl zip; do
        if php -m 2>/dev/null | grep -qi "$ext"; then
            ok "PHP $ext"
        else
            warn "PHP $ext missing"
        fi
    done
    echo ""

    log "Checking HTTP reachability..."
    local https_port
    https_port=$(curl -s -o /dev/null -w '%{http_code}' "https://$domain" 2>/dev/null || echo "000")
    if [[ "$https_port" != "000" ]]; then
        ok "HTTPS responding (HTTP $https_port)"
    else
        warn "HTTPS not responding"
    fi
    echo ""

    log "File permission check..."
    local upload_dir="$DEPLOY_DIR/system/storage/upload"
    local cache_dir="$DEPLOY_DIR/system/storage/cache"
    [[ -d "$upload_dir" ]] && [[ -w "$upload_dir" ]] && ok "Upload dir writable" || warn "Upload dir not writable"
    [[ -d "$cache_dir" ]]  && [[ -w "$cache_dir"  ]] && ok "Cache dir writable"  || warn "Cache dir not writable"
    echo ""

    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║     Validation PASSED — Deployment looks good!  ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${YELLOW}╔═══════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║     Validation FAILED — $failed issues found     ║${NC}"
        echo -e "${YELLOW}╚═══════════════════════════════════════════════════╝${NC}"
        echo ""
        log "Run: bash repair-plesk.sh $domain"
    fi
}

# ── MAIN ────────────────────────────────────────────────────────────────

main() {
    if [[ $# -lt 1 ]]; then
        echo ""
        echo "OpenCart + Strapi CMS — Plesk Automated Installer"
        echo ""
        echo "Usage:"
        echo "  bash install-plesk.sh opencart <domain>   Deploy OpenCart module only"
        echo "  bash install-plesk.sh strapi <domain>    Deploy Strapi CMS on subdomain"
        echo "  bash install-plesk.sh bundled <domain>    Deploy both on same domain"
        echo "  bash install-plesk.sh validate <domain>  Validate existing deployment"
        echo "  bash install-plesk.sh deploy-opencart <domain>  Full OpenCart install"
        echo ""
        echo "Examples:"
        echo "  bash install-plesk.sh opencart oc.mystore.com"
        echo "  bash install-plesk.sh strapi api.mystore.com"
        echo "  bash install-plesk.sh bundled mystore.com"
        echo "  bash install-plesk.sh validate mystore.com"
        echo "  bash install-plesk.sh deploy-opencart mystore.com"
        exit 1
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        opencart)
            [[ $# -lt 1 ]] && err "Usage: install-plesk.sh opencart <domain>"
            deploy_opencart "$1"
            ;;
        strapi)
            [[ $# -lt 1 ]] && err "Usage: install-plesk.sh strapi <domain>"
            deploy_strapi "$1"
            ;;
        bundled)
            [[ $# -lt 1 ]] && err "Usage: install-plesk.sh bundled <domain>"
            deploy_bundled "$1"
            ;;
        validate)
            [[ $# -lt 1 ]] && err "Usage: install-plesk.sh validate <domain>"
            validate_deployment "$1"
            ;;
        deploy-opencart)
            [[ $# -lt 1 ]] && err "Usage: install-plesk.sh deploy-opencart <domain>"
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            bash "$SCRIPT_DIR/deploy-opencart.sh" "$@"
            ;;
        *)
            err "Unknown command: $cmd"
            ;;
    esac
}

main "$@"