<div align="center">

<!-- Logo -->
<img src="assets/logo.svg" alt="OpenCart Bundle System" width="700">

<!-- Badges -->
[![OpenCart](https://img.shields.io/badge/OpenCart-3.0.3.2+-1a1a1a?style=for-the-badge&logo=opencart&logoColor=d3b65f&labelColor=0a0a0a)](https://opencart.com)
[![PHP](https://img.shields.io/badge/PHP-7.4+-1a1a1a?style=for-the-badge&logo=php&logoColor=d3b65f&labelColor=0a0a0a)](https://php.net)
[![Strapi](https://img.shields.io/badge/Strapi-5.x-1a1a1a?style=for-the-badge&logo=strapi&logoColor=d3b65f&labelColor=0a0a0a)](https://strapi.io)
[![License](https://img.shields.io/badge/License-GPL--3.0-1a1a1a?style=for-the-badge&logo=gnu&logoColor=d3b65f&labelColor=0a0a0a)](LICENSE)

<p align="center">
  <strong style="color: #d3b65f;">A Premium Product Bundle System for OpenCart 3.x</strong><br>
  <span style="color: #888;">Create, manage, and sell product bundles with automatic discounts</span>
</p>

[📖 Documentation](#documentation) • [🚀 Quick Start](#quick-start) • [⚡ Installation](#installation) • [🔧 Configuration](#configuration) • [📸 Screenshots](#screenshots)

</div>

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 **Product Bundles**
Create unlimited bundles with multiple products, quantities, and custom pricing

### 💰 **Automatic Discounts**
Real-time savings calculation with percentage and fixed amount discounts

### 📱 **Responsive Design**
Mobile-first approach with elegant grid layouts

### 🚀 **One-Click Cart**
Add entire bundles to cart with a single click

</td>
<td width="50%">

### 🔗 **Strapi Integration**
Optional headless CMS for advanced content management

### ⚡ **High Performance**
Built-in caching system for optimal page load speeds

### 🎨 **Premium UI**
Dark theme with gold accents inspired by luxury e-commerce

### 🔒 **Plesk Ready**
Automated installer with permission fixes

</td>
</tr>
</table>

---

## 🚀 Quick Start

### Prerequisites

```bash
✓ OpenCart 3.0.3.2 or higher
✓ PHP 7.4+ (8.0+ recommended)
✓ MySQL 5.7+ / MariaDB 10.2+
✓ (Optional) Strapi 5.x + Node.js 18+
```

### One-Line Install (Plesk)

```bash
sudo curl -sSL https://raw.githubusercontent.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI/main/install/plesk-install.sh | bash
```

### Manual Install

```bash
# 1. Clone repository
git clone https://github.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI.git
cd OpenCart3-StrapiCMSAPI

# 2. Run migration
php install/migrate.php

# 3. Install module in OpenCart Admin
# Extensions > Modules > Bundle Manager > Install
```

---

## 📸 Screenshots

<div align="center">

<table>
<tr>
<td align="center">
<strong style="color: #d3b65f;">Product Page Bundle Display</strong><br>
<em>Show bundles containing the viewed product</em>
</td>
<td align="center">
<strong style="color: #d3b65f;">Bundle Listing Page</strong><br>
<em>Grid layout with pricing and discounts</em>
</td>
</tr>
<tr>
<td align="center">
<strong style="color: #d3b65f;">Admin Panel</strong><br>
<em>Full CRUD interface for bundle management</em>
</td>
<td align="center">
<strong style="color: #d3b65f;">Strapi CMS</strong><br>
<em>Headless CMS for advanced content editing</em>
</td>
</tr>
</table>

</div>

---

## 📖 Documentation

| Document | Description | Link |
|----------|-------------|------|
| 📘 **Full Tutorial** | Complete step-by-step guide | [TUTORIAL.md](docs/TUTORIAL.md) |
| 🖥️ **Plesk Guide** | Plesk-specific deployment | [PLESK.md](docs/PLESK.md) |
| 🔌 **Strapi Setup** | Strapi CMS integration | [STRAPI.md](docs/STRAPI.md) |
| 🔧 **API Reference** | REST API endpoints | [API.md](docs/API.md) |
| ⚙️ **Configuration** | Module settings & options | [CONFIG.md](docs/CONFIG.md) |

---

## ⚡ Installation

### Method 1: Plesk Auto-Installer ⭐ Recommended

```bash
chmod +x install/plesk-install.sh
sudo ./install/plesk-install.sh --domain=yourdomain.com --yes
```

**What it does:**
- ✅ Checks system requirements
- ✅ Creates database tables automatically
- ✅ Copies all module files
- ✅ Fixes Plesk permissions
- ✅ Updates configuration
- ✅ Creates sample bundles (optional)

### Method 2: Manual Installation

**Step 1:** Create database tables
```bash
mysql -u YOUR_DB_USER -p YOUR_DB < install/bundle_install.sql
```

**Step 2:** Copy module files
```bash
cp -r catalog/* /path/to/opencart/catalog/
cp -r admin/* /path/to/opencart/admin/
```

**Step 3:** Configure
```php
// Add to config.php and admin/config.php
define('STRAPI_API_URL', 'http://localhost:1337/api');
```

**Step 4:** Install module
Go to **OpenCart Admin > Extensions > Modules > Bundle Manager > Install**

---

## 🔧 Configuration

### Module Settings

Navigate to: **Extensions > Modules > Bundle Manager > Edit**

| Setting | Default | Description |
|---------|---------|-------------|
| **Status** | Enabled | Enable/disable module |
| **Module Title** | Product Bundles | Display title on frontend |
| **Show on Product Pages** | Yes | Display bundles on product pages |
| **Use Strapi API** | No | Enable Strapi integration |
| **Strapi API URL** | localhost:1337 | Your Strapi instance URL |
| **Cache Duration** | 3600 | Cache TTL in seconds |

### Adding to Layouts

**Product Page:**
```
Design > Layouts > Product > Content Bottom
→ Add Module: Bundle Product
```

**Category Page:**
```
Design > Layouts > Category > Content Bottom
→ Add Module: Bundle
```

**Home Page:**
```
Design > Layouts > Home > Content Bottom
→ Add Module: Bundle
```

---

## 🎯 Creating Bundles

### Example: Gaming PC Bundle

```yaml
Bundle Name: Gaming PC Bundle - Entry Level
Description: Complete gaming PC with everything you need
Original Price: $950.00
Bundle Price: $899.00
Discount: 5.37% (auto-calculated)
Stock: 10 units
SKU: BUNDLE-GAMING-001

Products:
  - Intel Core i5-12400F (Qty: 1) - $250.00
  - ASUS RTX 3050 8GB (Qty: 1) - $320.00
  - Corsair 16GB DDR4 (Qty: 2) - $80.00 each
  - 1TB NVMe SSD (Qty: 1) - $120.00
```

---

## 🔗 Strapi Integration

### Why Strapi?

Strapi provides a modern CMS interface for managing your bundles:

- 🎨 **Rich Text Editor** - WYSIWYG bundle descriptions
- 🖼️ **Media Library** - Drag & drop bundle images
- 👥 **Role-Based Access** - Editor, admin, super admin roles
- 🌍 **Internationalization** - Multi-language support
- 📊 **Content Versioning** - Track changes over time

### Quick Setup

```bash
cd strapi/
npm install
npm run build
npm start
# Access admin at http://localhost:1337/admin
```

Read the full [Strapi Setup Guide](docs/STRAPI.md) for detailed instructions.

---

## 🏗️ Architecture

```
OpenCart3-StrapiCMSAPI/
├── 📁 assets/              # Images, logos, branding
│   └── logo.svg           # Maven Music branded logo
│
├── 📁 catalog/             # Frontend module files
│   ├── controller/         # MVC Controllers
│   ├── model/              # Data models
│   ├── view/               # Templates
│   └── language/           # Translations
│
├── 📁 admin/               # Admin panel files
│   ├── controller/         # Admin controllers
│   ├── model/              # Admin models
│   ├── view/               # Admin templates
│   └── language/           # Admin translations
│
├── 📁 docs/                # Documentation
│   ├── TUTORIAL.md         # Complete guide
│   ├── PLESK.md            # Plesk deployment
│   ├── STRAPI.md           # Strapi setup
│   ├── API.md              # API reference
│   └── CONFIG.md           # Configuration guide
│
├── 📁 install/             # Installation scripts
│   ├── plesk-install.sh    # Plesk auto-installer
│   ├── migrate.php         # PHP migration
│   ├── bundle_install.sql  # Database schema
│   └── deploy.sh           # Universal deploy
│
└── 📄 README.md            # This file
```

---

## 🛠️ API Reference

### OpenCart Module API

```php
// Get all bundles
$bundles = $this->model_module_bundle->getBundles(10, 0);

// Get bundle by ID
$bundle = $this->model_module_bundle->getBundleById(1);

// Get bundles by product
$bundles = $this->model_module_bundle->getBundlesByProduct(42);
```

### Strapi REST API

```bash
# List all bundles
GET /api/bundles

# Get bundle by ID
GET /api/bundles/1

# Get bundles by product
GET /api/bundles/by-product/42

# Sync bundles
POST /api/bundles/sync
```

See [API.md](docs/API.md) for complete documentation.

---

## 🎨 Design Philosophy

This bundle system follows the **Maven Music Network** design principles:

> **Premium, Dark, Gold** - A luxurious e-commerce experience

- 🌑 **Dark backgrounds** (`#050505`, `#1a1a1a`) for reduced eye strain
- ✨ **Gold accents** (`#d3b65f`, `#f2df88`) for premium feel
- 📱 **Mobile-first** responsive design
- ⚡ **Performance optimized** with caching and lazy loading
- ♿ **Accessibility compliant** with proper contrast ratios

---

## 🤝 Contributing

We welcome contributions from the community!

```bash
# 1. Fork the repository
# 2. Create your feature branch
git checkout -b feature/AmazingFeature

# 3. Commit your changes
git commit -m 'Add some AmazingFeature'

# 4. Push to the branch
git push origin feature/AmazingFeature

# 5. Open a Pull Request
```

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/OpenCart3-StrapiCMSAPI.git
cd OpenCart3-StrapiCMSAPI

# Install dependencies
composer install  # For OpenCart
npm install       # For Strapi

# Run tests
php vendor/bin/phpunit
```

---

## 📜 License

```
OpenCart Bundle System
Copyright (C) 2026 Maven Music Network

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```

See [LICENSE](LICENSE) for full details.

---

## 🙏 Acknowledgments

- **Inspired by** [sigma-computer.com](https://www.sigma-computer.com) bundle functionality
- **Design by** [Maven Music Network](https://mavenmusic.network)
- **Powered by** [OpenCart](https://opencart.com) & [Strapi](https://strapi.io)
- **Icons by** [Lucide](https://lucide.dev)

---

<div align="center">

<p style="color: #888;">Made with ❤️ by <strong style="color: #d3b65f;">Maven Music Network</strong></p>

<p>
<a href="https://mavenmusic.network" style="color: #d3b65f;">Website</a> •
<a href="https://github.com/MavenMusicLLC" style="color: #d3b65f;">GitHub</a> •
<a href="mailto:info@mavenmusic.network" style="color: #d3b65f;">Contact</a>
</p>

<p style="color: #555; font-size: 12px;">
Version 1.0.0 • Compatible with OpenCart 3.0.3.2+
</p>

</div>