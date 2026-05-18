#!/bin/bash
# ============================================================================
# OpenCart Bundle System - Plesk Auto-Installer
# ============================================================================
# Compatible with Plesk Obsidian and newer
# Usage: sudo ./plesk-install.sh [--domain=DOMAIN] [--plesk-user=USER]
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCART_ROOT="${SCRIPT_DIR}/.."
DOMAIN=""
PLESK_USER=""
DB_HOST="localhost"
DB_NAME=""
DB_USER=""
DB_PASS=""
STRAPI_DOMAIN=""
AUTO_YES=false
FIX_PERMISSIONS=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --domain=*)
            DOMAIN="${arg#*=}"
            shift
            ;;
        --plesk-user=*)
            PLESK_USER="${arg#*=}"
            shift
            ;;
        --db-host=*)
            DB_HOST="${arg#*=}"
            shift
            ;;
        --db-name=*)
            DB_NAME="${arg#*=}"
            shift
            ;;
        --db-user=*)
            DB_USER="${arg#*=}"
            shift
            ;;
        --db-pass=*)
            DB_PASS="${arg#*=}"
            shift
            ;;
        --strapi-domain=*)
            STRAPI_DOMAIN="${arg#*=}"
            shift
            ;;
        --yes|-y)
            AUTO_YES=true
            shift
            ;;
        --fix-permissions)
            FIX_PERMISSIONS=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
    esac
done

# Help function
show_help() {
    echo -e "${BOLD}OpenCart Bundle System - Plesk Installer${NC}"
    echo ""
    echo "Usage: sudo $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --domain=DOMAIN         Plesk domain name (e.g., oc.noxhosting.cloud)"
    echo "  --plesk-user=USER       Plesk system user (e.g., noxhosting.cloud_u2hif4o4jyi)"
    echo "  --db-host=HOST          Database host (default: localhost)"
    echo "  --db-name=NAME          Database name (auto-detected if not set)"
    echo "  --db-user=USER          Database user (auto-detected if not set)"
    echo "  --db-pass=PASSWORD      Database password (will prompt if not set)"
    echo "  --strapi-domain=DOMAIN  Strapi domain (optional, e.g., api-oc.noxhosting.cloud)"
    echo "  --yes, -y               Auto-answer yes to all prompts"
    echo "  --fix-permissions       Fix file permissions for Plesk"
    echo "  --help, -h              Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo $0 --domain=oc.noxhosting.cloud"
    echo "  sudo $0 --domain=oc.noxhosting.cloud --plesk-user=noxhosting.cloud_u2hif4o4jyi"
    echo "  sudo $0 --domain=oc.noxhosting.cloud --yes"
}

# Print header
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  OpenCart Bundle System Installer${NC}"
    echo -e "${BLUE}  Plesk Edition${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Detect Plesk domain from current directory
detect_domain() {
    if [ -z "$DOMAIN" ]; then
        # Try to detect from path
        if [[ "$OPENCART_ROOT" == *"/var/www/vhosts/"* ]]; then
            DOMAIN=$(echo "$OPENCART_ROOT" | sed 's|/var/www/vhosts/||;s|/.*||')
        fi
    fi
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${YELLOW}Could not auto-detect domain.${NC}"
        read -p "Enter your domain name (e.g., oc.noxhosting.cloud): " DOMAIN
    fi
    
    echo -e "${CYAN}Domain: $DOMAIN${NC}"
}

# Detect Plesk user
detect_plesk_user() {
    if [ -z "$PLESK_USER" ]; then
        # Get owner of document root
        if [ -d "$OPENCART_ROOT" ]; then
            PLESK_USER=$(stat -c '%U' "$OPENCART_ROOT" 2>/dev/null || echo "")
        fi
    fi
    
    if [ -z "$PLESK_USER" ]; then
        echo -e "${YELLOW}Could not auto-detect Plesk user.${NC}"
        read -p "Enter Plesk system user: " PLESK_USER
    fi
    
    echo -e "${CYAN}Plesk User: $PLESK_USER${NC}"
}

