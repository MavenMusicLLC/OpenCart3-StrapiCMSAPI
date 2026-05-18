#!/bin/bash
# ============================================================
# OpenCart + Strapi Bundle System - Deploy Script
# ============================================================
# This script deploys the bundle system for OpenCart with Strapi integration
# Compatible with OpenCart 3.x and Strapi 5.x
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OPENCART_ROOT="${OPENCART_ROOT:-/var/www/vhosts/noxhosting.cloud/oc.noxhosting.cloud}"
STRAPI_ROOT="${STRAPI_ROOT:-/var/www/vhosts/noxhosting.cloud/api-oc.noxhosting.cloud}"
OPENCART_DB_HOST="${DB_HOST:-localhost}"
OPENCART_DB_NAME="${DB_NAME:-ocdev1}"
OPENCART_DB_USER="${DB_USER:-ocdev1}"
OPENCART_DB_PASS="${DB_PASSWORD}"
STRAPI_PORT="${STRAPI_PORT:-1337}"
STRAPI_API_URL="${STRAPI_API_URL:-http://localhost:1337}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  OpenCart + Strapi Bundle Deploy${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check requirements
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    if [ ! -d "$OPENCART_ROOT" ]; then
        echo -e "${RED}Error: OpenCart directory not found at $OPENCART_ROOT${NC}"
        exit 1
    fi
    
    if [ ! -d "$STRAPI_ROOT" ]; then
        echo -e "${RED}Error: Strapi directory not found at $STRAPI_ROOT${NC}"
        exit 1
    fi
    
    if ! command -v mysql &> /dev/null; then
        echo -e "${RED}Error: MySQL client not found${NC}"
        exit 1
    fi
    
    if ! command -v node &> /dev/null; then
        echo -e "${RED}Error: Node.js not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All requirements met!${NC}"
}

# Install database tables
install_database() {
    echo -e "${YELLOW}Installing bundle database tables...${NC}"
    
    if [ -z "$OPENCART_DB_PASS" ]; then
        echo -e "${YELLOW}Database password not set. Please enter:${NC}"
        read -s OPENCART_DB_PASS
    fi
    
    mysql -h "$OPENCART_DB_HOST" -u "$OPENCART_DB_USER" -p"$OPENCART_DB_PASS" "$OPENCART_DB_NAME" < "$OPENCART_ROOT/install/bundle_install.sql"
    
    echo -e "${GREEN}Database tables installed successfully!${NC}"
}

# Install OpenCart module
install_opencart() {
    echo -e "${YELLOW}Installing OpenCart bundle module...${NC}"
    
    # Create symlinks or copy files
    # Ensure module directories exist
    mkdir -p "$OPENCART_ROOT/catalog/controller/module"
    mkdir -p "$OPENCART_ROOT/catalog/model/module"
    mkdir -p "$OPENCART_ROOT/catalog/view/theme/default/template/module"
    mkdir -p "$OPENCART_ROOT/admin/controller/module"
    mkdir -p "$OPENCART_ROOT/admin/model/module"
    mkdir -p "$OPENCART_ROOT/admin/view/module"
    mkdir -p "$OPENCART_ROOT/catalog/controller/extension/module"
    mkdir -p "$OPENCART_ROOT/catalog/model/setting"
    
    # Update OpenCart config with Strapi API URL
    CONFIG_FILE="$OPENCART_ROOT/config.php"
    if [ -f "$CONFIG_FILE" ]; then
        if ! grep -q "STRAPI_API_URL" "$CONFIG_FILE"; then
            echo -e "${YELLOW}Adding Strapi API URL to OpenCart config...${NC}"
            echo "" >> "$CONFIG_FILE"
            echo "// Bundle Manager - Strapi API" >> "$CONFIG_FILE"
            echo "define('STRAPI_API_URL', '$STRAPI_API_URL/api');" >> "$CONFIG_FILE"
        fi
    fi
    
    # Copy deploy-specific config
    cat > "$OPENCART_ROOT/system/config/bundle.php" << 'EOF'
<?php
// Bundle Manager Configuration
$_['bundle_manager_api_url'] = defined('STRAPI_API_URL') ? STRAPI_API_URL : 'http://localhost:1337/api';
$_['bundle_manager_api_timeout'] = 5;
$_['bundle_manager_cache_ttl'] = 3600;
$_['bundle_manager_show_on_product'] = true;
$_['bundle_manager_show_on_category'] = true;
$_['bundle_manager_module_title'] = 'Product Bundles';
EOF
    
    echo -e "${GREEN}OpenCart module files configured!${NC}"
}

