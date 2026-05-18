# 🎓 OpenCart Bundle System - Complete Tutorial

<div align="center">

<img src="../assets/logo-maven-music.svg" alt="Maven Music Network - OpenCart Bundle System" width="500">

**A Comprehensive Guide to Product Bundles in OpenCart 3.x**

</div>

---

## 📚 Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Creating Your First Bundle](#creating-your-first-bundle)
5. [Managing Bundles](#managing-bundles)
6. [Frontend Display](#frontend-display)
7. [Strapi Integration](#strapi-integration)
8. [Advanced Configuration](#advanced-configuration)
9. [API Reference](#api-reference)
10. [Troubleshooting](#troubleshooting)
11. [Best Practices](#best-practices)

---

## Introduction

The **OpenCart Bundle System** allows you to create product bundles where customers can purchase multiple related products together at a discounted price. Inspired by premium e-commerce platforms like [sigma-computer.com](https://www.sigma-computer.com), this system provides a luxurious shopping experience with dark theme and gold accents.

### What You'll Learn

✅ Install the bundle system on your OpenCart store  
✅ Create professional product bundles  
✅ Configure frontend display on product pages  
✅ Set up optional Strapi CMS integration  
✅ Manage bundles through the admin panel  
✅ Customize pricing and discounts  

---

## Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OpenCart** | 3.0.3.2 | 3.0.3.2+ |
| **PHP** | 7.4 | 8.0+ |
| **MySQL** | 5.7 | 8.0+ |
| **Node.js** | 18.0 | 20+ (for Strapi) |
| **RAM** | 2GB | 4GB+ |

### Required PHP Extensions

```bash
php -m | grep -E "mysqli|json|curl|mbstring|gd|openssl|zlib"
```

All of these should be enabled:
- `mysqli` - MySQL database connection
- `json` - JSON data handling
- `curl` - API requests to Strapi
- `mbstring` - Multibyte string functions
- `gd` - Image processing
- `openssl` - Encryption
- `zlib` - Compression

### Plesk-Specific Requirements

If using Plesk hosting:
- Plesk Obsidian 18.0 or newer
- SSH access enabled
- Root or sudo privileges (for installer)

---

## Installation

### Method 1: Automated Plesk Installer (Recommended)

The fastest way to install on Plesk servers:

```bash
# Navigate to your OpenCart root
cd /var/www/vhosts/yourdomain.com/httpdocs

# Download and run installer
curl -sSL https://raw.githubusercontent.com/yourusername/OpenCart3-StrapiCMSAPI/main/install/plesk-install.sh -o install.sh
chmod +x install.sh
sudo ./install.sh --domain=yourdomain.com --yes
```

**What the installer does:**

1. 🔍 **System Check** - Verifies PHP, MySQL, and OpenCart
2. 💾 **Database Backup** - Creates backup before making changes
3. 🗄️ **Create Tables** - Creates `oc_bundles`, `oc_bundle_products`, `oc_bundle_settings`
4. 📁 **Copy Files** - Installs all module files to correct directories
5. ⚙️ **Update Config** - Adds STRAPI_API_URL to config.php
6. 🔐 **Fix Permissions** - Sets proper Plesk user:group ownership
7. ✅ **Verify** - Confirms everything is working

### Method 2: Plesk Git Deployment (With Strapi CMS)

Deploy **both** OpenCart module AND Strapi CMS using Plesk Git:

#### Option A: OpenCart Module Only

**Step 1:** In Plesk, go to **Git → Add Repository**

**Step 2:** Enter:
```
Repository URL: https://github.com/yourusername/OpenCart3-StrapiCMSAPI.git
Branch: main
```

**Step 3:** Set deploy path to your OpenCart root:
```
/var/www/vhosts/yourdomain.com/httpdocs/
```

**Step 4:** Click **Deploy**

**Step 5:** Run post-deploy script:
```bash
sudo bash .plesk/post-deploy
```

✅ **Done!** The bundle system is now installed.

---

#### Option B: OpenCart + Strapi CMS (Full Setup)

**Deploy OpenCart Module (Main Domain):**

1. In Plesk Git, add repository:
```
Repository URL: https://github.com/yourusername/OpenCart3-StrapiCMSAPI.git
Branch: main
Path: /var/www/vhosts/yourdomain.com/httpdocs/
```

2. After deploy, run:
```bash
cd /var/www/vhosts/yourdomain.com/httpdocs
sudo bash .plesk/post-deploy
```

**Deploy Strapi API (Subdomain):**

3. Create subdomain in Plesk: **Subdomains → Add Subdomain**
   - Name: `api` (creates api.yourdomain.com)

4. In Plesk Git, add second repository:
```
Repository URL: https://github.com/yourusername/OpenCart3-StrapiCMSAPI.git
Branch: main
Path: /var/www/vhosts/yourdomain.com/api/
```

5. Setup Strapi:
```bash
cd /var/www/vhosts/yourdomain.com/api/strapi-api
npm install
npm run build
npm start
```

6. Access Strapi Admin:
```
https://api.yourdomain.com/admin
```

✅ **Done!** You now have:
- OpenCart bundles at: `https://yourdomain.com`
- Strapi admin at: `https://api.yourdomain.com/admin`

---

### Method 3: Manual Installation

#### Step 1: Create Database Tables

**Option 1: Using MySQL Command Line**

```bash
# Get credentials from OpenCart config
DB_NAME=$(grep "define('DB_DATABASE'" config.php | cut -d"'" -f4)
DB_USER=$(grep "define('DB_USERNAME'" config.php | cut -d"'" -f4)
DB_PASS=$(grep "define('DB_PASSWORD'" config.php | cut -d"'" -f4)

# Run SQL
mysql -u $DB_USER -p$DB_PASS $DB_NAME < install/bundle_install.sql
```

**Option 2: Using PHP Migration Script**

```bash
cd /path/to/opencart
php install/migrate.php
```

The migration script will:
- Detect your table prefix automatically
- Create tables with proper encoding (utf8mb4)
- Insert default settings
- Check Strapi connectivity
- Update config files

**Option 3: Using phpMyAdmin**

1. Login to Plesk → Databases → phpMyAdmin
2. Select your OpenCart database
3. Go to SQL tab
4. Copy contents of `install/bundle_install.sql`
5. Click **Go**

#### Step 2: Copy Module Files

```bash
# Catalog (frontend) files
cp -r catalog/controller/module/bundle.php /path/to/opencart/catalog/controller/module/
cp -r catalog/model/module/bundle.php /path/to/opencart/catalog/model/module/
cp -r catalog/view/theme/default/template/module/bundle.tpl /path/to/opencart/catalog/view/theme/default/template/module/
cp -r catalog/view/theme/default/template/extension/module/bundle_product.tpl /path/to/opencart/catalog/view/theme/default/template/extension/module/

# Admin files
cp -r admin/controller/module/bundle_manager.php /path/to/opencart/admin/controller/module/
cp -r admin/model/module/bundle_manager.php /path/to/opencart/admin/model/module/
cp -r admin/view/module/bundle_manager*.tpl /path/to/opencart/admin/view/module/

# Language files
cp -r catalog/language/en-gb/module/bundle.php /path/to/opencart/catalog/language/en-gb/module/
cp -r catalog/language/en-gb/extension/module/bundle_product.php /path/to/opencart/catalog/language/en-gb/extension/module/
cp -r admin/language/en-gb/module/bundle_manager.php /path/to/opencart/admin/language/en-gb/module/
```

#### Step 3: Update Configuration

Add to **both** `config.php` and `admin/config.php`:

```php
// Bundle Manager - Strapi API Integration (optional)
define('STRAPI_API_URL', 'http://localhost:1337/api');
```

#### Step 4: Install Module in OpenCart

1. Login to OpenCart Admin
2. Navigate to **Extensions > Extensions**
3. Select **Modules** from the dropdown
4. Find **Bundle Manager**
5. Click the green **Install** button
6. Click **Edit** to configure

---

## Creating Your First Bundle

### Step 1: Access Bundle Manager

1. Go to **Extensions > Modules > Bundle Manager**
2. Click **Manage Bundles**
3. Click **Add Bundle**

### Step 2: Fill General Information

**General Tab:**

| Field | Example Value |
|-------|--------------|
| **Bundle Name** | Gaming PC Bundle - Entry Level |
| **Description** | Complete gaming PC with everything you need to start gaming |
| **Short Description** | Intel i5, RTX 3050, 16GB RAM, 1TB SSD |
| **Image** | URL to bundle image |

### Step 3: Add Products

**Products Tab:**

Click **Add Product** for each item:

```
Product 1: Intel Core i5-12400F
  - Quantity: 1
  - Price Override: (leave empty to use product price)

Product 2: ASUS RTX 3050 8GB
  - Quantity: 1
  - Price Override: (leave empty)

Product 3: Corsair 16GB DDR4 3200MHz
  - Quantity: 2
  - Price Override: (leave empty)

Product 4: 1TB NVMe SSD
  - Quantity: 1
  - Price Override: (leave empty)
```

### Step 4: Set Pricing

**Data Tab:**

| Field | Value | Description |
|-------|-------|-------------|
| **Original Price** | $950.00 | Sum of all individual prices |
| **Bundle Price** | $899.00 | Your discounted price |
| **Discount %** | 5.37 | Auto-calculated or manual |
| **Stock** | 10 | Available bundle quantities |
| **SKU** | BUNDLE-GAMING-001 | Unique identifier |
| **Status** | Enabled | Active/Inactive |
| **Sort Order** | 1 | Display priority |

### Step 5: Save and Verify

Click **Save**. Your bundle is now live!

### Example Bundles

#### Example 1: Gaming PC Bundle
```yaml
Name: Gaming PC Bundle - Entry Level
Original Price: $950.00
Bundle Price: $899.00
Discount: 5.37%
Products:
  - CPU: Intel Core i5-12400F (1x) - $250.00
  - GPU: ASUS RTX 3050 8GB (1x) - $320.00
  - RAM: Corsair 16GB DDR4 (2x) - $80.00 each
  - Storage: 1TB NVMe SSD (1x) - $120.00
```

#### Example 2: Pro Workstation
```yaml
Name: Pro Workstation Bundle
Original Price: $2850.00
Bundle Price: $2699.00
Discount: 5.30%
Products:
  - CPU: AMD Ryzen 9 7950X (1x) - $550.00
  - GPU: NVIDIA RTX 4070 Ti (1x) - $800.00
  - RAM: G.SKILL 64GB DDR5 (2x) - $300.00 each
  - Storage: 2TB NVMe Gen4 SSD (1x) - $250.00
```

---

## Managing Bundles

### Editing Bundles

1. Go to **Extensions > Modules > Bundle Manager > Manage Bundles**
2. Find the bundle you want to edit
3. Click the **Edit** (pencil) icon
4. Make your changes
5. Click **Save**

### Deleting Bundles

1. In the bundle list, check the checkbox next to the bundle
2. Click the **Delete** (trash) button
3. Confirm deletion

### Bulk Operations

**Enable/Disable Multiple Bundles:**
1. Check multiple bundles
2. Edit each one and change Status

**Reorder Bundles:**
1. Edit bundle
2. Change **Sort Order** value
3. Lower numbers display first

### Search and Filter

The bundle list supports:
- **Search by name** - Type in the search box
- **Filter by status** - Enabled/Disabled
- **Sort by date** - Newest first

---

## Frontend Display

### Product Page Bundle Display

When a customer views a product that's part of a bundle:

**What they see:**
1. 🏷️ **Bundle name** with gold gradient styling
2. 💰 **Discount badge** showing savings percentage
3. 📦 **Product list** with all items in the bundle
4. ⭐ **Current product** highlighted with gold border
5. 💵 **Pricing panel** showing:
   - Original total price (strikethrough)
   - Bundle price (large, gold)
   - Savings amount
6. 🛒 **Add Bundle to Cart** button (gold gradient)

**Customer actions:**
- Click "Add Complete Bundle to Cart" to add all products at once
- View individual product prices
- See exactly what they're saving

### Bundle Listing Page

Access via module on homepage or dedicated page.

**Grid layout showing:**
- Bundle image with discount badge
- Bundle name and short description
- Original vs bundle price
- "Add to Cart" button
- Stock availability

### Customizing Display

**Edit template file:**
```php
// catalog/view/theme/default/template/module/bundle.tpl
// catalog/view/theme/default/template/extension/module/bundle_product.tpl
```

**Available CSS classes:**
```css
.bundle-product-section     /* Main container */
.bundle-product-card        /* Individual bundle card */
.bundle-discount-badge      /* Discount percentage badge */
.bundle-product-name        /* Bundle title */
.bundle-products-list       /* Products table */
.bundle-pricing-panel       /* Pricing section */
.bundle-add-btn            /* Add to cart button */
```

---

## Strapi Integration

### Why Use Strapi?

Strapi provides a modern CMS for managing bundles:

- 🎨 **Rich text editor** for descriptions
- 🖼️ **Media library** for bundle images
- 👥 **Role-based access** control
- 🌍 **Multi-language** support
- 📊 **Version history** tracking

### Setup Strapi

#### Step 1: Install Dependencies

```bash
cd strapi/
npm install
```

#### Step 2: Configure Environment

Create `.env` file:
```env
# Server
HOST=0.0.0.0
PORT=1337

# Database
DATABASE_CLIENT=mysql
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_NAME=strapi_db
DATABASE_USERNAME=your_user
DATABASE_PASSWORD=your_password

# Security
APP_KEYS=your_key1,your_key2,your_key3,your_key4
API_TOKEN_SALT=your_salt
ADMIN_JWT_SECRET=your_secret
TRANSFER_TOKEN_SALT=your_transfer_salt
```

#### Step 3: Build and Start

```bash
# Build admin panel
npm run build

# Start server
npm start

# Access admin
# http://localhost:1337/admin
```

#### Step 4: Create First Admin User

1. Go to `http://localhost:1337/admin`
2. Create your admin account
3. The Bundle content type is pre-configured

### Managing Bundles in Strapi

1. Login to Strapi Admin
2. Go to **Content Manager > Bundles**
3. Click **Create new entry**
4. Fill in all fields
5. Click **Publish**

### Sync Configuration

**OpenCart to Strapi:**
```bash
php install/bundle_sync.php --direction=to-strapi
```

**Strapi to OpenCart:**
```bash
php install/bundle_sync.php --direction=to-opencart
```

**Auto-sync via Cron:**
```bash
# Add to crontab
0 3 * * * /usr/bin/php /path/to/opencart/install/bundle_sync.php
```

---

## Advanced Configuration

### Custom Table Prefix

If using custom prefix (not `oc_`):

```bash
# Edit SQL before running
sed 's/oc_/yourprefix_/g' install/bundle_install.sql > custom_install.sql
mysql -u user -p database < custom_install.sql
```

### Multi-Store Setup

For multiple OpenCart stores:

```php
// Different Strapi URLs per store
if ($_SERVER['HTTP_HOST'] == 'store1.com') {
    define('STRAPI_API_URL', 'http://strapi1.example.com/api');
} else {
    define('STRAPI_API_URL', 'http://strapi2.example.com/api');
}
```

### Custom Cache Settings

Edit `system/config/bundle.php`:
```php
$_['bundle_manager_cache_ttl'] = 7200;  // 2 hours
$_['bundle_manager_cache_type'] = 'file';  // file, memcached, redis
```

### API Timeout Configuration

```php
$_['bundle_manager_api_timeout'] = 10;  // seconds
```

---

## API Reference

### OpenCart Module API

#### Get Bundles
```php
$this->load->model('module/bundle');

// Get all active bundles (limit 10)
$bundles = $this->model_module_bundle->getBundles(10, 0);

// Get by category
$bundles = $this->model_module_bundle->getBundles(10, $category_id);
```

#### Get Bundle by ID
```php
$bundle = $this->model_module_bundle->getBundleById(1);

// Returns:
// [
//     'id' => 1,
//     'name' => 'Gaming PC Bundle',
//     'slug' => 'gaming-pc-bundle',
//     'original_price' => 950.00,
//     'bundle_price' => 899.00,
//     'products' => [...]
// ]
```

#### Get Bundles by Product
```php
$bundles = $this->model_module_bundle->getBundlesByProduct(42);
```

#### Get Bundle Products
```php
$product_ids = [1, 2, 3, 4];
$products = $this->model_module_bundle->getProducts($product_ids);
```

### Strapi REST API

#### Authentication

All API endpoints are public (no authentication required by default).

#### Endpoints

**List All Bundles**
```bash
GET http://localhost:1337/api/bundles

# Query parameters
?pagination[limit]=10
&filters[isActive][$eq]=true
&sort=sortOrder:asc
```

**Get Bundle by ID**
```bash
GET http://localhost:1337/api/bundles/1
```

**Get Bundle by Slug**
```bash
GET http://localhost:1337/api/bundles/by-slug/gaming-pc-bundle
```

**Get Bundles by Product**
```bash
GET http://localhost:1337/api/bundles/by-product/42
```

**Sync Bundles**
```bash
POST http://localhost:1337/api/bundles/sync
Content-Type: application/json

{
  "bundles": [
    {
      "name": "Gaming PC Bundle",
      "slug": "gaming-pc-bundle",
      "originalPrice": 950.00,
      "bundlePrice": 899.00,
      "products": [...]
    }
  ]
}
```

**Calculate Price**
```bash
GET http://localhost:1337/api/bundles/1/calculate

# Response:
{
  "originalPrice": 950.00,
  "bundlePrice": 899.00,
  "discountPercent": 5.37,
  "savings": 51.00
}
```

---

## Troubleshooting

### Common Issues

#### ❌ "Bundle Manager not found in Extensions"

**Solution:**
1. Clear modification cache:
   ```bash
   rm -rf /path/to/opencart/system/storage/modification/*
   ```
2. Go to **Extensions > Modifications > Refresh**
3. Logout and login again

#### ❌ "Database table not found"

**Solution:**
```bash
# Re-run migration
php install/migrate.php

# Or manually create tables
mysql -u user -p database < install/bundle_install.sql
```

#### ❌ "Permission denied" (Plesk)

**Solution:**
```bash
# Fix ownership
chown -R youruser:psacln /var/www/vhosts/yourdomain.com/httpdocs/catalog/controller/module/
chown -R youruser:psacln /var/www/vhosts/yourdomain.com/httpdocs/admin/controller/module/

# Fix permissions
chmod -R 755 /var/www/vhosts/yourdomain.com/httpdocs/catalog/
chmod -R 755 /var/www/vhosts/yourdomain.com/httpdocs/admin/
```

#### ❌ "Strapi API not connecting"

**Solution:**
1. Check if Strapi is running:
   ```bash
   curl http://localhost:1337
   ```
2. Verify firewall isn't blocking port 1337
3. Check `STRAPI_API_URL` in config.php
4. Disable API in module settings (use local DB)

#### ❌ "Bundles not showing on product page"

**Solution:**
1. Check module is installed and enabled
2. Verify product is in a bundle
3. Check layout assignment:
   - **Design > Layouts > Product**
   - Ensure "Bundle Product" module is in Content Bottom
4. Clear OpenCart cache

#### ❌ "Add to cart not working"

**Solution:**
1. Check browser console for JavaScript errors
2. Ensure jQuery is loaded
3. Verify cart controller exists:
   ```
   catalog/controller/checkout/cart_bundle.php
   ```
4. Check products have stock available

### Debug Mode

Enable debug logging:

```php
// Edit system/config/catalog.php
$_['error_display'] = true;
```

Check logs:
```bash
# OpenCart logs
tail -f /path/to/opencart/system/storage/logs/error.log

# Strapi logs
tail -f /tmp/strapi.log
```

---

## Best Practices

### ✅ DO

- **Use high-quality images** for bundles (recommended: 400x300px)
- **Write clear descriptions** explaining what's included
- **Set realistic discounts** (5-15% is typical)
- **Monitor stock levels** to prevent overselling
- **Test bundles** before making them live
- **Use SEO-friendly slugs** (e.g., `gaming-pc-bundle`)
- **Keep bundles updated** with current product prices

### ❌ DON'T

- **Don't create too many bundles** - Focus on your best combinations
- **Don't set discounts too high** - Maintain profitability
- **Don't include out-of-stock products** - Check inventory first
- **Don't use generic names** - Be specific (e.g., "Gaming PC Bundle - Entry Level")
- **Don't forget to test** on mobile devices

### 📊 Performance Tips

1. **Enable caching** - Set cache TTL to 3600 seconds or higher
2. **Optimize images** - Compress bundle images before upload
3. **Limit bundles per page** - Show 6-12 bundles at a time
4. **Use a CDN** for bundle images
5. **Enable gzip compression** on your server

### 🎨 Design Tips

1. **Consistent branding** - Use your store's colors
2. **Clear hierarchy** - Bundle name → Products → Price → CTA
3. **Highlight savings** - Make the discount percentage prominent
4. **Use action words** - "Add Complete Bundle" vs "Add to Cart"
5. **Mobile-friendly** - Test on various screen sizes

---

<div align="center">

## 🎉 You're All Set!

Your OpenCart Bundle System is now ready to create amazing product bundles.

**Need help?** Check the [Plesk Guide](PLESK.md) or [Strapi Setup](STRAPI.md)

**Found a bug?** [Create an issue](https://github.com/yourusername/OpenCart3-StrapiCMSAPI/issues)

---

<p style="color: #888;">Made with ❤️ by <strong style="color: #d3b65f;">Maven Music Network</strong></p>

</div>