#!/bin/bash
# ============================================================================
# healthcheck.sh — Runtime Health Check for Plesk Deployment
# For: OpenCart3-StrapiCMSAPI on Plesk Obsidian
# ============================================================================
# Verifies all services are running correctly:
#   - Node/Strapi process
#   - Strapi API endpoints
#   - OpenCart storefront
#   - Database connectivity
#   - File permissions
#   - SSL validity
#   - PM2 status
#   - Upload directories
# ============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN="${1:-}"
HEALTH_FILE="/tmp/plesk-opencart-strapi/health-${DOMAIN:-unknown}.json"
FAILED=0

log()   { echo -e "  $1"; }
ok()    { echo -e "  ${GREEN}[PASS]${NC} $1"; }
warn()  { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
fail()  { echo -e "  ${RED}[FAIL]${NC} $1"; FAILED=$((FAILED+1)); }

print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    OpenCart + Strapi — Health Check                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_process() {
    echo "── Process Status ───────────────────────────────────────────"
    if command -v pm2 &>/dev/null; then
        local strapi_proc
        strapi_proc=$(pm2 list 2>/dev/null | grep -E "strapi[-_]" | grep -v grep || echo "")
        if [[ -n "$strapi_proc" ]]; then
            ok "Strapi process running"
            pm2 list 2>/dev/null | grep -E "strapi[-_]" | grep -v grep | while read -r line; do
                echo -e "    $line"
            done
        else
            warn "No Strapi PM2 process found"
        fi
    else
        warn "PM2 not installed"
    fi

    local node_pid
    node_pid=$(pgrep -f "strapi" | head -1 || echo "")
    if [[ -n "$node_pid" ]]; then
        ok "Strapi Node process active (PID: $node_pid)"
    else
        warn "No Strapi Node process found"
    fi
}

check_port() {
    echo ""
    echo "── Port 1337 (Strapi internal) ────────────────────────────────"
    if command -v ss &>/dev/null; then
        if ss -tlnp 2>/dev/null | grep -q ":1337 "; then
            ok "Strapi listening on port 1337"
        else
            warn "Nothing listening on port 1337 — Strapi may not be running"
        fi
    elif command -v netstat &>/dev/null; then
        if netstat -tlnp 2>/dev/null | grep -q ":1337 "; then
            ok "Strapi listening on port 1337"
        else
            warn "Nothing listening on port 1337"
        fi
    fi
}

check_http_endpoints() {
    echo ""
    echo "── HTTP Endpoint Checks ──────────────────────────────────────"

    local code

    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://${DOMAIN}/api/status" 2>/dev/null || echo "000")
    if [[ "$code" == "200" ]]; then
        ok "GET /api/status → HTTP $code"
    else
        fail "GET /api/status → HTTP $code (expected 200)"
    fi

    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://${DOMAIN}/api/bundles" 2>/dev/null || echo "000")
    if [[ "$code" == "200" ]]; then
        ok "GET /api/bundles → HTTP $code"
    else
        warn "GET /api/bundles → HTTP $code (may need auth or empty data)"
    fi

    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://${DOMAIN}/graphql" 2>/dev/null || echo "000")
    if [[ "$code" == "200" ]] || [[ "$code" == "400" ]]; then
        ok "GET /graphql → HTTP $code"
    else
        warn "GET /graphql → HTTP $code"
    fi

    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "https://${DOMAIN}/strapi/admin" 2>/dev/null || echo "000")
    if [[ "$code" == "200" ]]; then
        ok "GET /strapi/admin → HTTP $code"
    elif [[ "$code" == "302" ]] || [[ "$code" == "301" ]]; then
        ok "GET /strapi/admin → HTTP $code (redirect to login)"
    else
        fail "GET /strapi/admin → HTTP $code (expected 200 or redirect)"
    fi

    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://${DOMAIN}" 2>/dev/null || echo "000")
    if [[ "$code" == "200" ]]; then
        ok "GET / (OpenCart) → HTTP $code"
    else
        fail "GET / (OpenCart) → HTTP $code (expected 200)"
    fi
}