# Detect database credentials from config.php
detect_database() {
    local config_file="$OPENCART_ROOT/config.php"
    
    if [ -f "$config_file" ]; then
        if [ -z "$DB_NAME" ]; then
            DB_NAME=$(grep "define('DB_DATABASE'" "$config_file" | cut -d"'" -f4)
        fi
        if [ -z "$DB_USER" ]; then
            DB_USER=$(grep "define('DB_USERNAME'" "$config_file" | cut -d"'" -f4)
        fi
        if [ -z "$DB_PASS" ]; then
            DB_PASS=$(grep "define('DB_PASSWORD'" "$config_file" | cut -d"'" -f4)
        fi
    fi
    
    # Prompt for missing values
    if [ -z "$DB_NAME" ]; then
        read -p "Enter database name: " DB_NAME
    fi
    if [ -z "$DB_USER" ]; then
        read -p "Enter database user: " DB_USER
    fi
    if [ -z "$DB_PASS" ]; then
        read -s -p "Enter database password: " DB_PASS
        echo ""
    fi
    
    echo -e "${CYAN}Database: $DB_NAME${NC}"
    echo -e "${CYAN}DB User: $DB_USER${NC}"
}

# Check if running as root or with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This installer must be run as root or with sudo.${NC}"
        echo -e "${YELLOW}Please run: sudo $0${NC}"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
    local errors=0
    
    # Check PHP
    if command -v php &> /dev/null; then
        PHP_VERSION=$(php -v | head -n 1 | cut -d' ' -f2 | cut -d'.' -f1,2)
        echo -e "  ${GREEN}✓${NC} PHP $PHP_VERSION"
    else
        echo -e "  ${RED}✗${NC} PHP not found"
        errors=$((errors + 1))
    fi
    
    # Check MySQL
    if command -v mysql &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} MySQL client"
    else
        echo -e "  ${RED}✗${NC} MySQL client not found"
        errors=$((errors + 1))
    fi
    
    # Check OpenCart
    if [ -f "$OPENCART_ROOT/config.php" ]; then
        echo -e "  ${GREEN}✓${NC} OpenCart found"
    else
        echo -e "  ${RED}✗${NC} OpenCart not found at $OPENCART_ROOT"
        errors=$((errors + 1))
    fi
    
    # Check write permissions
    if [ -w "$OPENCART_ROOT" ]; then
        echo -e "  ${GREEN}✓${NC} Write permissions"
    else
        echo -e "  ${RED}✗${NC} No write permissions to $OPENCART_ROOT"
        errors=$((errors + 1))
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "${RED}Requirements check failed. Please fix the issues above.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All requirements met!${NC}"
}

# Backup database
backup_database() {
    echo -e "${YELLOW}Creating database backup...${NC}"
    
    local backup_dir="$OPENCART_ROOT/backups"
    local backup_file="$backup_dir/bundle_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    mkdir -p "$backup_dir"
    
    if mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$backup_file" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Backup created: $backup_file"
    else
        echo -e "  ${YELLOW}!${NC} Could not create backup (continuing anyway)"
    fi
}

