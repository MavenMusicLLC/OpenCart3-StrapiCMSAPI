#!/bin/bash
# ============================================================================
# Strapi CMS Subdomain Setup for Plesk
# ============================================================================
# This script sets up Strapi on a subdomain (e.g., api.yourdomain.com)
# with native Plesk integration including Node.js support
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_DOMAIN="${1:-}"
SUBDOMAIN="${2:-api}"
NODE_VERSION="${NODE_VERSION:-18}"
STRAPI_PORT="${STRAPI_PORT:-1337}"
DB_NAME="${DB_NAME:-}"
DB_USER="${DB_USER:-}"
DB_PASS="${DB_PASS:-}"

# Print header
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Strapi CMS Subdomain Setup${NC}"
    echo -e "${BLUE}  For Plesk Hosting${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Show help
show_help() {
    echo -e "${BOLD}Strapi Subdomain Setup${NC}"
    echo ""
    echo "Usage: sudo ./setup-strapi-subdomain.sh [MAIN_DOMAIN] [SUBDOMAIN] [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  MAIN_DOMAIN   Your main domain (e.g., noxhosting.cloud)"
    echo "  SUBDOMAIN     Subdomain prefix (default: api)"
    echo ""
    echo "Options:"
    echo "  --node-version=VERSION  Node.js version (default: 18)"
    echo "  --port=PORT             Strapi port (default: 1337)"
    echo "  --db-name=NAME          Database name"
    echo "  --db-user=USER          Database user"
    echo "  --db-pass=PASSWORD      Database password"
    echo "  --help                  Show this help"
    echo ""
    echo "Examples:"
    echo "  sudo ./setup-strapi-subdomain.sh noxhosting.cloud api"
    echo "  sudo ./setup-strapi-subdomain.sh example.com cms --port=3000"
    echo ""
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        --node-version=*)
            NODE_VERSION="${arg#*=}"
            ;;
        --port=*)
            STRAPI_PORT="${arg#*=}"
            ;;
        --db-name=*)
            DB_NAME="${arg#*=}"
            ;;
        --db-user=*)
            DB_USER="${arg#*=}"
            ;;
        --db-pass=*)
            DB_PASS="${arg#*=}"
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
    esac
done

# Check if running as root
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This script must be run as root or with sudo${NC}"
        exit 1
    fi
}

# Detect domain if not provided
detect_domain() {
    if [ -z "$MAIN_DOMAIN" ]; then
        # Try to detect from Plesk
        if [ -d "/var/www/vhosts" ]; then
            echo -e "${YELLOW}Available domains:${NC}"
            ls /var/www/vhosts/ | grep -v "^\." | head -20
            echo ""
            read -p "Enter your main domain: " MAIN_DOMAIN
        else
            echo -e "${RED}Could not detect domain. Please provide it as argument.${NC}"
            show_help
            exit 1
        fi
    fi
    
    FULL_DOMAIN="${SUBDOMAIN}.${MAIN_DOMAIN}"
    DOC_ROOT="/var/www/vhosts/${MAIN_DOMAIN}/${SUBDOMAIN}"
    
    echo -e "${CYAN}Main Domain: $MAIN_DOMAIN${NC}"
    echo -e "${CYAN}Subdomain: $FULL_DOMAIN${NC}"
    echo -e "${CYAN}Document Root: $DOC_ROOT${NC}"
}