check_database() {
    echo ""
    echo "── Database Connectivity ──────────────────────────────────────"

    local deploy_dir="/var/www/vhosts/${DOMAIN}/httpdocs"
    local strapi_dir="$deploy_dir/strapi"
    local target_dir="$deploy_dir"
    [[ -d "$strapi_dir" ]] && target_dir="$strapi_dir"

    if [[ ! -f "$target_dir/.env" ]]; then
        warn "No .env file found — cannot check DB"
        return
    fi

    local db_host db_port db_name db_user db_pass
    db_host=$(grep "^DATABASE_HOST=" "$target_dir/.env" 2>/dev/null | cut -d= -f2 | tr -d ' \r')
    db_port=$(grep "^DATABASE_PORT=" "$target_dir/.env" 2>/dev/null | cut -d= -f2 | tr -d ' \r')
    db_name=$(grep "^DATABASE_NAME=" "$target_dir/.env" 2>/dev/null | cut -d= -f2 | tr -d ' \r')
    db_user=$(grep "^DATABASE_USERNAME=" "$target_dir/.env" 2>/dev/null | cut -d= -f2 | tr -d ' \r')
    db_pass=$(grep "^DATABASE_PASSWORD=" "$target_dir/.env" 2>/dev/null | cut -d= -f2 | tr -d ' \r')

    [[ -z "$db_host" ]] && db_host="localhost"
    [[ -z "$db_port" ]] && db_port="3306"

    if command -v mysql &>/dev/null; then
        if TIMEOUT=5 mysql -h "$db_host" -P "$db_port" -u "$db_user" -p"$db_pass" "$db_name" -e "SELECT 1;" &>/dev/null; then
            ok "MySQL connection OK ($db_name@$db_host:$db_port)"
        else
            fail "MySQL connection failed ($db_user@$db_host:$db_port/$db_name)"
        fi
    elif command -v mariadb &>/dev/null; then
        if TIMEOUT=5 mariadb -h "$db_host" -P "$db_port" -u "$db_user" -p"$db_pass" "$db_name" -e "SELECT 1;" &>/dev/null; then
            ok "MariaDB connection OK"
        else
            fail "MariaDB connection failed"
        fi
    else
        warn "MySQL CLI not available — using API fallback"
        local api_code
        api_code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://${DOMAIN}/api/status" 2>/dev/null || echo "000")
        if [[ "$api_code" == "200" ]]; then
            ok "API responding (DB likely connected)"
        else
            fail "API unreachable — DB may be disconnected"
        fi
    fi
}

check_permissions() {
    echo ""
    echo "── File Permission Checks ─────────────────────────────────────"

    local deploy_dir="/var/www/vhosts/${DOMAIN}/httpdocs"
    local strapi_dir="$deploy_dir/strapi"

    for dir in \
        "$deploy_dir/system/storage/cache" \
        "$deploy_dir/system/storage/modification" \
        "$deploy_dir/system/storage/upload" \
        "$deploy_dir/image"; do
        if [[ -d "$dir" ]]; then
            if [[ -w "$dir" ]]; then
                ok "$dir writable"
            else
                fail "$dir not writable"
            fi
        fi
    done

    if [[ -d "$strapi_dir" ]]; then
        for dir in \
            "$strapi_dir/public/uploads" \
            "$strapi_dir/.cache" \
            "$strapi_dir/.tmp"; do
            [[ -d "$dir" ]] && [[ -w "$dir" ]] && ok "$dir writable" || warn "$dir not writable"
        done

        if [[ -f "$strapi_dir/.env" ]]; then
            local perm
            perm=$(stat -c '%a' "$strapi_dir/.env" 2>/dev/null || echo "000")
            if [[ "$perm" == "600" ]] || [[ "$perm" == "640" ]]; then
                ok ".env permissions OK ($perm)"
            else
                warn ".env permissions: $perm (should be 600)"
            fi
        fi
    fi
}