# Build and configure Strapi
install_strapi() {
    echo -e "${YELLOW}Configuring Strapi...${NC}"
    
    cd "$STRAPI_ROOT"
    
    # Install dependencies if needed
    if [ ! -d "$STRAPI_ROOT/node_modules" ]; then
        echo -e "${YELLOW}Installing Strapi dependencies...${NC}"
        npm install
    fi
    
    # Build Strapi
    echo -e "${YELLOW}Building Strapi...${NC}"
    npm run build
    
    # Update CORS config for OpenCart
    mkdir -p "$STRAPI_ROOT/config"
    cat > "$STRAPI_ROOT/config/middlewares.js" << EOF
module.exports = [
  'strapi::errors',
  {
    name: 'strapi::security',
    config: {
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'connect-src': ["'self'", 'https:', 'http:'],
          'img-src': ["'self'", 'data:', 'blob:', 'https:', 'http:'],
          'media-src': ["'self'", 'data:', 'blob:', 'https:', 'http:'],
          upgradeInsecureRequests: null,
        },
      },
    },
  },
  {
    name: 'strapi::cors',
    config: {
      enabled: true,
      headers: '*',
      origin: ['*']
    }
  },
  'strapi::poweredBy',
  'strapi::logger',
  'strapi::query',
  'strapi::body',
  'strapi::session',
  'strapi::favicon',
  'strapi::public',
];
EOF
    
    echo -e "${GREEN}Strapi configured successfully!${NC}"
}

# Start services
start_services() {
    echo -e "${YELLOW}Starting services...${NC}"
    
    # Start Strapi in background
    cd "$STRAPI_ROOT"
    nohup npm start > /tmp/strapi.log 2>&1 &
    
    # Wait for Strapi to be ready
    echo -e "${YELLOW}Waiting for Strapi to be ready...${NC}"
    for i in {1..30}; do
        if curl -s "http://localhost:$STRAPI_PORT/api/bundles" > /dev/null 2>&1; then
            echo -e "${GREEN}Strapi is running on port $STRAPI_PORT${NC}"
            break
        fi
        sleep 2
    done
    
    echo -e "${GREEN}Services started!${NC}"
}

# Test endpoints
test_endpoints() {
    echo -e "${YELLOW}Testing API endpoints...${NC}"
    
    # Test Strapi bundles endpoint
    RESPONSE=$(curl -s "$STRAPI_API_URL/api/bundles" || echo "")
    if [ -n "$RESPONSE" ]; then
        echo -e "${GREEN}Strapi bundles endpoint: OK${NC}"
    else
        echo -e "${RED}Strapi bundles endpoint: FAIL${NC}"
    fi
    
    # Test OpenCart (if web server is running)
    if curl -s "https://oc.noxhosting.cloud" > /dev/null 2>&1; then
        echo -e "${GREEN}OpenCart site: OK${NC}"
    else
        echo -e "${YELLOW}OpenCart site: Could not verify (may need web server restart)${NC}"
    fi
}

# Show deployment info
show_info() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Deployment Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Strapi Admin:${NC} http://localhost:$STRAPI_PORT/admin"
    echo -e "${BLUE}Strapi API:${NC} $STRAPI_API_URL/api"
    echo -e "${BLUE}OpenCart:${NC} $OPENCART_ROOT"
    echo ""
    echo -e "${YELLOW}API Endpoints:${NC}"
    echo "  GET  /api/bundles               - List all bundles"
    echo "  GET  /api/bundles/:id           - Get bundle by ID"
    echo "  GET  /api/bundles/by-slug/:slug - Get bundle by slug"
    echo "  GET  /api/bundles/by-product/:id- Get bundles containing product"
    echo "  POST /api/bundles/sync          - Sync from OpenCart"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Go to Strapi Admin and create bundles"
    echo "  2. Configure OpenCart Extensions > Modules > Bundle Manager"
    echo "  3. Add bundles module to your store layout"
    echo ""
}

# Main execution
case "${1:-deploy}" in
    deploy)
        check_requirements
        install_database
        install_opencart
        install_strapi
        start_services
        test_endpoints
        show_info
        ;;
    db-only)
        install_database
        ;;
    opencart-only)
        install_opencart
        ;;
    strapi-only)
        install_strapi
        start_services
        ;;
    test)
        test_endpoints
        ;;
    *)
        echo "Usage: $0 [deploy|db-only|opencart-only|strapi-only|test]"
        exit 1
        ;;
esac