# 🚀 Strapi CMS API for OpenCart Bundle System

<div align="center">

<img src="assets/logo-maven-music.svg" alt="Maven Music Network - Strapi API" width="400">

**Deploy this branch to your API subdomain (e.g., `api.yourdomain.com`)**

[![Strapi](https://img.shields.io/badge/Strapi-5.46.0-1a1a1a?style=for-the-badge&logo=strapi&logoColor=d3b65f&labelColor=0a0a0a)](https://strapi.io)
[![Node.js](https://img.shields.io/badge/Node.js-18+-1a1a1a?style=for-the-badge&logo=node.js&logoColor=d3b65f&labelColor=0a0a0a)](https://nodejs.org)

</div>

---

## 📦 What's in This Branch?

This branch contains **only the Strapi CMS** for the OpenCart Bundle System.

### Deploy this to your API subdomain:
```
api.yourdomain.com
cms.yourdomain.com
admin.yourdomain.com
```

---

## ⚡ Quick Deploy

### Via Plesk Git (Recommended)

1. In Plesk, go to **Git**
2. Click **Add Repository**
3. Enter:
   ```
   Repository URL: https://github.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI.git
   Branch: strapi-api
   ```
4. Deploy to: `/var/www/vhosts/yourdomain.com/api/`
5. Click **Deploy**

### After Deploy:

```bash
cd /var/www/vhosts/yourdomain.com/api/

# Install dependencies
npm install

# Build Strapi
npm run build

# Start server
npm start
```

---

## 🚀 Setup After Deploy

### Step 1: Configure Environment

```bash
cp .env.example .env
nano .env
```

**Update these values:**
```env
# Database
DATABASE_NAME=strapi_yourdb
DATABASE_USERNAME=strapi_user
DATABASE_PASSWORD=your_secure_password

# Secrets (generate random strings)
APP_KEYS=key1,key2,key3,key4
API_TOKEN_SALT=random_string
ADMIN_JWT_SECRET=random_string
TRANSFER_TOKEN_SALT=random_string
```

### Step 2: Start Strapi

```bash
npm start
```

### Step 3: Create Admin User

Visit: `https://api.yourdomain.com/admin`

Create your first admin user.

---

## 🔌 API Endpoints

Once deployed, your API is available at:

```
https://api.yourdomain.com/api
```

### Available Routes:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/bundles` | List all bundles |
| GET | `/api/bundles/:id` | Get bundle by ID |
| GET | `/api/bundles/by-slug/:slug` | Get by slug |
| GET | `/api/bundles/by-product/:id` | Find by product |
| POST | `/api/bundles/sync` | Sync from OpenCart |

---

## 🔗 Connect to OpenCart

In your OpenCart `config.php`:

```php
define('STRAPI_API_URL', 'https://api.yourdomain.com/api');
```

---

## 📄 Full Documentation

For complete setup, see the [main repository](https://github.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI/tree/main)

---

<div align="center">

**Made with ❤️ by [Maven Music Network](https://mavenmusic.network)**

</div>