check_ssl() {
    echo ""
    echo "── SSL Certificate Check ───────────────────────────────────────"

    if command -v openssl &>/dev/null; then
        local ssl_result
        ssl_result=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" -brief 2>/dev/null | head -3 || echo "")
        if [[ -n "$ssl_result" ]]; then
            ok "SSL handshake OK"
            echo "$ssl_result" | while read -r line; do
                echo -e "    $line"
            done
        else
            fail "SSL handshake failed"
        fi
    else
        local code
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://${DOMAIN}" 2>/dev/null || echo "000")
        if [[ "$code" != "000" ]]; then
            ok "HTTPS responding (HTTP $code) — SSL likely valid"
        else
            fail "HTTPS not responding"
        fi
    fi
}

check_opencart_module() {
    echo ""
    echo "── OpenCart Module Check ──────────────────────────────────────"

    local deploy_dir="/var/www/vhosts/${DOMAIN}/httpdocs"

    if [[ -f "$deploy_dir/catalog/controller/module/bundle.php" ]]; then
        ok "Bundle controller found"
    else
        fail "Bundle controller missing"
    fi

    if [[ -f "$deploy_dir/admin/controller/module/bundle_manager.php" ]]; then
        ok "Bundle Manager admin controller found"
    else
        fail "Bundle Manager admin controller missing"
    fi

    if grep -q "STRAPI_API_URL" "$deploy_dir/config.php" 2>/dev/null; then
        ok "STRAPI_API_URL configured"
    else
        warn "STRAPI_API_URL not set in config.php"
    fi
}

check_strapi_logs() {
    echo ""
    echo "── Recent Log Summary ─────────────────────────────────────────"

    if command -v pm2 &>/dev/null; then
        local strapi_proc
        strapi_proc=$(pm2 list 2>/dev/null | grep -E "strapi[-_]" | grep -v grep | awk '{print $2}' | head -1 || echo "")
        if [[ -n "$strapi_proc" ]]; then
            local last_errors
            last_errors=$(pm2 logs "$strapi_proc" --lines 10 --nostream 2>/dev/null | grep -iE "error|fail|warn|exception" | tail -5 || echo "")
            if [[ -n "$last_errors" ]]; then
                warn "Recent log errors found:"
                echo "$last_errors" | while read -r line; do
                    echo -e "    ${YELLOW}⚠${NC} $line"
                done
            else
                ok "No recent errors in PM2 logs"
            fi
        fi
    fi
}

write_json_report() {
    local uptime
    uptime=$(uptime 2>/dev/null | awk -F'up' '{print $2}' | cut -d',' -f1 || echo "unknown")

    cat > "$HEALTH_FILE" <<EOF
{
  "domain": "$DOMAIN",
  "timestamp": "$(date -Iseconds)",
  "uptime": "$uptime",
  "status": "$([ $FAILED -eq 0 ] && echo "healthy" || echo "degraded")",
  "failed_checks": $FAILED,
  "openapi_url": "https://$DOMAIN",
  "strapi_admin_url": "https://$DOMAIN/strapi",
  "api_url": "https://$DOMAIN/api",
  "graphql_url": "https://$DOMAIN/graphql"
}
EOF
    log "Report written: $HEALTH_FILE"
}

main() {
    if [[ -z "$DOMAIN" ]]; then
        echo ""
        echo "Usage: bash healthcheck.sh <domain>"
        echo "Example: bash healthcheck.sh mystore.com"
        exit 1
    fi

    print_header
    log "Domain: $DOMAIN"
    log "Time: $(date)"
    echo ""

    check_process
    check_port
    check_http_endpoints
    check_database
    check_permissions
    check_ssl
    check_opencart_module
    check_strapi_logs

    echo ""
    echo "──────────────────────────────────────────────────────────────"
    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   ALL CHECKS PASSED — Deployment is healthy!       ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${RED}╔═══════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║   $FAILED CHECK(S) FAILED — Action required            ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "Run repair script: bash repair-plesk.sh $DOMAIN"
    fi
    echo ""

    write_json_report
}

main "$@"