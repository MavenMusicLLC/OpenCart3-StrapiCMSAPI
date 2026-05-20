# Plesk Deployment Guide — OpenCart + Strapi CMS

## Complete deployment for Plesk Obsidian (non-Docker)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Deployment Options](#deployment-options)
5. [Step-by-Step Instructions](#step-by-step-instructions)
6. [Post-Deployment Setup](#post-deployment-setup)
7. [PM2 Startup Persistence](#pm2-startup-persistence)
8. [Troubleshooting](#troubleshooting)
9. [Production Hardening](#production-hardening)
10. [Known Plesk Limitations](#known-plesk-limitations)

---

## Overview

This guide covers deploying the **OpenCart3-StrapiCMSAPI** bundle system on Plesk Obsidian using native Plesk Node.js support, npm, and Apache + nginx reverse proxy — **without Docker**.

The system consists of:
- **OpenCart 3.x** — e-commerce storefront (PHP 8+, MySQL)
- **Strapi CMS 5.x** — headless CMS for product bundles (Node.js 18+, MySQL)
- **Bundle Module** — PHP integration connecting OpenCart to Strapi API

---

## Architecture

### Option A — Separated (2 domains, recommended)

```
oc.yourdomain.com (PHP/Apache)          oc-api.yourdomain.com (Node.js)
┌──────────────────┐                   ┌──────────────────────┐
│  OpenCart Store  │ ─── HTTPS REST ───│  Strapi CMS API      │
│  + Bundle Module │                   │  Port 1337           │
└──────────────────┘                   └──────────────────────┘
```

### Option B — Bundled (1 domain)

```
yourdomain.com (PHP + Node.js)
┌─────────────────────────────────────────────────┐
│  /                     → OpenCart store         │
│  /strapi               → Strapi admin (proxy)   │
│  /api                  → REST API   (proxy)    │
│  /graphql              → GraphQL    (proxy)    │
└─────────────────────────────────────────────────┘
```

---

## Prerequisites

### Plesk Settings (Required)

| Setting | Value | Location |
|---------|-------|----------|
| PHP version | 8.0+ (8.2 recommended) | Subscriptions → PHP |
| Node.js | 18.x LTS or 20.x LTS | Add/Remove Components |
| MySQL/MariaDB | 8.0+ | Add/Remove Components |
| Apache modules | mod_rewrite, mod_proxy, mod_proxy_http, mod_headers | Plesk → Apache Settings |
| SSL | Let's Encrypt or paid cert | SSL/TLS Settings |

### Server Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 1 GB | 2 GB+ |
| Disk | 5 GB | 15 GB+ |
| Swap | 1 GB (if RAM < 1GB) | 2 GB |

### Required PHP Extensions

```
pdo pdo_mysql json mbstring gd curl zip openssl filter session
```

### Required Apache Modules

```
mod_rewrite mod_proxy mod_proxy_http mod_headers
```

---

## Deployment Options

### Option A — OpenCart Module Only (`main` branch)

Use when you already have Strapi on a separate server/domain.

```bash
# Domain: oc.yourdomain.com
# Branch: main
# Deploy path: /var/www/vhosts/oc.yourdomain.com/httpdocs/
# Deploy action: bash .plesk/post-deploy-opencart
```

### Option B — Strapi API Subdomain (`strapi-api` branch)

Use when Strapi runs on its own subdomain.

```bash
# Domain: api-oc.yourdomain.com
# Branch: strapi-api
# Deploy path: /var/www/vhosts/api-oc.yourdomain.com/httpdocs/
# Deploy action: bash .plesk/post-deploy-strapi
```

### Option C — Full OpenCart Installation + Bundle (`deploy-opencart` script)

Use when you need a **complete fresh OpenCart install** on a domain — downloads OpenCart 3.x, configures the database, sets up permissions, and optionally installs the Bundle Manager + Strapi integration.

```bash
# Fresh OpenCart install (no Strapi)
bash deploy-opencart.sh yourdomain.com

# OpenCart install WITH Bundle Manager + Strapi
bash deploy-opencart.sh yourdomain.com --with-bundle --strapi-url https://api.mystore.com/api

# OpenCart with custom database credentials
bash deploy-opencart.sh yourdomain.com --db-name opencart_db --db-user admin --db-pass MySecurePass

# OpenCart with bundle, custom repo/branch
bash deploy-opencart.sh yourdomain.com --with-bundle --strapi-url https://api.mystore.com/api --bundle-branch main
```

### Option D — Bundled (`bundled` branch) — Both on One Domain

Use when both run on one domain, Strapi proxied under `/api`.

```bash
# Domain: yourdomain.com
# Branch: bundled
# Deploy path: /var/www/vhosts/yourdomain.com/httpdocs/
# Deploy action: bash .plesk/post-deploy-bundled
```

---

## Step-by-Step Instructions

### Phase 1 — Prepare Plesk

#### 1.1 Enable Apache Modules

```bash
a2enmod rewrite proxy proxy_http headers
systemctl restart apache2
```

#### 1.2 Install Node.js via Plesk

```bash
# Via Plesk Panel:
# Subscriptions → yourdomain.com → Add/Remove Components
# → Node.js (check) → Apply
```

#### 1.3 Install PM2 (for process management)

```bash
npm install -g pm2
pm2 install pm2-logrotate
```

#### 1.4 Configure Swap (if RAM < 1GB)

```bash
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
swapon /swapfile >> /etc/fstab
```

### Phase 2 — Create Database

```bash
# Via Plesk Panel:
# Databases → Add Database
#   Name: opencart_db
#   User: opencart_user
#   Password: (strong random password)

# For Strapi (separate DB recommended):
# Databases → Add Database
#   Name: strapi_opencart
#   User: strapi_user
#   Password: (strong random password)
```

### Phase 3 — Upload OpenCart (if not pre-installed)

1. Download OpenCart 3.x from https://www.opencart.com
2. Upload files to `/var/www/vhosts/yourdomain.com/httpdocs/`
3. Visit `https://yourdomain.com` to run the installer
4. Delete the `install/` directory after setup

### Phase 4 — Configure Plesk Git Deploy

#### For Bundled Deployment (recommended for most users)

1. **Empty the httpdocs directory** (delete all files, including hidden `.git`)
2. **Plesk → Websites & Domains → yourdomain.com → Git**
3. **Add Repository:**
   - Repository URL: `https://github.com/MavenMusicLLC/OpenCart3-StrapiCMSAPI.git`
   - Branch: `bundled`
   - Deploy path: `/var/www/vhosts/yourdomain.com/httpdocs/`
   - Deployment action: `bash .plesk/post-deploy-bundled`
4. **Enable auto-deploy** on push
5. Click **Deploy**

The deploy script will automatically:
- Install OpenCart module files
- Run database migrations
- Set up Strapi in `strapi/` subdirectory
- Install Node.js dependencies
- Build Strapi admin panel
- Configure Apache proxy rules
- Start Strapi via PM2

### Phase 5 — Post-Deploy Configuration

#### 5.1 Edit Strapi .env

```bash
nano /var/www/vhosts/yourdomain.com/httpdocs/strapi/.env
```

Update these values:
```
HOST=0.0.0.0
PORT=1337
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_NAME=strapi_opencart
DATABASE_USERNAME=strapi_user
DATABASE_PASSWORD=your_real_password_here
```

#### 5.2 Restart Strapi

```bash
cd /var/www/vhosts/yourdomain.com/httpdocs/strapi
pm2 restart strapi-bundled-yourdomain.com
```

#### 5.3 Create Strapi Admin Account

1. Visit `https://yourdomain.com/strapi/admin`
2. Create your first admin user
3. Save credentials securely

#### 5.4 Seed Demo Data (optional)

```bash
curl -X POST https://yourdomain.com/api/seed
```

#### 5.5 Activate OpenCart Module

1. OpenCart Admin → **Extensions** → **Extensions**
2. Modules → **Bundle Manager** → **Install**
3. Edit → Set **API URL** to `https://yourdomain.com/api`
4. Set **Status** → **Enabled**
5. **Design** → **Layouts** → **Product** → Add **Bundle Product** to Content Bottom
6. **Extensions** → **Modifications** → **Refresh**

---

## Post-Deployment Setup

### Enable PM2 Startup on Reboot

```bash
pm2 startup
# Copy the command it outputs and run it as root
pm2 save
```

### Verify Everything is Running

```bash
# Check PM2 processes
pm2 list

# Test Strapi API
curl https://yourdomain.com/api/status

# Test OpenCart
curl https://yourdomain.com

# Run full health check
bash healthcheck.sh yourdomain.com
```

### Expected PM2 Output

```
┌─────────────────┬──────┬─────────┬───────┬──────────┬─────────────┬─────┐
│ App name        │ id   │ status  │ restarts │ uptime  │  memory    │ cpu │
├─────────────────┼──────┼─────────┼───────┼──────────┼─────────────┼─────┤
│ strapi-bundled  │ 0   │ online  │ 0      │ 5d      │ 120MB      │ 1%  │
└─────────────────┴──────┴─────────┴───────┴──────────┴─────────────┴─────┘
```

---

## PM2 Startup Persistence

### Ensure Strapi Starts After Reboot

```bash
# Generate startup script
pm2 startup

# Example output for systemd:
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u username --hp /home/username

# Save current process list
pm2 save

# Restart
pm2 resurrect
```

### Monitor Logs

```bash
pm2 logs strapi-bundled --lines 50
pm2 logs strapi-bundled --err --lines 20
```

### Auto-Restart on Crash

PM2 automatically restarts crashed processes. Configure memory limit:

```bash
pm2 start npm --name "strapi-bundled" -- start --max-memory-restart 512M
```

---

## Troubleshooting

### Strapi Won't Start

**Symptom:** `pm2 list` shows "errored" or Strapi process immediately exits

**Diagnose:**
```bash
pm2 logs strapi-bundled --lines 50
curl http://127.0.0.1:1337/api/status
```

**Common causes:**

1. **Missing .env or bad DB credentials**
   ```bash
   # Check Strapi logs
   pm2 logs strapi-bundled --lines 20
   
   # Verify .env exists
   cat /var/www/vhosts/yourdomain.com/httpdocs/strapi/.env | grep DATABASE
   
   # Test MySQL connection
   mysql -u strapi_user -p -h localhost strapi_opencart -e "SELECT 1;"
   ```

2. **Port 1337 already in use**
   ```bash
   # Check what's using the port
   ss -tlnp | grep 1337
   
   # Kill the old process
   pkill -f strapi
   pm2 restart strapi-bundled
   ```

3. **Build artifacts missing**
   ```bash
   cd /var/www/vhosts/yourdomain.com/httpdocs/strapi
   npm run build
   pm2 restart strapi-bundled
   ```

### Strapi Admin Unreachable (404 / Proxy Error)

**Symptom:** `https://yourdomain.com/strapi` returns 404 or proxy error

**Diagnose:**
```bash
# Test direct connection
curl http://127.0.0.1:1337/admin

# Check Apache proxy
apache2ctl -M | grep proxy
```

**Fix:**
```bash
# Verify .htaccess exists with proxy rules
cat /var/www/vhosts/yourdomain.com/httpdocs/.htaccess | grep 1337

# If missing, run repair
bash repair-plesk.sh yourdomain.com
```

### OpenCart Module Not in Extensions List

**Symptom:** Bundle Manager doesn't appear in OpenCart extensions

**Fix:**
```bash
# Clear modification cache
rm -rf /var/www/vhosts/yourdomain.com/httpdocs/system/storage/modification/*

# Refresh modifications in OpenCart Admin
# Extensions → Modifications → Refresh
```

### API Communication Failure

**Symptom:** Bundles not loading on OpenCart product pages

**Diagnose:**
```bash
# Test Strapi API directly
curl https://yourdomain.com/api/bundles

# Check OpenCart config
grep STRAPI_API_URL /var/www/vhosts/yourdomain.com/httpdocs/config.php
```

**Fix:**
```bash
# Edit OpenCart config
nano /var/www/vhosts/yourdomain.com/httpdocs/config.php

# Add or update:
define('STRAPI_API_URL', 'https://yourdomain.com/api');
```

### Build Failures (npm install / npm run build)

**Symptom:** Build script fails or runs out of memory

**Diagnose:**
```bash
# Check available memory
free -m

# Check disk space
df -h /var/www

# Check Node version
node -v
```

**Fix:**
```bash
# Add swap
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Clean and rebuild
cd /var/www/vhosts/yourdomain.com/httpdocs/strapi
rm -rf node_modules .cache build
npm ci
NODE_ENV=production npm run build
```

### Permission Errors

**Symptom:** "Permission denied" in Apache or PM2 logs

**Fix:**
```bash
# Get Plesk owner
stat -c '%U' /var/www/vhosts/yourdomain.com/httpdocs

# Fix ownership
chown -R username:psacln /var/www/vhosts/yourdomain.com/httpdocs
chmod 755 /var/www/vhosts/yourdomain.com/httpdocs/catalog
chmod 755 /var/www/vhosts/yourdomain.com/httpdocs/admin
chmod -R 775 /var/www/vhosts/yourdomain.com/httpdocs/strapi/.cache
chmod -R 775 /var/www/vhosts/yourdomain.com/httpdocs/strapi/public/uploads
chmod 600 /var/www/vhosts/yourdomain.com/httpdocs/strapi/.env
```

### SSL Certificate Issues

**Symptom:** Mixed content warnings, API returning HTTP instead of HTTPS

**Fix:**
```bash
# Force HTTPS in Strapi config
nano /var/www/vhosts/yourdomain.com/httpdocs/strapi/config/server.js

# Ensure proxy settings:
# proxy: { enabled: true, ssl: true }
# url: 'https://yourdomain.com'

# In .htaccess, ensure headers are set:
# RequestHeader set X-Forwarded-Proto "https" env=HTTPS
```

---

## Production Hardening

### 1. Secure .env File

```bash
chmod 600 /var/www/vhosts/yourdomain.com/httpdocs/strapi/.env
chown username:psacln /var/www/vhosts/yourdomain.com/httpdocs/strapi/.env
```

### 2. Disable Strapi Telemetry

```bash
echo "STRAPI_TELEMETRY_DISABLED=true" >> /var/www/vhosts/yourdomain.com/httpdocs/strapi/.env
pm2 restart strapi-bundled
```

### 3. Set Correct File Permissions

```bash
# Strapi directories
find /var/www/vhosts/yourdomain.com/httpdocs/strapi -type d -exec chmod 755 {} \;
find /var/www/vhosts/yourdomain.com/httpdocs/strapi -type f -exec chmod 644 {} \;
chmod 600 /var/www/vhosts/yourdomain.com/httpdocs/strapi/.env

# OpenCart
find /var/www/vhosts/yourdomain.com/httpdocs/catalog -type d -exec chmod 755 {} \;
find /var/www/vhosts/yourdomain.com/httpdocs/catalog -type f -exec chmod 644 {} \;
find /var/www/vhosts/yourdomain.com/httpdocs/admin -type d -exec chmod 755 {} \;
find /var/www/vhosts/yourdomain.com/httpdocs/admin -type f -exec chmod 644 {} \;
```

### 4. Configure Fail2Ban

```bash
apt install fail2ban
systemctl enable fail2ban
```

### 5. Set Up Log Rotation

```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 save
```

### 6. Enable HTTP Security Headers

Add to `.htaccess`:

```apache
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
</IfModule>
```

### 7. Rate Limiting (Apache)

```apache
<IfModule mod_ratelimit.c>
    <Location />
        SetOutputFilter RATE_LIMIT
        SetEnv rate-limit 5120
    </Location>
</IfModule>
```

### 8. Disable Directory Listing

Ensure `.htaccess` has:
```apache
Options -Indexes
```

---

## Known Plesk Limitations

### 1. Plesk Node.js Extension

- Only runs as the domain owner user (not root)
- Limited to one Node.js version per domain
- Startup timeout may be too short for Strapi build

**Workaround:** Use PM2 instead of Plesk's built-in Node.js management for Strapi.

### 2. Apache + nginx Reverse Proxy

- Plesk uses nginx as a frontend proxy by default
- This means Apache's `.htaccess` RewriteRules need nginx equivalents
- nginx config can conflict with Apache proxy settings

**Workaround:** Configure both:
- `.htaccess` for Apache RewriteRules (inside httpdocs)
- nginx additional directives for proxy settings

**In Plesk → Domain → Hosting & DNS → Apache & nginx Settings → Additional nginx directives:**
```nginx
location /api {
    proxy_pass http://127.0.0.1:1337;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
    proxy_read_timeout 300s;
    proxy_connect_timeout 75s;
}

location /graphql {
    proxy_pass http://127.0.0.1:1337;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location /strapi {
    proxy_pass http://127.0.0.1:1337;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location /uploads {
    proxy_pass http://127.0.0.1:1337;
    proxy_set_header Host $host;
}
```

### 3. Process Timeouts

- Plesk may kill long-running npm processes (install/build)
- Default startup timeout: 120 seconds

**Workaround:** Run `npm ci` and `npm run build` via SSH/sudo, not through Plesk panel.

### 4. Firewall Ports

- Port 1337 must be accessible only locally
- Ensure Plesk firewall allows loopback traffic

```bash
# Verify loopback is allowed
iptables -L -n | grep 127.0.0.1
```

### 5. Plesk Git Deploy Hooks

- Post-deploy hooks run as the domain owner
- PATH may be restricted
- Some binaries may not be in PATH

**Workaround:** Scripts export PATH explicitly at the top.

### 6. Auto-Restart on Crash

- Plesk's built-in Node.js support does NOT auto-restart crashed apps
- PM2 handles this — install PM2 and use it instead of Plesk Node.js

### 7. Memory Limits

- Plesk may impose per-process memory limits
- PHP-FPM and Apache each use RAM
- Strapi build needs ~1GB free RAM

**Workaround:** Monitor with `htop` and upgrade VPS if needed.

---

## Quick Reference

### Important Paths

```bash
# Domain root
/var/www/vhosts/yourdomain.com/

# Web root
/var/www/vhosts/yourdomain.com/httpdocs/

# Strapi (bundled mode)
/var/www/vhosts/yourdomain.com/httpdocs/strapi/

# OpenCart config
/var/www/vhosts/yourdomain.com/httpdocs/config.php

# Strapi config
/var/www/vhosts/yourdomain.com/httpdocs/strapi/.env

# Apache logs
/var/www/vhosts/yourdomain.com/logs/

# PM2 logs
~/.pm2/logs/

# Deployment logs
/tmp/plesk-bundled-deploy.log
/tmp/plesk-strapi-deploy.log
/tmp/plesk-opencart-deploy.log
```

### Key Commands

```bash
# Deploy fresh OpenCart (downloads, configures DB, sets permissions)
bash deploy-opencart.sh yourdomain.com --with-bundle --strapi-url https://api.mystore.com/api

# Restart Strapi
pm2 restart strapi-bundled-yourdomain.com

# View logs
pm2 logs strapi-bundled-yourdomain.com --lines 50

# Check status
pm2 list

# Check API directly
curl http://127.0.0.1:1337/api/status

# Check via HTTPS
curl https://yourdomain.com/api/status

# Rebuild Strapi
cd /var/www/vhosts/yourdomain.com/httpdocs/strapi
npm run build
pm2 restart strapi-bundled-yourdomain.com

# Clear OpenCart cache
rm -rf /var/www/vhosts/yourdomain.com/httpdocs/system/storage/cache/*
rm -rf /var/www/vhosts/yourdomain.com/httpdocs/system/storage/modification/*

# Run validation
bash validate-plesk-env.sh yourdomain.com

# Run health check
bash healthcheck.sh yourdomain.com

# Run repair
bash repair-plesk.sh yourdomain.com
```

---

## File Reference

All scripts are located at: `/var/www/vhosts/yourdomain.com/httpdocs/`

| Script | Purpose |
|--------|---------|
| `install-plesk.sh` | Main deployment automation (opencart/strapi/bundled/deploy-opencart/validate modes) |
| `deploy-opencart.sh` | Full OpenCart 3.x installation from scratch |
| `repair-plesk.sh` | Automatic failure repair |
| `healthcheck.sh` | Runtime health verification |
| `validate-plesk-env.sh` | Pre-deployment environment check |