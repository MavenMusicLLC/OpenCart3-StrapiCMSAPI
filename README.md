# 🛒 OpenCart Product Bundle System with Strapi CMS

<div align="center">

<img src="assets/logo-maven-music.svg" alt="Maven Music Network - OpenCart Bundle System" width="700">

[![OpenCart](https://img.shields.io/badge/OpenCart-3.0.3.2+-1a1a1a?style=for-the-badge&logo=opencart&logoColor=d3b65f&labelColor=0a0a0a)](https://opencart.com)
[![PHP](https://img.shields.io/badge/PHP-7.4+-1a1a1a?style=for-the-badge&logo=php&logoColor=d3b65f&labelColor=0a0a0a)](https://php.net)
[![Strapi](https://img.shields.io/badge/Strapi-5.x-1a1a1a?style=for-the-badge&logo=strapi&logoColor=d3b65f&labelColor=0a0a0a)](https://strapi.io)
[![License](https://img.shields.io/badge/License-GPL--3.0-1a1a1a?style=for-the-badge&logo=gnu&logoColor=d3b65f&labelColor=0a0a0a)](LICENSE)

<p align="center">
  <strong style="color: #d3b65f;">A Premium Product Bundle System for OpenCart 3.x</strong><br>
  <span style="color: #888;">Create, manage, and sell product bundles with optional Strapi CMS integration</span>
</p>

</div>

---

## 🚀 Plesk Git Deployment

### Repository Structure

```
OpenCart3-StrapiCMSAPI/
├── opencart-module/     # OpenCart Bundle Module
├── strapi-api/          # Strapi CMS API (branch: strapi-api)
├── install/             # Installation scripts
├── docs/                # Documentation
├── .plesk/              # Plesk auto-deploy scripts
└── assets/              # Logos & branding
```

### Deploy Options

**Option A: OpenCart Only**
- Branch: `main`
- Deploy Path: `/var/www/vhosts/yourdomain.com/httpdocs/`

**Option B: OpenCart + Strapi API**
- Branch 1: `main` → `/var/www/vhosts/yourdomain.com/httpdocs/`
- Branch 2: `strapi-api` → `/var/www/vhosts/api.yourdomain.com/httpdocs/`

---

## 🎯 Quick Deploy

### Step 1: Add Repository in Plesk Git

1. Go to **Domains** → Select your domain → **Git**
2. Click **Add Repository**
3. Enter:
   ```
   Repository URL: https://github.com/yourusername/OpenCart3-StrapiCMSAPI.git
   Branch: main (or strapi-api for API subdomain)
   ```
4. Deploy path: `/var/www/vhosts/yourdomain.com/httpdocs/`
5. Click **Deploy**

### Step 2: Run Post-Deploy Script

```bash
cd /var/www/vhosts/yourdomain.com/httpdocs
bash .plesk/post-deploy
```

---

## 📖 Documentation

| Document | Description | Link |
|----------|-------------|------|
| 📘 **Full Tutorial** | Complete step-by-step guide | [docs/TUTORIAL.md](docs/TUTORIAL.md) |
| 🖥️ **Plesk Guide** | Plesk-specific deployment | [docs/PLESK.md](docs/PLESK.md) |
| 🔧 **API Reference** | REST API endpoints | [docs/API.md](docs/API.md) |

---

## 🏗️ Component Structure

### OpenCart Module (`opencart-module/`)
```
opencart-module/
├── admin/           # Admin panel files
├── catalog/         # Frontend files
└── install/         # SQL & migration scripts
```

### Strapi API (`strapi-api/` branch)
```
strapi-api/
├── config/          # Strapi configuration
├── src/api/bundle/  # Bundle content type
├── package.json     # Dependencies
└── .env.example     # Environment template
```

---

## 🔌 API Endpoints (Strapi)

Once Strapi is deployed, your API is available at:

```
https://api.yourdomain.com/api
```

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/bundles` | List all bundles |
| GET | `/api/bundles/:id` | Get bundle by ID |
| GET | `/api/bundles/by-slug/:slug` | Get by slug |
| GET | `/api/bundles/by-product/:id` | Find by product |
| POST | `/api/bundles/sync` | Sync from OpenCart |

---

## 📞 Support

- 🌐 Website: [mavenmusic.network](https://mavenmusic.network)

---

<div align="center">

**Made with ❤️ by Maven Music Network**

**Version 1.0.0** • Compatible with OpenCart 3.0.3.2+

</div>