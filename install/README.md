# OpenCart + Strapi Bundle System

## Overview

A complete Product Bundle system for OpenCart 3.x with optional Strapi 5 CMS integration.
Inspired by sigma-computer.com's bundle functionality.

## Features

- Create product bundles with multiple products
- Automatic discount calculation
- Display bundles on product pages (like sigma-computer.com)
- Dedicated bundle listing page
- Add entire bundles to cart with one click
- Strapi CMS integration for advanced bundle management
- Full CRUD operations in OpenCart admin
- Fallback to local database if Strapi is unavailable
- Compatible with OpenCart 3.0.3.x

## Quick Start

### 1. Install Database Tables

```bash
cd /var/www/vhosts/noxhosting.cloud/oc.noxhosting.cloud
php install/migrate.php
```

### 2. Install OpenCart Module

1. Go to OpenCart Admin
2. Extensions > Extensions Installer
3. The module files are already in place
4. Extensions > Modules > Bundle Manager > Install

### 3. Configure Module

1. Go to Extensions > Modules > Bundle Manager > Edit
2. Enable the module
3. Configure API settings (optional - for Strapi integration)
4. Save settings

### 4. Create Bundles

1. Go to Extensions > Modules > Bundle Manager > Manage Bundles
2. Click "Add Bundle"
3. Fill in bundle details
4. Add products to the bundle
5. Save

### 5. Display Bundles

1. Go to Design > Layouts
2. Edit Product layout
3. Add "Bundle Product" module to content_bottom position
4. Save

## Strapi Integration (Optional)

### Setup Strapi

```bash
cd /var/www/vhosts/noxhosting.cloud/api-oc.noxhosting.cloud
npm install
npm run build
npm start
```

### Configure OpenCart for Strapi

Edit `config.php` and add:
```php
define('STRAPI_API_URL', 'http://localhost:1337/api');
```

### Strapi API Endpoints

- `GET /api/bundles` - List all bundles
- `GET /api/bundles/:id` - Get bundle by ID
- `GET /api/bundles/by-slug/:slug` - Get bundle by slug
- `GET /api/bundles/by-product/:productId` - Get bundles containing product
- `POST /api/bundles/sync` - Sync bundles from OpenCart

## File Structure

```
oc.noxhosting.cloud/
├── catalog/
│   ├── controller/
│   │   ├── module/
│   │   │   └── bundle.php
│   │   └── checkout/
│   │       └── cart_bundle.php
│   ├── model/
│   │   ├── module/
│   │   │   └── bundle.php
│   │   └── setting/
│   │       └── bundle_sync.php
│   ├── view/
│   │   └── theme/default/template/
│   │       ├── module/
│   │       │   └── bundle.tpl
│   │       └── extension/module/
│   │           └── bundle_product.tpl
│   └── language/
│       └── en-gb/
│           └── module/
│               └── bundle.php
├── admin/
│   ├── controller/
│   │   └── module/
│   │       └── bundle_manager.php
│   ├── model/
│   │   └── module/
│   │       └── bundle_manager.php
│   ├── view/
│   │   └── module/
│   │       ├── bundle_manager.tpl
│   │       ├── bundle_manager_list.tpl
│   │       └── bundle_manager_form.tpl
│   └── language/
│       └── en-gb/
│           └── module/
│               └── bundle_manager.php
├── install/
│   ├── bundle_install.sql
│   ├── migrate.php
│   ├── deploy.sh
│   └── bundle_sync.sh
└── config.php (updated with STRAPI_API_URL)

api-oc.noxhosting.cloud/
└── src/
    └── api/
        └── bundle/
            ├── content-types/
            │   └── bundle/
            │       └── schema.json
            ├── controllers/
            │   └── bundle.js
            ├── services/
            │   └── bundle.js
            └── routes/
                └── bundle.js
```

## Database Schema

### oc_bundles
- `bundle_id` - Primary key
- `name` - Bundle name
- `slug` - Unique URL slug
- `description` - HTML description
- `short_description` - Short text description
- `image` - Main image URL
- `images` - JSON array of additional images
- `original_price` - Total price if bought separately
- `bundle_price` - Discounted bundle price
- `discount_percent` - Discount percentage
- `products` - JSON array of products with quantities
- `categories` - JSON array of category IDs
- `stock` - Available quantity
- `sku` - Bundle SKU
- `status` - Active/Inactive
- `sort_order` - Display order
- `valid_from` / `valid_to` - Optional date range

## API Configuration

### Settings Table

The module stores configuration in `oc_bundle_settings`:

| Key | Default | Description |
|-----|---------|-------------|
| api_url | http://localhost:1337/api | Strapi API URL |
| api_enabled | 1 | Enable Strapi integration |
| cache_ttl | 3600 | Cache duration in seconds |
| show_on_product_page | 1 | Show bundles on product pages |
| default_title | Product Bundles | Default module title |

## Usage Examples

### Creating a Gaming PC Bundle

1. Name: "Gaming PC Bundle - Entry Level"
2. Products:
   - Intel Core i5-12400F (1x)
   - ASUS RTX 3050 8GB (1x)
   - Corsair 16GB DDR4 (2x)
   - 1TB NVMe SSD (1x)
3. Original Price: $950.00
4. Bundle Price: $899.00
5. Discount: 5.37%

### Displaying on Product Page

When a customer views a product that's part of a bundle:
- Bundle section appears below product details
- Shows all products in the bundle
- Highlights the current product
- Shows "Add Complete Bundle to Cart" button
- Displays savings amount

## Deployment

### Automated Deploy

```bash
cd /var/www/vhosts/noxhosting.cloud/oc.noxhosting.cloud/install
chmod +x deploy.sh
./deploy.sh
```

### Manual Steps

1. Run SQL: `mysql < install/bundle_install.sql`
2. Update config.php with `STRAPI_API_URL`
3. Copy module files to OpenCart directories
4. Install module in OpenCart admin
5. Configure layout positions

## Troubleshooting

### Bundles not showing on product page
- Check module is installed and enabled
- Verify product is added to a bundle
- Check layout assignment in Design > Layouts

### Strapi API not connecting
- Verify STRAPI_API_URL in config.php
- Check Strapi is running: `curl http://localhost:1337`
- Ensure CORS is configured in Strapi
- Disable API in settings to use local database only

### Database errors
- Run migration again: `php install/migrate.php`
- Check table prefix matches config
- Verify MySQL user has CREATE TABLE permissions

## Compatibility

- OpenCart 3.0.3.2+
- PHP 7.4+
- MySQL 5.7+ / MariaDB 10.2+
- Strapi 5.x (optional)
- Node.js 18+ (for Strapi)

## Support

For issues or questions, refer to:
- OpenCart documentation
- Strapi documentation
- System logs in `/system/storage/logs/`

## License

This module follows OpenCart's license terms.