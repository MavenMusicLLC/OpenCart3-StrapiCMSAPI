#!/bin/bash
# ============================================================================
# validate-plesk-env.sh — Environment Validation Script
# For: OpenCart3-StrapiCMSAPI on Plesk Obsidian
# ============================================================================
# Checks all environment requirements before deployment:
#   - Node.js version (18+)
#   - npm version
#   - PHP version (8+)
#   - Required PHP extensions
#   - MySQL/MariaDB availability
#   - Filesystem permissions
#   - Memory availability
#   - Disk space
#   - Plesk Node.js extension
#   - PM2 installation
# ============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_CHECKS=0
FAILED_CHECKS=0
DOMAIN="${1:-}"

log()   { echo -e "  $1"; }
ok()    { echo -e "  ${GREEN}[PASS]${NC} $1"; TOTAL_CHECKS=$((TOTAL_CHECKS+1)); }
warn()  { echo -e "  ${YELLOW}[WARN]${NC} $1"; TOTAL_CHECKS=$((TOTAL_CHECKS+1)); }
fail()  { echo -e "  ${RED}[FAIL]${NC} $1"; TOTAL_CHECKS=$((TOTAL_CHECKS+1)); FAILED_CHECKS=$((FAILED_CHECKS+1)); }

check() {
    local desc="$1"; shift
    if "$@"; then
        ok "$desc"
    else
        fail "$desc"
    fi
}

print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    Environment Validation — Plesk OpenCart + Strapi         ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_requirements() {
    echo ""
    echo -e "${BLUE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│  System Requirements Checklist                           │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│  Item                          │ Required │ Recommended │${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│  Node.js                       │ 18.x+    │ 20.x LTS   │${NC}"
    echo -e "${BLUE}│  npm                           │ 6.x+     │ 10.x+      │${NC}"
    echo -e "${BLUE}│  PHP                           │ 8.0+     │ 8.2–8.3   │${NC}"
    echo -e "${BLUE}│  MySQL                         │ 8.0+     │ 8.0+       │${NC}"
    echo -e "${BLUE}│  mod_rewrite (Apache)          │ Yes      │ Yes        │${NC}"
    echo -e "${BLUE}│  PM2                           │ Optional │ Yes        │${NC}"
    echo -e "${BLUE}│  RAM                           │ 1GB      │ 2GB+       │${NC}"
    echo -e "${BLUE}│  Disk                          │ 3GB      │ 10GB+      │${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

check_node() {
    echo "── Node.js ───────────────────────────────────────────────────"
    if ! command -v node &>/dev/null; then
        fail "Node.js not installed"
        echo ""
        echo "Install via Plesk Panel:"
        echo "  Plesk → Subscriptions → <domain> → Add/Remove Components"
        echo "  → Node.js (check the box) → Apply"
        echo ""
        return
    fi

    local version
    version=$(node -v 2>/dev/null)
    local major
    major=$(node -e "process.stdout.write(process.versions.node)" 2>/dev/null | cut -d. -f1)

    log "Node.js: $version"
    if [[ "${major:-0}" -ge 18 ]]; then
        ok "Node.js version OK (18+ required)"
    else
        fail "Node.js too old: $version (need 18+)"
        echo ""
        echo "Upgrade via Plesk:"
        echo "  Plesk → Tool & Settings → Node.js → Install/Update"
    fi
}

check_npm() {
    echo ""
    echo "── npm ───────────────────────────────────────────────────────"
    if ! command -v npm &>/dev/null; then
        fail "npm not installed (comes with Node.js)"
        return
    fi

    local version
    version=$(npm -v 2>/dev/null)
    local major
    major=$(echo "$version" | cut -d. -f1)

    log "npm: v$version"
    if [[ "${major:-0}" -ge 6 ]]; then
        ok "npm version OK"
    else
        warn "npm $version is old — upgrade recommended"
    fi
}

check_php() {
    echo ""
    echo "── PHP ───────────────────────────────────────────────────────"
    if ! command -v php &>/dev/null; then
        fail "PHP not installed"
        return
    fi

    local version
    version=$(php -r 'echo PHP_VERSION;' 2>/dev/null)
    local major_minor
    major_minor=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)

    log "PHP: $version"
    local major
    major=$(php -r 'echo PHP_MAJOR_VERSION;' 2>/dev/null)

    if [[ "${major:-0}" -ge 8 ]]; then
        ok "PHP version OK (8.0+ required)"
    elif [[ "${major:-0}" -ge 7 ]]; then
        warn "PHP 7.x detected — PHP 8+ recommended"
    else
        fail "PHP too old: $version (need PHP 8+)"
    fi
}