# Check requirements
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    local errors=0
    
    # Check Plesk
    if [ ! -f "/usr/local/psa/bin/domain" ] && [ ! -f "/opt/psa/bin/domain" ]; then
        echo -e "  ${YELLOW}!${NC} Plesk CLI not found, will use manual setup"
    else
        echo -e "  ${GREEN}✓${NC} Plesk detected"
    fi
    
    # Check Node.js
    if command -v node &> /dev/null; then
        NODE_CURRENT=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        echo -e "  ${GREEN}✓${NC} Node.js $(node -v)"
        
        if [ "$NODE_CURRENT" -lt "$NODE_VERSION" ]; then
            echo -e "  ${YELLOW}!${NC} Node.js $NODE_CURRENT found, but $NODE_VERSION+ recommended"
        fi
    else
        echo -e "  ${YELLOW}!${NC} Node.js not found, will install"
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} npm $(npm -v)"
    else
        echo -e "  ${YELLOW}!${NC} npm not found"
        errors=$((errors + 1))
    fi
    
    # Check MySQL
    if command -v mysql &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} MySQL client"
    else
        echo -e "  ${RED}✗${NC} MySQL client not found"
        errors=$((errors + 1))
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "${RED}Some requirements missing. Installing...${NC}"
    fi
}

# Install Node.js
install_nodejs() {
    echo -e "${YELLOW}Installing Node.js ${NODE_VERSION}...${NC}"
    
    if [ -f "/usr/local/psa/admin/bin/npm-installer" ]; then
        # Use Plesk's Node.js installer
        echo -e "  ${CYAN}→${NC} Using Plesk Node.js installer"
        /usr/local/psa/admin/bin/npm-installer --install-nodejs "${NODE_VERSION}"
    else
        # Use NodeSource
        curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -
        apt-get install -y nodejs
    fi
    
    echo -e "  ${GREEN}✓${NC} Node.js $(node -v) installed"
}

# Create subdomain in Plesk
create_subdomain() {
    echo -e "${YELLOW}Creating subdomain...${NC}"
    
    if command -v plesk &> /dev/null; then
        # Use Plesk CLI
        plesk bin subdomain --create "$SUBDOMAIN" -domain "$MAIN_DOMAIN" -www-root "$SUBDOMAIN" 2>/dev/null || {
            echo -e "  ${YELLOW}!${NC} Subdomain may already exist or using manual setup"
        }
    elif [ -f "/usr/local/psa/bin/subdomain" ]; then
        /usr/local/psa/bin/subdomain --create "$SUBDOMAIN" -domain "$MAIN_DOMAIN" -www-root "$SUBDOMAIN" 2>/dev/null || true
    fi
    
    # Create document root if not exists
    if [ ! -d "$DOC_ROOT" ]; then
        mkdir -p "$DOC_ROOT"
        echo -e "  ${GREEN}✓${NC} Created document root: $DOC_ROOT"
    fi
}

# Setup Strapi
setup_strapi() {
    echo -e "${YELLOW}Setting up Strapi...${NC}"
    
    cd "$DOC_ROOT"
    
    # Get database credentials if not provided
    if [ -z "$DB_NAME" ]; then
        DB_NAME="strapi_${SUBDOMAIN}"
    fi
    if [ -z "$DB_USER" ]; then
        DB_USER="strapi_${SUBDOMAIN}"
    fi
    if [ -z "$DB_PASS" ]; then
        DB_PASS=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 16)
    fi
    
    echo -e "  ${CYAN}→${NC} Database: $DB_NAME"
    echo -e "  ${CYAN}→${NC} DB User: $DB_USER"
    
    # Create database
    mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || {
        echo -e "  ${YELLOW}!${NC} Could not create database, may need manual setup"
    }
    
    # Create database user
    mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" 2>/dev/null || true
    mysql -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';" 2>/dev/null || true
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    
    echo -e "  ${GREEN}✓${NC} Database configured"
    
    # Copy Strapi source files
    if [ -d "$SCRIPT_DIR/src" ]; then
        cp -r "$SCRIPT_DIR/src" "$DOC_ROOT/"
        echo -e "  ${GREEN}✓${NC} Copied Strapi source files"
    fi
    
    # Create package.json if not exists
    if [ ! -f "$DOC_ROOT/package.json" ]; then
        cat > "$DOC_ROOT/package.json" << 'EOF'
{
  "name": "strapi-cms-api",
  "version": "1.0.0",
  "description": "Strapi CMS for OpenCart Bundle System",
  "scripts": {
    "develop": "strapi develop",
    "start": "strapi start",
    "build": "strapi build",
    "strapi": "strapi"
  },
  "dependencies": {
    "@strapi/strapi": "5.0.0",
    "@strapi/plugin-users-permissions": "5.0.0",
    "mysql2": "^3.9.0"
  },
  "strapi": {
    "uuid": "opencart-bundle-system"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  }
}
EOF
        echo -e "  ${GREEN}✓${NC} Created package.json"
    fi
    
    # Create .env file
    JWT_SECRET=$(openssl rand -base64 32)
    ADMIN_JWT_SECRET=$(openssl rand -base64 32)
    APP_KEYS=$(openssl rand -base64 32),$(openssl rand -base64 32),$(openssl rand -base64 32),$(openssl rand -base64 32)
    API_TOKEN_SALT=$(openssl rand -base64 32)
    TRANSFER_TOKEN_SALT=$(openssl rand -base64 32)
    
    cat > "$DOC_ROOT/.env" << EOF
