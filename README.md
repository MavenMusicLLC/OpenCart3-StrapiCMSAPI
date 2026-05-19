<div align="center">

<img src="assets/logo.svg" alt="OpenCart Bundle System — Maven Music Network" width="800">

<br><br>

[![OpenCart](https://img.shields.io/badge/OpenCart-3.0.3.2+-0a0a0a?style=for-the-badge&logo=opencart&logoColor=d3b65f&labelColor=0a0a0a)](https://opencart.com)
[![PHP](https://img.shields.io/badge/PHP-7.4%2B-0a0a0a?style=for-the-badge&logo=php&logoColor=d3b65f&labelColor=0a0a0a)](https://php.net)
[![Strapi](https://img.shields.io/badge/Strapi-5.x-0a0a0a?style=for-the-badge&logo=strapi&logoColor=d3b65f&labelColor=0a0a0a)](https://strapi.io)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-0a0a0a?style=for-the-badge&logo=nodedotjs&logoColor=d3b65f&labelColor=0a0a0a)](https://nodejs.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-0a0a0a?style=for-the-badge&logo=mysql&logoColor=d3b65f&labelColor=0a0a0a)](https://mysql.com)
[![License](https://img.shields.io/badge/License-GPL--3.0-0a0a0a?style=for-the-badge&logo=gnu&logoColor=d3b65f&labelColor=0a0a0a)](LICENSE)

**A premium product bundle system for OpenCart 3.x, powered by a Strapi v5 headless CMS.**  
Create fixed, dynamic, tiered, and mix-and-match bundles — managed centrally and delivered via REST + GraphQL.

[Quick Start](#-quick-start) · [Architecture](#-architecture) · [API Reference](#-api-reference) · [Troubleshooting](#-troubleshooting)

</div>

---

## 📐 Architecture

This project uses **two Git branches** deploying to **two separate domains** via Plesk Git:

```
                         ┌─────────────────────────┐
                         │      GitHub Repo         │
                         │  MavenMusicLLC/          │
                         │  OpenCart3-StrapiCMSAPI  │
                         └────────┬────────┬────────┘
                                  │        │
                    branch: main  │        │  branch: strapi-api
                                  ▼        ▼
               ┌──────────────────┐      ┌──────────────────────┐
               │  oc.domain.com   │      │  oc-api.domain.com   │
               │  OpenCart Store  │ ───► │  Strapi CMS API      │
               │  + Bundle Module │ REST │  Port 1337           │
               └──────────────────┘      └──────────┬───────────┘
                                                     │
                                              ┌──────▼──────┐
                                              │   MySQL DB   │
                                              └─────────────┘
```

| Branch | Domain | Purpose | Deploy Script |
|--------|--------|---------|---------------|
| `main` | `oc.yourdomain.com` | OpenCart store + Bundle Module | `.plesk/post-deploy-opencart` |
| `strapi-api` | `oc-api.yourdomain.com` | Strapi CMS REST + GraphQL API | `.plesk/post-deploy-strapi` |

---

## ⚡ Quick Start

### Prerequisites

| Requirement | Minimum | Notes |
|-------------|---------|-------|
| OpenCart | 3.0.3.2+ | Already installed on your domain |
| PHP | 7.4+ | With `mysqli`, `curl`, `json`, `mbstring` |
| Node.js | 18+ | Install via Plesk Node.js extension |
| MySQL | 8.0+ | Or MariaDB 10.5+ |
| Plesk | Obsidian 18+ | With Git and Node.js extensions |

---

## 🚀 Plesk Git Deployment

> **Important:** Each domain must be **completely empty** (no files, no `.git` folder) before adding a Git repository in Plesk. If your `httpdocs/` folder has existing files, remove them first.

### Step 1 — Deploy OpenCart Bundle Module

In Plesk, go to **Websites & Domains** → `oc.yourdomain.com` → **Git** → **Add Repository**:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI.git` |
| Branch | `main` |
| Deploy path | `/var/www/vhosts/oc.yourdomain.com/httpdocs/` |
| Deployment action | `bash .plesk/post-deploy-opencart` |

Click **Deploy**.

**What the script does automatically:**
- Detects your OpenCart installation
- Copies all bundle module files into `catalog/` and `admin/`
- Runs the database migration (`install/migrate.php` or SQL)
- Adds `STRAPI_API_URL` to your `config.php`
- Clears OpenCart modification cache
- Fixes Plesk `user:psacln` file ownership and permissions

### Step 2 — Deploy Strapi CMS API

In Plesk, go to **Websites & Domains** → `oc-api.yourdomain.com` → **Git** → **Add Repository**:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI.git` |
| Branch | `strapi-api` |
| Deploy path | `/var/www/vhosts/oc-api.yourdomain.com/httpdocs/` |
| Deployment action | `bash .plesk/post-deploy-strapi` |

Click **Deploy**.

**What the script does automatically:**
- Verifies Node.js 18+ is installed
- Runs `npm ci` (or `npm install`) for dependencies
- Creates `.env` from `.env.example` with **auto-generated secure secrets**
- Runs `npm run build` to compile the Strapi admin panel
- Fixes Plesk file ownership and permissions
- Restarts Strapi via PM2 (if installed)

### Step 3 — Configure Apache Proxy for Strapi

The `strapi-api` branch already includes a `.htaccess` for you. If you need it manually, create `/var/www/vhosts/oc-api.yourdomain.com/httpdocs/.htaccess`:

```apache
RewriteEngine On
RewriteBase /

RewriteRule ^admin(/.*)?$          http://127.0.0.1:1337/admin$1          [P,L]
RewriteRule ^api(/.*)?$            http://127.0.0.1:1337/api$1            [P,L]
RewriteRule ^graphql(/.*)?$        http://127.0.0.1:1337/graphql$1        [P,L]
RewriteRule ^uploads(/.*)?$        http://127.0.0.1:1337/uploads$1        [P,L]
RewriteRule ^content-manager(/.*)?$ http://127.0.0.1:1337/content-manager$1 [P,L]
RewriteRule ^documentation(/.*)?$  http://127.0.0.1:1337/documentation$1  [P,L]

<IfModule mod_headers.c>
    RequestHeader set X-Forwarded-Proto "https" env=HTTPS
    RequestHeader set X-Real-IP %{REMOTE_ADDR}s
</IfModule>
```

### Step 4 — Configure Database & Start Strapi

Edit the auto-created `.env` file with your database credentials:

```bash
nano /var/www/vhosts/oc-api.yourdomain.com/httpdocs/.env
```

```env
HOST=0.0.0.0
PORT=1337
APP_KEYS=<auto-generated>
API_TOKEN_SALT=<auto-generated>
ADMIN_JWT_SECRET=<auto-generated>
TRANSFER_TOKEN_SALT=<auto-generated>
JWT_SECRET=<auto-generated>

DATABASE_CLIENT=mysql
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_NAME=your_strapi_db
DATABASE_USERNAME=your_db_user
DATABASE_PASSWORD=your_db_password
```

Then start Strapi:

```bash
cd /var/www/vhosts/oc-api.yourdomain.com/httpdocs
npm start
```

### Step 5 — Create Strapi Admin & Seed Data

1. Visit `https://oc-api.yourdomain.com/admin`
2. Create your first admin account
3. Seed demo bundles, products, and categories:

```bash
curl -X POST https://oc-api.yourdomain.com/api/seed
```

### Step 6 — Activate the Module in OpenCart

1. Log in to OpenCart Admin → **Extensions** → **Extensions** → **Modules**
2. Find **Bundle Manager** → click **Install**, then **Edit**
3. Set **API URL** to `https://oc-api.yourdomain.com/api`
4. Set **Status** to **Enabled**
5. Go to **Design** → **Layouts** → **Product** → add **Bundle Product** to Content Bottom

---

## 📦 Bundle Types

| Type | How It Works | Example |
|------|-------------|---------|
| **Fixed** | Pre-set group of products sold together at a discount | Gaming PC: CPU + GPU + RAM + SSD |
| **Dynamic** | Customer selects from an approved product pool | Build Your Own Studio Kit |
| **Tiered** | Discount increases with quantity | Buy 2 = 10% off · Buy 3 = 20% off |
| **Mix & Match** | Any combination up to X items for a flat price | Any 3 accessories for $50 |

---

## 🔌 API Reference

Base URL: `https://oc-api.yourdomain.com`

### Bundles

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/bundles` | List all bundles (supports filters, pagination) |
| `GET` | `/api/bundles/:id` | Get a single bundle by Strapi ID |
| `GET` | `/api/bundles/slug/:slug` | Find bundle by URL slug |
| `GET` | `/api/bundles/by-product/:productId` | All bundles containing a product |
| `GET` | `/api/bundles/:id/calculate` | Calculate savings for a bundle |
| `POST` | `/api/bundles/sync` | Bulk sync bundles from OpenCart |

### Products & Categories

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/products` | List all products |
| `GET` | `/api/products/by-oc-id/:id` | Find by OpenCart product_id |
| `POST` | `/api/products/sync` | Bulk sync from OpenCart |
| `GET` | `/api/categories` | List all categories |
| `GET` | `/api/categories/tree/:parentId` | Category tree |
| `POST` | `/api/categories/sync` | Bulk sync from OpenCart |

### System

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/status` | Health check + system info |
| `GET` | `/api/stats` | Content statistics |
| `POST` | `/api/seed` | Seed demo data |
| `POST` | `/api/seed/reset` | Reset all seeded data |

### GraphQL

Endpoint: `https://oc-api.yourdomain.com/graphql`

```graphql
query {
  bundles(filters: { isActive: { eq: true } }) {
    documentId
    name
    slug
    bundlePrice
    discountPercent
    products
  }
}
```

---

## 📁 Repository Structure

```
OpenCart3-StrapiCMSAPI/          ← main branch
├── opencart-module/
│   ├── admin/                   # Admin panel controllers, models, views, language
│   └── catalog/                 # Frontend controllers, models, views, language
├── assets/
│   ├── logo.svg                 # Project banner
│   └── logo-footer.svg          # Maven Music footer mark
├── docs/
│   └── TUTORIAL.md              # Full step-by-step tutorial
└── .plesk/
    └── post-deploy-opencart     # Auto-runs on Plesk Git deploy (main branch)

strapi-api branch                ← strapi-api branch
├── src/api/
│   ├── bundle/                  # Bundle content type (schema, controller, service, routes)
│   ├── category/                # Category content type
│   ├── product/                 # Product content type
│   └── seed/                    # Demo data seeder
├── config/
│   ├── database.js              # MySQL configuration
│   ├── plugins.js               # GraphQL + documentation plugins
│   └── middlewares.js           # CORS + security headers
├── .htaccess                    # Apache reverse proxy to port 1337
├── .env.example                 # Environment variable template
├── package.json                 # Strapi 5.x dependencies
└── .plesk/
    └── post-deploy-strapi       # Auto-runs on Plesk Git deploy (strapi-api branch)
```

---

## 🛠️ Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `Deployment path already exists and is not empty` | Old files or `.git` folder in `httpdocs/` | Delete all files in `httpdocs/` including any hidden `.git` folder, then deploy |
| Module not in Extensions list | Cache not cleared | `rm -rf system/storage/modification/*` then **Extensions → Modifications → Refresh** |
| `Database table 'oc_bundles' not found` | Migration didn't run | `php install/migrate.php` or run `install/bundle_install.sql` in phpMyAdmin |
| Strapi won't start | Missing `.env` or wrong DB credentials | Check `.env` exists, verify DB credentials, run `npm start` manually and check output |
| Strapi admin unreachable | Apache proxy not active or port 1337 blocked | Verify `.htaccess` proxy rules are present; check `curl http://127.0.0.1:1337` on server |
| Bundles not showing on product page | Module not assigned to layout | **Design → Layouts → Product** → add Bundle Product module to Content Bottom position |
| `Permission denied` errors | Wrong Plesk file ownership | `chown -R user:psacln /var/www/vhosts/yourdomain.com/httpdocs/catalog/` |

### Useful Debug Commands

```bash
# Check Strapi is running
curl http://127.0.0.1:1337/api/status

# Tail Strapi logs
tail -f /tmp/strapi-run.log

# Restart via PM2
pm2 restart strapi-oc-api

# Check OpenCart error log
tail -f system/storage/logs/error.log

# Re-run deploy script manually
bash .plesk/post-deploy-opencart
bash .plesk/post-deploy-strapi
```

---

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| [docs/TUTORIAL.md](docs/TUTORIAL.md) | Complete end-to-end tutorial with screenshots and examples |

---

<br>

<div align="right">
  <img src="assets/logo-footer.svg" alt="Maven Music Network" width="220">
</div>