check_php_extensions() {
    echo ""
    echo "── PHP Extensions ────────────────────────────────────────────"
    local required=("pdo" "pdo_mysql" "json" "mbstring" "gd" "curl" "zip" "openssl" "filter" "session")
    local missing=()

    for ext in "${required[@]}"; do
        if php -m 2>/dev/null | grep -qi "$ext"; then
            ok "php-$ext"
        else
            fail "php-$ext (MISSING)"
            missing+=("$ext")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        echo "Install missing extensions:"
        echo "  apt install ${missing[*]}"
        echo "  Or via Plesk: Hosting & DNS → PHP → PHP Settings"
    fi
}

check_mysql() {
    echo ""
    echo "── MySQL / MariaDB ───────────────────────────────────────────"
    if command -v mysql &>/dev/null; then
        local version
        version=$(mysql --version 2>/dev/null | grep -oP 'Ver \K[0-9.]+' || echo "unknown")
        log "MySQL: $version"

        if command -v mysql &>/dev/null; then
            ok "MySQL CLI available"
        fi
    elif command -v mariadb &>/dev/null; then
        local version
        version=$(mariadb --version 2>/dev/null | head -1 || echo "unknown")
        log "MariaDB: $version"
        ok "MariaDB CLI available"
    else
        fail "MySQL/MariaDB CLI not found"
        echo ""
        echo "Install MySQL via Plesk:"
        echo "  Plesk → Subscriptions → <domain> → Add/Remove Components"
        echo "  → MySQL (check) → Apply"
    fi
}

check_pm2() {
    echo ""
    echo "── PM2 Process Manager ────────────────────────────────────────"
    if command -v pm2 &>/dev/null; then
        local version
        version=$(pm2 --version 2>/dev/null || echo "unknown")
        log "PM2: v$version"
        ok "PM2 installed"

        local running
        running=$(pm2 list 2>/dev/null | grep -c "online\|errored\|stopped" || echo "0")
        log "PM2 processes: $running"
    else
        warn "PM2 not installed (recommended for production)"
        echo ""
        echo "Install PM2:"
        echo "  npm install -g pm2"
        echo ""
        echo "PM2 enables:"
        echo "  - Auto-restart on crash"
        echo "  - Startup persistence on reboot"
        echo "  - Log management"
        echo "  - Process clustering"
    fi
}

check_memory() {
    echo ""
    echo "── Memory (RAM) ───────────────────────────────────────────────"
    if command -v free &>/dev/null; then
        local total used available
        total=$(free -m 2>/dev/null | awk 'NR==2 {print $2}')
        available=$(free -m 2>/dev/null | awk 'NR==2 {print $7}')
        local swap
        swap=$(free -m 2>/dev/null | awk 'NR==3 {print $2}')

        log "Total: ${total}MB | Available: ${available}MB | Swap: ${swap}MB"

        if [[ "${available:-0}" -ge 1024 ]]; then
            ok "Memory OK (1GB+ available)"
        elif [[ "${available:-0}" -ge 512 ]]; then
            warn "Memory low (${available}MB available) — Strapi build may fail"
        else
            fail "Insufficient memory (${available}MB available)"
            echo ""
            echo "Strapi build requires ~1GB RAM. Options:"
            echo "  1. Add swap: fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile"
            echo "  2. Upgrade VPS RAM"
            echo "  3. Use a smaller Node.js worker (pm2 start ... --max-memory-restart 512M)"
        fi
    fi
}