# Server
HOST=127.0.0.1
PORT=${STRAPI_PORT}

# Secrets
APP_KEYS=${APP_KEYS}
API_TOKEN_SALT=${API_TOKEN_SALT}
ADMIN_JWT_SECRET=${ADMIN_JWT_SECRET}
TRANSFER_TOKEN_SALT=${TRANSFER_TOKEN_SALT}
JWT_SECRET=${JWT_SECRET}

# Database
DATABASE_CLIENT=mysql
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_NAME=${DB_NAME}
DATABASE_USERNAME=${DB_USER}
DATABASE_PASSWORD=${DB_PASS}
DATABASE_SSL=false

# Advanced
WEBSITE_URL=https://${FULL_DOMAIN}
EOF
    
    chmod 600 "$DOC_ROOT/.env"
    echo -e "  ${GREEN}✓${NC} Created .env configuration"
    
    # Install dependencies
    echo -e "  ${CYAN}→${NC} Installing Node.js dependencies (this may take a few minutes)..."
    cd "$DOC_ROOT"
    npm install 2>&1 | tail -5
    
    echo -e "  ${GREEN}✓${NC} Dependencies installed"
}

# Create systemd service for auto-start
create_systemd_service() {
    echo -e "${YELLOW}Creating systemd service...${NC}"
    
    # Detect Plesk user
    PLESK_USER=$(stat -c '%U' "/var/www/vhosts/${MAIN_DOMAIN}/httpdocs" 2>/dev/null || echo "root")
    
    cat > "/etc/systemd/system/strapi-${SUBDOMAIN}.service" << EOF
[Unit]
Description=Strapi CMS for ${FULL_DOMAIN}
Documentation=https://docs.strapi.io
After=network.target mysql.service

[Service]
Type=simple
User=${PLESK_USER}
Group=psacln
WorkingDirectory=${DOC_ROOT}
Environment=NODE_ENV=production
Environment=PATH=/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/node ${DOC_ROOT}/node_modules/.bin/strapi start
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=strapi-${SUBDOMAIN}

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable "strapi-${SUBDOMAIN}.service"
    
    echo -e "  ${GREEN}✓${NC} Created systemd service: strapi-${SUBDOMAIN}"
}