# Install database tables
install_database() {
    echo -e "${YELLOW}Installing database tables...${NC}"
    
    local sql_file="$OPENCART_ROOT/install/bundle_install.sql"
    
    if [ ! -f "$sql_file" ]; then
        echo -e "${RED}SQL file not found: $sql_file${NC}"
        exit 1
    fi
    
    # Modify SQL to use correct prefix
    local prefix=$(grep "define('DB_PREFIX'" "$OPENCART_ROOT/config.php" | cut -d"'" -f4)
    if [ -z "$prefix" ]; then
        prefix="oc_"
    fi
    
    # Create temporary SQL file with correct prefix
    local temp_sql="/tmp/bundle_install_$(date +%s).sql"
    sed "s/oc_/${prefix}/g" "$sql_file" > "$temp_sql"
    
    if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$temp_sql" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Database tables installed"
    else
        echo -e "  ${RED}✗${NC} Failed to install database tables"
        rm -f "$temp_sql"
        exit 1
    fi
    
    rm -f "$temp_sql"
    
    # Insert default settings
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        INSERT INTO ${prefix}bundle_settings (\`key\`, value) VALUES
        ('api_url', 'http://${STRAPI_DOMAIN:-localhost:1337}/api'),
        ('api_enabled', '0'),
        ('cache_ttl', '3600'),
        ('show_on_product_page', '1'),
        ('default_title', 'Product Bundles')
        ON DUPLICATE KEY UPDATE value=VALUES(value);
    " 2>/dev/null
    
    echo -e "  ${GREEN}✓${NC} Default settings inserted"
}

# Update OpenCart config
update_config() {
    echo -e "${YELLOW}Updating OpenCart configuration...${NC}"
    
    local config_file="$OPENCART_ROOT/config.php"
    local admin_config_file="$OPENCART_ROOT/admin/config.php"
    local strapi_url="http://${STRAPI_DOMAIN:-localhost:1337}/api"
    
    # Update main config
    if [ -f "$config_file" ]; then
        if ! grep -q "STRAPI_API_URL" "$config_file"; then
            echo "" >> "$config_file"
            echo "// Bundle Manager - Strapi API Integration" >> "$config_file"
            echo "define('STRAPI_API_URL', '$strapi_url');" >> "$config_file"
            echo -e "  ${GREEN}✓${NC} Updated $config_file"
        else
            echo -e "  ${CYAN}→${NC} STRAPI_API_URL already exists in $config_file"
        fi
    fi
    
    # Update admin config
    if [ -f "$admin_config_file" ]; then
        if ! grep -q "STRAPI_API_URL" "$admin_config_file"; then
            echo "" >> "$admin_config_file"
            echo "// Bundle Manager - Strapi API Integration" >> "$admin_config_file"
            echo "define('STRAPI_API_URL', '$strapi_url');" >> "$admin_config_file"
            echo -e "  ${GREEN}✓${NC} Updated $admin_config_file"
        else
            echo -e "  ${CYAN}→${NC} STRAPI_API_URL already exists in $admin_config_file"
        fi
    fi
}

# Fix Plesk permissions
fix_permissions() {
    echo -e "${YELLOW}Fixing file permissions for Plesk...${NC}"
    
    # Find the Plesk user group
    local plesk_group="psacln"
    
    # Set ownership
    chown -R "$PLESK_USER:$plesk_group" "$OPENCART_ROOT/catalog/controller/module/" 2>/dev/null || true
    chown -R "$PLESK_USER:$plesk_group" "$OPENCART_ROOT/catalog/model/module/" 2>/dev/null || true
    chown -R "$PLESK_USER:$plesk_group" "$OPENCART_ROOT/catalog/view/theme/default/template/module/" 2>/dev/null || true
    chown -R "$PLESK_USER:$plesk_group" "$OPENCART_ROOT/admin/controller/module/" 2>/dev/null || true
    chown -R "$PLESK_USER:$plesk_group" "$OPENCART_ROOT/admin/model/module/" 2>/dev/null || true
    chown -R "$PLESK_USER:$plesk_group" "$OPENCART_ROOT/admin/view/module/" 2>/dev/null || true
    
    # Set permissions
    find "$OPENCART_ROOT/catalog/controller/module/" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find "$OPENCART_ROOT/catalog/model/module/" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find "$OPENCART_ROOT/catalog/view/theme/default/template/module/" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find "$OPENCART_ROOT/admin/controller/module/" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find "$OPENCART_ROOT/admin/model/module/" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find "$OPENCART_ROOT/admin/view/module/" -type f -exec chmod 644 {} \; 2>/dev/null || true
    
    echo -e "  ${GREEN}✓${NC} Permissions fixed"
}

# Create module settings in OpenCart
install_module() {
    echo -e "${YELLOW}Installing OpenCart module...${NC}"
    
    # Add module to extensions
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        INSERT INTO ${prefix}extension (type, code) 
        VALUES ('module', 'bundle_manager') 
        ON DUPLICATE KEY UPDATE code=code;
    " 2>/dev/null || true
    
    # Add settings
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        INSERT INTO ${prefix}setting (store_id, code, key, value, serialized) 
        VALUES (0, 'bundle_manager', 'bundle_manager_status', '1', 0)
        ON DUPLICATE KEY UPDATE value='1';
    " 2>/dev/null || true
    
    echo -e "  ${GREEN}✓${NC} Module registered"
}

# Create sample bundles
create_samples() {
    if [ "$AUTO_YES" = true ]; then
        return 0
    fi
    
    echo ""
    read -p "Create sample bundles? (y/N): " create_samples
    
    if [[ $create_samples =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Creating sample bundles...${NC}"
        
        local prefix=$(grep "define('DB_PREFIX'" "$OPENCART_ROOT/config.php" | cut -d"'" -f4)
        
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
            INSERT INTO ${prefix}bundles (name, slug, description, short_description, original_price, bundle_price, discount_percent, products, stock, sku, status, sort_order, date_added, date_modified) VALUES
            ('Gaming PC Bundle - Entry Level', 'gaming-pc-bundle-entry', '<p>Complete gaming PC bundle with everything you need.</p>', 'Intel i5, RTX 3050, 16GB RAM, 1TB SSD', 950.00, 899.00, 5.37, '[{\"productId\":\"1\",\"name\":\"Intel Core i5-12400F\",\"price\":250.00,\"quantity\":1},{\"productId\":\"2\",\"name\":\"ASUS RTX 3050 8GB\",\"price\":320.00,\"quantity\":1},{\"productId\":\"3\",\"name\":\"Corsair 16GB DDR4\",\"price\":80.00,\"quantity\":2}]', 10, 'BUNDLE-GAMING-001', 1, 1, NOW(), NOW()),
            ('Pro Workstation Bundle', 'pro-workstation-bundle', '<p>Professional workstation for creators.</p>', 'AMD Ryzen 9, RTX 4070, 64GB RAM, 2TB SSD', 2850.00, 2699.00, 5.30, '[{\"productId\":\"5\",\"name\":\"AMD Ryzen 9 7950X\",\"price\":550.00,\"quantity\":1},{\"productId\":\"6\",\"name\":\"NVIDIA RTX 4070 Ti\",\"price\":800.00,\"quantity\":1},{\"productId\":\"7\",\"name\":\"G.SKILL 64GB DDR5\",\"price\":300.00,\"quantity\":2}]', 5, 'BUNDLE-PRO-001', 1, 2, NOW(), NOW())
            ON DUPLICATE KEY UPDATE name=VALUES(name);
        " 2>/dev/null
        
        echo -e "  ${GREEN}✓${NC} Sample bundles created"
    fi
}

# Verify installation
verify_installation() {
    echo -e "${YELLOW}Verifying installation...${NC}"
    
    local errors=0
    local prefix=$(grep "define('DB_PREFIX'" "$OPENCART_ROOT/config.php" | cut -d"'" -f4)
    
    # Check tables
    if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT 1 FROM ${prefix}bundles LIMIT 1" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Bundle table exists"
    else
        echo -e "  ${RED}✗${NC} Bundle table missing"
        errors=$((errors + 1))
    fi
    
    # Check controller files
    if [ -f "$OPENCART_ROOT/catalog/controller/module/bundle.php" ]; then
        echo -e "  ${GREEN}✓${NC} Frontend controller"
    else
        echo -e "  ${RED}✗${NC} Frontend controller missing"
        errors=$((errors + 1))
    fi
    
    if [ -f "$OPENCART_ROOT/admin/controller/module/bundle_manager.php" ]; then
        echo -e "  ${GREEN}✓${NC} Admin controller"
    else
        echo -e "  ${RED}✗${NC} Admin controller missing"
        errors=$((errors + 1))
    fi
    
    # Check config
    if grep -q "STRAPI_API_URL" "$OPENCART_ROOT/config.php"; then
        echo -e "  ${GREEN}✓${NC} Config updated"
    else
        echo -e "  ${RED}✗${NC} Config not updated"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Create installation log
create_log() {
    local log_file="$OPENCART_ROOT/install/install.log"
    local prefix=$(grep "define('DB_PREFIX'" "$OPENCART_ROOT/config.php" | cut -d"'" -f4)
    
    cat > "$log_file" << EOF
OpenCart Bundle System Installation Log
========================================
Date: $(date)
Domain: $DOMAIN
Plesk User: $PLESK_USER
Database: $DB_NAME
Table Prefix: $prefix
Strapi Domain: ${STRAPI_DOMAIN:-Not configured}
Installation Status: SUCCESS

Files Installed:
- catalog/controller/module/bundle.php
- catalog/model/module/bundle.php
- catalog/view/theme/default/template/module/bundle.tpl
- admin/controller/module/bundle_manager.php
- admin/model/module/bundle_manager.php
- admin/view/module/bundle_manager*.tpl

Database Tables:
- ${prefix}bundles
- ${prefix}bundle_products
- ${prefix}bundle_settings

Next Steps:
1. Go to OpenCart Admin
2. Extensions > Modules > Bundle Manager
3. Click Install if not already installed
4. Configure module settings
5. Create your first bundle
6. Add bundle module to layouts
EOF
    
    echo -e "  ${GREEN}✓${NC} Installation log created: install/install.log"
}

# Print success message
print_success() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BOLD}Your OpenCart Bundle System is ready!${NC}"
    echo ""
    echo -e "${CYAN}Domain:${NC} $DOMAIN"
    echo -e "${CYAN}OpenCart:${NC} https://$DOMAIN"
    echo -e "${CYAN}Admin:${NC} https://$DOMAIN/admin"
    if [ -n "$STRAPI_DOMAIN" ]; then
        echo -e "${CYAN}Strapi:${NC} https://$STRAPI_DOMAIN"
    fi
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Go to OpenCart Admin"
    echo "  2. Extensions > Modules > Bundle Manager"
    echo "  3. Install the module (if not auto-installed)"
    echo "  4. Configure settings"
    echo "  5. Create bundles"
    echo "  6. Add to layouts: Design > Layouts"
    echo ""
    echo -e "${YELLOW}Documentation:${NC}"
    echo "  - docs/TUTORIAL.md"
    echo "  - docs/API.md"
    echo "  - docs/PLESK.md"
    echo ""
    echo -e "${YELLOW}Support:${NC}"
    echo "  Check GitHub issues or OpenCart forums"
    echo ""
}

# Main installation flow
main() {
    print_header
    
    # Pre-installation checks
    check_sudo
    check_requirements
    
    # Auto-detect settings
    detect_domain
    detect_plesk_user
    detect_database
    
    # Confirmation
    if [ "$AUTO_YES" = false ]; then
        echo ""
        read -p "Continue with installation? (Y/n): " confirm
        if [[ $confirm =~ ^[Nn]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
    
    echo ""
    echo -e "${BLUE}Starting installation...${NC}"
    echo ""
    
    # Backup first
    backup_database
    
    # Install
    install_database
    update_config
    install_module
    
    # Fix permissions if requested
    if [ "$FIX_PERMISSIONS" = true ] || [ "$AUTO_YES" = true ]; then
        fix_permissions
    fi
    
    # Create samples
    create_samples
    
    # Verify
    echo ""
    if verify_installation; then
        create_log
        print_success
    else
        echo -e "${RED}Installation completed with errors. Check the output above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"