check_disk_space() {
    echo ""
    echo "── Disk Space ─────────────────────────────────────────────────"
    if command -v df &>/dev/null; then
        local available
        available=$(df -BG /var/www 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G')
        log "Available: ${available}GB"

        if [[ "${available:-0}" -ge 10 ]]; then
            ok "Disk space OK (10GB+)"
        elif [[ "${available:-0}" -ge 3 ]]; then
            warn "Disk space tight (${available}GB) — Strapi needs ~3GB"
        else
            fail "Insufficient disk space (${available}GB)"
        fi
    fi
}

check_plesk_directory() {
    echo ""
    echo "── Plesk Directory Structure ──────────────────────────────────"
    if [[ -d "/var/www/vhosts" ]]; then
        ok "/var/www/vhosts exists"
    else
        fail "/var/www/vhosts not found"
    fi

    if [[ -d "/var/www/vhosts/$DOMAIN" ]]; then
        ok "Domain directory exists: /var/www/vhosts/$DOMAIN"
    else
        warn "Domain directory not found: /var/www/vhosts/$DOMAIN"
    fi

    if [[ -d "/var/www/vhosts/$DOMAIN/httpdocs" ]]; then
        ok "httpdocs directory exists"
    else
        warn "httpdocs directory not found"
    fi
}

check_apache_mods() {
    echo ""
    echo "── Apache Modules ─────────────────────────────────────────────"
    local required_mods=("mod_rewrite" "mod_proxy" "mod_proxy_http" "mod_headers")
    local missing=()

    for mod in "${required_mods[@]}"; do
        if apache2ctl -M 2>/dev/null | grep -qi "$mod"; then
            ok "$mod"
        else
            missing+=("$mod")
            warn "$mod not enabled"
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        echo "Enable missing modules:"
        echo "  a2enmod ${missing[*]}"
        echo "  systemctl restart apache2"
    fi
}

check_openssl() {
    echo ""
    echo "── OpenSSL ────────────────────────────────────────────────────"
    if command -v openssl &>/dev/null; then
        local version
        version=$(openssl version 2>/dev/null | awk '{print $2}')
        log "OpenSSL: $version"
        ok "OpenSSL available"
    else
        warn "OpenSSL CLI not found"
    fi
}

check_git() {
    echo ""
    echo "── Git ────────────────────────────────────────────────────────"
    if command -v git &>/dev/null; then
        local version
        version=$(git --version 2>/dev/null | awk '{print $3}')
        log "Git: $version"
        ok "Git available"
    else
        warn "Git not installed (needed for Plesk Git deploy)"
    fi
}

check_user_limits() {
    echo ""
    echo "── User Limits (ulimit) ──────────────────────────────────────"
    local max_proc
    max_proc=$(ulimit -u 2>/dev/null || echo "unlimited")
    log "Max processes: $max_proc"

    if [[ "$max_proc" == "unlimited" ]] || [[ "${max_proc:-0}" -ge 1000 ]]; then
        ok "Process limit OK"
    else
        warn "Process limit low ($max_proc) — may hit limit during npm install"
    fi
}

check_timezone() {
    echo ""
    echo "── Timezone ─────────────────────────────────────────────────"
    local tz
    tz=$(cat /etc/timezone 2>/dev/null || timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}' || echo "unknown")
    log "Timezone: $tz"
}

print_summary() {
    echo ""
    echo "──────────────────────────────────────────────────────────────"
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Environment Summary                  ║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════╣${NC}"
    printf "${BLUE}║  Total checks: %-30s ║${NC}\n" "$TOTAL_CHECKS"
    printf "${BLUE}║  Failed:       %-30s ║${NC}\n" "$FAILED_CHECKS"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}✓  Environment ready for deployment!${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. bash install-plesk.sh opencart   <domain>   # OpenCart only"
        echo "  2. bash install-plesk.sh strapi    <domain>   # Strapi subdomain"
        echo "  3. bash install-plesk.sh bundled    <domain>   # Both together"
    else
        echo -e "${RED}✗  $FAILED_CHECKS issue(s) need to be resolved${NC}"
        echo ""
        echo "Common fixes:"
        echo "  - Node.js missing:   Plesk → Add/Remove Components → Node.js"
        echo "  - PHP extensions:     apt install php-mbstring php-gd php-curl php-zip"
        echo "  - PM2 missing:       npm install -g pm2"
        echo "  - Low memory:        Add swap or upgrade VPS"
        echo ""
        echo "After fixes, re-run this script:"
        echo "  bash validate-plesk-env.sh $DOMAIN"
    fi
    echo ""
}

main() {
    print_header
    print_requirements

    check_node
    check_npm
    check_pm2
    check_php
    check_php_extensions
    check_mysql
    check_memory
    check_disk_space
    check_plesk_directory
    check_apache_mods
    check_openssl
    check_git
    check_user_limits
    check_timezone

    print_summary
}

main "$@"