# Configure nginx reverse proxy
configure_nginx() {
    echo -e "${YELLOW}Configuring nginx...${NC}"
    
    # Find nginx config path
    NGINX_CONF=""
    if [ -d "/etc/nginx/plesk.conf.d" ]; then
        NGINX_CONF="/etc/nginx/plesk.conf.d/vhosts/${FULL_DOMAIN}.conf"
    elif [ -d "/etc/nginx/conf.d" ]; then
        NGINX_CONF="/etc/nginx/conf.d/${FULL_DOMAIN}.conf"
    fi
    
    if [ -n "$NGINX_CONF" ]; then
        cat > "$NGINX_CONF" << EOF
# Strapi Subdomain Configuration
# Auto-generated for ${FULL_DOMAIN}

server {
    listen 80;
    listen [::]:80;
    server_name ${FULL_DOMAIN};
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${FULL_DOMAIN};
    
    root ${DOC_ROOT};
    index index.html;
    
    # SSL Configuration (Plesk manages this)
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Proxy to Strapi
    location / {
        proxy_pass http://127.0.0.1:${STRAPI_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Admin panel
    location /admin {
        proxy_pass http://127.0.0.1:${STRAPI_PORT}/admin;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # API endpoints
    location /api {
        proxy_pass http://127.0.0.1:${STRAPI_PORT}/api;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers for OpenCart
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization" always;
    }
    
    # Static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri @proxy;
    }
    
    location @proxy {
        proxy_pass http://127.0.0.1:${STRAPI_PORT};
    }
    
    # Uploads
    location /uploads {
        alias ${DOC_ROOT}/public/uploads;
        expires 1y;
        add_header Cache-Control "public";
    }
}
EOF
        
        # Test nginx config
        nginx -t 2>/dev/null && {
            systemctl reload nginx 2>/dev/null || service nginx reload 2>/dev/null
            echo -e "  ${GREEN}✓${NC} Nginx configured and reloaded"
        } || {
            echo -e "  ${YELLOW}!${NC} Nginx config test failed, may need manual review"
        }
    else
        echo -e "  ${YELLOW}!${NC} Nginx config path not found, manual configuration needed"
    fi
}

# Configure Apache (fallback)
configure_apache() {
    echo -e "${YELLOW}Configuring Apache...${NC}"
    
    # Create .htaccess for the subdomain
    cat > "$DOC_ROOT/.htaccess" << 'EOF'
# Strapi CMS - Apache Configuration
# Enable rewrite engine
RewriteEngine On
RewriteBase /

# Proxy all requests to Strapi
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ http://127.0.0.1:${STRAPI_PORT}/$1 [P,L]

# CORS Headers
<IfModule mod_headers.c>
    Header set Access-Control-Allow-Origin "*"
    Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
    Header set Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization"
</IfModule>

# Security
<IfModule mod_headers.c>
    Header set X-Frame-Options "SAMEORIGIN"
    Header set X-Content-Type-Options "nosniff"
    Header set X-XSS-Protection "1; mode=block"
</IfModule>

# Compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css application/javascript application/json
</IfModule>

# Caching
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
</IfModule>
EOF
    
    echo -e "  ${GREEN}✓${NC} Created .htaccess"
}

# Start Strapi
start_strapi() {
    echo -e "${YELLOW}Starting Strapi...${NC}"
    
    # Build Strapi first
    cd "$DOC_ROOT"
    echo -e "  ${CYAN}→${NC} Building Strapi..."
    npm run build 2>&1 | tail -10
    
    # Start with systemd or directly
    if systemctl is-active --quiet "strapi-${SUBDOMAIN}" 2>/dev/null; then
        systemctl restart "strapi-${SUBDOMAIN}"
    else
        # Start directly
        nohup npm start > /tmp/strapi-${SUBDOMAIN}.log 2>&1 &
    fi
    
    # Wait for startup
    echo -e "  ${CYAN}→${NC} Waiting for Strapi to start..."
    for i in {1..30}; do
        if curl -s "http://127.0.0.1:${STRAPI_PORT}" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} Strapi is running on port ${STRAPI_PORT}"
            return 0
        fi
        sleep 2
    done
    
    echo -e "  ${YELLOW}!${NC} Strapi may need manual start"
}

