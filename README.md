# OpenCart Product Bundle System + Strapi CMS

<p align="center">
  <img src="assets/logo.svg" alt="OpenCart Bundle System" width="600">
</p>

<p align="center">
  <a href="https://opencart.com"><img src="https://img.shields.io/badge/OpenCart-3.0.3.2+-1a1a1a?style=flat-square&logo=opencart&logoColor=d3b65f&labelColor=0a0a0a" alt="OpenCart"></a>
  <a href="https://php.net"><img src="https://img.shields.io/badge/PHP-7.4+-1a1a1a?style=flat-square&logo=php&logoColor=d3b65f&labelColor=0a0a0a" alt="PHP"></a>
  <a href="https://strapi.io"><img src="https://img.shields.io/badge/Strapi-5.x-1a1a1a?style=flat-square&logo=strapi&logoColor=d3b65f&labelColor=0a0a0a" alt="Strapi"></a>
  <a href="https://nodejs.org"><img src="https://img.shields.io/badge/Node.js-18+-1a1a1a?style=flat-square&logo=nodedotjs&logoColor=d3b65f&labelColor=0a0a0a" alt="Node.js"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0-1a1a1a?style=flat-square&logo=gnu&logoColor=d3b65f&labelColor=0a0a0a" alt="License"></a>
</p>

<p align="center">
  <strong>A premium product bundle system for OpenCart 3.x with optional Strapi CMS integration.</strong><br>
  Create, manage, and sell product bundles — fixed, dynamic, tiered, and mix & match.
</p>

---

## Architecture

```
[Customer] ────── [OpenCart Store] ────── [Strapi API Server]
                      |                    api-oc.domain.com:1337
                      |                         |
                      |                    [MySQL Database]
                      |
               [Bundle Module]
               (frontend + admin)
```

Two branches, two domains, one system:

| Branch | Domain | What It Deploys |
|--------|--------|-----------------|
| `main` | `oc.yourdomain.com` | OpenCart Bundle Module |
| `strapi-api` | `api-oc.yourdomain.com` | Strapi CMS API |

---

## Plesk Git Deployment (2-Minute Setup)

### Prerequisites

- Plesk Obsidian 18+ with Git extension
- Node.js 18+ (Plesk Node.js extension)
- MySQL 8+ / MariaDB 10.5+
- OpenCart 3.0.3.2+ already installed

### Step 1 — Deploy OpenCart Module (main branch)

In Plesk, go to **Websites & Domains** -> `oc.yourdomain.com` -> **Git**:

| Setting | Value |
|---------|-------|
| Repository | `https://github.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI.git` |
| Branch | `main` |
| Deploy Path | `/var/www/vhosts/oc.yourdomain.com/httpdocs/` |
| Deploy Action | `bash .plesk/post-deploy-opencart` |

Click **Deploy**. The post-deploy script will:
- Copy module files into your OpenCart installation
- Run database migrations
- Fix Plesk file permissions
- Clear OpenCart cache

### Step 2 — Deploy Strapi API (strapi-api branch)

In Plesk, go to **Websites & Domains** -> `api-oc.yourdomain.com` -> **Git**:

| Setting | Value |
|---------|-------|
| Repository | `https://github.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI.git` |
| Branch | `strapi-api` |
| Deploy Path | `/var/www/vhosts/api-oc.yourdomain.com/httpdocs/` |
| Deploy Action | `bash .plesk/post-deploy-strapi` |

Click **Deploy**. The post-deploy script will:
- Install npm dependencies
- Auto-generate secure secrets in `.env`
- Build the Strapi admin panel
- Fix Plesk permissions
- Restart via PM2 (if installed)

### Step 3 — Configure Apache Proxy

Add this `.htaccess` to `api-oc.yourdomain.com/httpdocs/`:

```apache
RewriteEngine On
RewriteRule ^admin(/.*)?$   http://127.0.0.1:1337/admin$1   [P,L]
RewriteRule ^api(/.*)?$     http://127.0.0.1:1337/api$1     [P,L]
RewriteRule ^graphql(/.*)?$ http://127.0.0.1:1337/graphql$1 [P,L]
RewriteRule ^uploads(/.*)?$ http://127.0.0.1:1337/uploads$1 [P,L]
```

### Step 4 — Start Strapi & Create Admin

```bash
cd /var/www/vhosts/api-oc.yourdomain.com/httpdocs
npm start
```

Then visit `https://api-oc.yourdomain.com/admin` to create your admin account.

---

## Bundle Types

| Type | Description | Example |
|------|-------------|---------|
| **Fixed** | Pre-defined product set at a discount | Gaming PC: CPU + GPU + RAM + SSD |
| **Dynamic** | Customer picks from a pool of products | Build Your Own Box |
| **Tiered** | Quantity-based pricing tiers | Buy 2 = 10% off, Buy 3 = 20% off |
| **Mix & Match** | Any X items for a fixed price | Any 3 items for $50 |

---

## API Endpoints (Strapi)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/bundles` | List all bundles |
| `GET` | `/api/bundles/:id` | Get bundle by ID |
| `GET` | `/api/bundles/by-slug/:slug` | Get by slug |
| `GET` | `/api/bundles/by-product/:id` | Find bundles containing a product |
| `POST` | `/api/bundles/sync` | Sync bundles from OpenCart |
| `GET` | `/api/status` | Health check |
| `POST` | `/api/seed` | Seed demo data |

---

## Repository Structure

```
OpenCart3-StrapiCMSAPI/
├── opencart-module/          # OpenCart Bundle Module
│   ├── admin/                # Admin panel files
│   ├── catalog/              # Frontend files
│   └── install/              # SQL migrations
├── src/                      # Strapi API source
│   └── api/
│       ├── bundle/           # Bundle content type
│       ├── category/         # Category content type
│       ├── product/          # Product content type
│       └── seed/             # Demo data seeder
├── config/                   # Strapi configuration
├── .plesk/                   # Plesk deploy scripts
│   ├── post-deploy-opencart  # Runs on main branch deploy
│   └── post-deploy-strapi    # Runs on strapi-api branch deploy
├── assets/                   # Logos & branding
│   ├── logo.svg              # Full banner logo
│   └── logo-footer.svg       # Compact footer logo
└── docs/                     # Documentation
    └── TUTORIAL.md           # Full step-by-step tutorial
```

---

## Quick Commands

```bash
# Seed demo data
curl -X POST https://api-oc.yourdomain.com/api/seed

# Health check
curl https://api-oc.yourdomain.com/api/status

# Sync bundles from OpenCart to Strapi
curl -X POST https://api-oc.yourdomain.com/api/bundles/sync

# Check Strapi logs
tail -50 /tmp/strapi-run.log

# Restart Strapi via PM2
pm2 restart strapi-oc-api
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Module not showing in Extensions | Clear modification cache: `rm -rf system/storage/modification/*` then refresh |
| Database table not found | Run `php install/migrate.php` |
| Permission denied (Plesk) | `chown -R user:psacln catalog/ admin/` |
| Strapi API not connecting | Check `curl http://localhost:1337` and firewall |
| Bundles not on product page | Check module is installed and assigned to layout |

---

## Support

- Website: [mavenmusic.network](https://mavenmusic.network)
- Documentation: [docs/TUTORIAL.md](docs/TUTORIAL.md)

---

<p align="right">
  <img src="assets/logo-footer.svg" alt="Maven Music Network" width="300">
</p>