# Create OpenCart config update script
update_opencart_config() {
    echo -e "${YELLOW}Updating OpenCart configuration...${NC}"
    
    OPENCART_ROOT="/var/www/vhosts/${MAIN_DOMAIN}/httpdocs"
    
    if [ -f "$OPENCART_ROOT/config.php" ]; then
        # Update or add STRAPI_API_URL
        if grep -q "STRAPI_API_URL" "$OPENCART_ROOT/config.php"; then
            sed -i "s|define('STRAPI_API_URL'.*|define('STRAPI_API_URL', 'https://${FULL_DOMAIN}/api');|" "$OPENCART_ROOT/config.php"
        else
            echo "
// Bundle Manager - Strapi API Integration (Subdomain)
define('STRAPI_API_URL', 'https://${FULL_DOMAIN}/api');" >> "$OPENCART_ROOT/config.php"
        fi
        
        # Update admin config too
        if [ -f "$OPENCART_ROOT/admin/config.php" ]; then
            if grep -q "STRAPI_API_URL" "$OPENCART_ROOT/admin/config.php"; then
                sed -i "s|define('STRAPI_API_URL'.*|define('STRAPI_API_URL', 'https://${FULL_DOMAIN}/api');|" "$OPENCART_ROOT/admin/config.php"
            else
                echo "
// Bundle Manager - Strapi API Integration (Subdomain)
define('STRAPI_API_URL', 'https://${FULL_DOMAIN}/api');" >> "$OPENCART_ROOT/admin/config.php"
            fi
        fi
        
        echo -e "  ${GREEN}✓${NC} Updated OpenCart config with: https://${FULL_DOMAIN}/api"
    else
        echo -e "  ${YELLOW}!${NC} OpenCart config not found at $OPENCART_ROOT"
    fi
}

# Create info file
create_info_file() {
    cat > "$DOC_ROOT/STRAPI_INFO.txt" << EOF
========================================
  Strapi CMS - Subdomain Setup
========================================

Domain: ${FULL_DOMAIN}
Port: ${STRAPI_PORT}
Document Root: ${DOC_ROOT}

Access URLs:
- Admin Panel: https://${FULL_DOMAIN}/admin
- API: https://${FULL_DOMAIN}/api
- Frontend: https://${FULL_DOMAIN}

Database:
- Name: ${DB_NAME}
- User: ${DB_USER}
- Password: ${DB_PASS}

Service:
- systemctl start strapi-${SUBDOMAIN}
- systemctl stop strapi-${SUBDOMAIN}
- systemctl status strapi-${SUBDOMAIN}
- systemctl restart strapi-${SUBDOMAIN}

Logs:
- journalctl -u strapi-${SUBDOMAIN} -f
- tail -f /tmp/strapi-${SUBDOMAIN}.log

OpenCart Integration:
- API URL: https://${FULL_DOMAIN}/api
- Updated in config.php and admin/config.php

========================================
EOF
    
    chmod 600 "$DOC_ROOT/STRAPI_INFO.txt"
    echo -e "  ${GREEN}✓${NC} Created info file: $DOC_ROOT/STRAPI_INFO.txt"
}

# Main execution
main() {
    print_header
    check_sudo
    detect_domain
    check_requirements
    
    # Install Node.js if needed
    if ! command -v node &> /dev/null; then
        install_nodejs
    fi
    
    create_subdomain
    setup_strapi
    create_systemd_service
    
    # Configure web server
    if [ -d "/etc/nginx" ]; then
        configure_nginx
    fi
    
    if [ -d "/etc/apache2" ] || [ -d "/etc/httpd" ]; then
        configure_apache
    fi
    
    start_strapi
    update_opencart_config
    create_info_file
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Strapi Setup Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${CYAN}Admin Panel:${NC} https://${FULL_DOMAIN}/admin"
    echo -e "${CYAN}API URL:${NC} https://${FULL_DOMAIN}/api"
    echo -e "${CYAN}OpenCart Config:${NC} Updated with new API URL"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Go to https://${FULL_DOMAIN}/admin"
    echo "  2. Create your first admin user"
    echo "  3. The Bundle content type is pre-configured"
    echo "  4. Create bundles in Strapi"
    echo "  5. They'll sync automatically with OpenCart"
    echo ""
    echo -e "${YELLOW}Service Management:${NC}"
    echo "  systemctl start strapi-${SUBDOMAIN}"
    echo "  systemctl stop strapi-${SUBDOMAIN}"
    echo "  systemctl restart strapi-${SUBDOMAIN}"
    echo ""
}

# Run main
main "$@"