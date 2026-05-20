# ============================================================================
# Troubleshooting Guide — Plesk OpenCart + Strapi CMS
# For: OpenCart3-StrapiCMSAPI on Plesk Obsidian
# ============================================================================

## Quick Diagnostics (run first)

```bash
# 1. Run health check
bash healthcheck.sh yourdomain.com

# 2. Run repair script
bash repair-plesk.sh yourdomain.com

# 3. Validate environment
bash validate-plesk-env.sh yourdomain.com
```

---

## Problem: "Strapi won't start after reboot"

**Cause:** PM2 not configured for startup persistence

**Diagnosis:**
```bash
pm2 list
# If strapi process is missing, PM2 wasn't set up for startup
```

**Fix:**
```bash
# Set up PM2 startup
pm2 startup
# Run the command it outputs (as root)

# Save current state
pm2 save

# Test resurrection
pm2 resurrect
```

---

## Problem: "Strapi admin gives 404 at /strapi"

**Cause:** Apache proxy rules not working OR Strapi not running

**Diagnosis:**
```bash
# Test if Strapi is running on port 1337
curl http://127.0.0.1:1337/api/status

# Check if .htaccess has proxy rules
grep 1337 /var/www/vhosts/yourdomain.com/httpdocs/.htaccess
```

**Fix:**
```bash
# If Strapi not running:
cd /var/www/vhosts/yourdomain.com/httpdocs/strapi
pm2 restart strapi-bundled

# If .htaccess missing proxy rules:
bash repair-plesk.sh yourdomain.com

# Or manually add to .htaccess:
# RewriteRule ^strapi(/.*)?$ http://127.0.0.1:1337/admin$1 [P,L]
# RewriteRule ^api(/.*)?$ http://127.0.0.1:1337/api$1 [P,L]
```

---

## Problem: "npm install fails with EACCES permission denied"

**Cause:** Running npm install as wrong user or without proper permissions

**Diagnosis:**
```bash
ls -la /var/www/vhosts/yourdomain.com/httpdocs/strapi/node_modules 2>&1 | head -5
```

**Fix:**
```bash
# Get correct owner
OWNER=$(stat -c '%U' /var/www/vhosts/yourdomain.com/httpdocs)
chown -R $OWNER:psacln /var/www/vhosts/yourdomain.com/httpdocs/strapi

# Run install as owner
su - $OWNER -c "cd /var/www/vhosts/yourdomain.com/httpdocs/strapi && npm install"
```

---

## Problem: "Build fails — JavaScript heap out of memory"

**Cause:** Not enough RAM for the Strapi build process

**Diagnosis:**
```bash
free -m
# If available < 512MB, build will likely fail
```

**Fix:**
```bash
# Method 1: Add swap
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Method 2: Increase Node.js memory limit
cd /var/www/vhosts/yourdomain.com/httpdocs/strapi
NODE_OPTIONS="--max-old-space-size=1024" npm run build

# Method 3: Run build with more memory
NODE_ENV=production NODE_OPTIONS="--max-old-space-size=1024" npm run build
```

---

## Problem: "Bundle Manager module not appearing in OpenCart Admin"

**Cause:** Cache not cleared OR module files not in correct location

**Diagnosis:**
```bash
ls /var/www/vhosts/yourdomain.com/httpdocs/catalog/controller/module/bundle.php
ls /var/www/vhosts/yourdomain.com/httpdocs/admin/controller/module/bundle_manager.php
```

**Fix:**
```bash
# 1. Clear modification cache
rm -rf /var/www/vhosts/yourdomain.com/httpdocs/system/storage/modification/*

# 2. Clear general cache
rm -rf /var/www/vhosts/yourdomain.com/httpdocs/system/storage/cache/*

# 3. Refresh modifications in OpenCart Admin:
#    Extensions → Modifications → Refresh (top right button)

# 4. If still missing, re-run deploy script
bash install-plesk.sh opencart yourdomain.com
```

---

## Problem: "API returns 500 or connection error"

**Cause:** Database credentials wrong OR Strapi can't connect to MySQL

**Diagnosis:**
```bash
# Check Strapi logs
pm2 logs strapi-bundled --lines 30

# Test MySQL directly
mysql -u strapi_user -p -h localhost strapi_opencart -e "SELECT 1;"
```

**Fix:**
```bash
# 1. Edit .env with correct credentials
nano /var/www/vhosts/yourdomain.com/httpdocs/strapi/.env

# 2. Restart Strapi
pm2 restart strapi-bundled

# 3. If database doesn't exist, create it:
#    Plesk → Databases → Add Database
```

---

## Problem: "npm ci fails — package-lock.json is missing"

**Cause:** Lockfile not generated yet

**Fix:**
```bash
cd /var/www/vhosts/yourdomain.com/httpdocs/strapi
npm install
# This will generate package-lock.json
```

---

## Problem: "Apache returns 500 after changes"

**Cause:** .htaccess syntax error OR permission issue

**Diagnosis:**
```bash
tail -20 /var/www/vhosts/yourdomain.com/logs/error_log
```

**Fix:**
```bash
# Check .htaccess syntax
apache2ctl configtest

# Temporarily disable .htaccess (move it)
mv /var/www/vhosts/yourdomain.com/httpdocs/.htaccess /var/www/vhosts/yourdomain.com/httpdocs/.htaccess.bak
# Test site — if it works, .htaccess has an error

# Restore:
mv /var/www/vhosts/yourdomain.com/httpdocs/.htaccess.bak /var/www/vhosts/yourdomain.com/httpdocs/.htaccess
```

---

## Problem: "SSL certificate not working"

**Cause:** SSL not enabled in Plesk OR certificate expired

**Fix:**
```bash
# Via Plesk Panel:
# Websites & Domains → yourdomain.com → SSL/TLS
# → Install Let's Encrypt (free) or upload custom certificate

# Force HTTPS in .htaccess:
# RewriteEngine On
# RewriteCond %{HTTPS} off
# RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

---

## Problem: "Uploads not working"

**Cause:** Upload directory not writable

**Fix:**
```bash
# Check permissions
ls -la /var/www/vhosts/yourdomain.com/httpdocs/system/storage/upload/

# Fix permissions
chmod -R 775 /var/www/vhosts/yourdomain.com/httpdocs/system/storage/upload/
chown -R username:psacln /var/www/vhosts/yourdomain.com/httpdocs/system/storage/upload/

# For Strapi uploads
chmod -R 775 /var/www/vhosts/yourdomain.com/httpdocs/strapi/public/uploads/
```

---

## Problem: "Strapi extremely slow"

**Cause:** Low memory, too many plugins, or database not optimized

**Diagnosis:**
```bash
free -m
pm2 list
```

**Fix:**
```bash
# 1. Increase PM2 memory limit
pm2 restart strapi-bundled --update-env --max-memory-restart 512M

# 2. Reduce Strapi workers
# Edit config/server.js:
# workers: 2

# 3. Optimize MySQL:
# Run in MySQL:
# OPTIMIZE TABLE some_table;

# 4. Add caching
# Install Redis for Strapi cache (optional advanced config)
```

---

## Problem: "Git deploy not working in Plesk"

**Cause:** Deploy directory not empty OR .git exists

**Fix:**
```bash
# 1. Delete deploy directory contents
rm -rf /var/www/vhosts/yourdomain.com/httpdocs/*

# 2. Delete hidden files too
rm -rf /var/www/vhosts/yourdomain.com/httpdocs/.*

# 3. Add Git repo in Plesk Panel:
# Websites & Domains → Git → Add Repository
```

---

## Problem: "403 Forbidden error"

**Cause:** File/directory permissions too restrictive

**Fix:**
```bash
# Find incorrect permissions
namei -l /var/www/vhosts/yourdomain.com/httpdocs/index.php

# Reset all permissions
cd /var/www/vhosts/yourdomain.com/httpdocs
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
```

---

## Problem: "Connection refused on port 1337"

**Cause:** Strapi process not running

**Fix:**
```bash
# Start Strapi
cd /var/www/vhosts/yourdomain.com/httpdocs/strapi
pm2 start npm --name "strapi-bundled" -- start

# Check if port is bound
ss -tlnp | grep 1337

# If port in use by something else:
fuser -k 1337/tcp
pm2 restart strapi-bundled
```

---

## Problem: "Deployment script fails"

**Cause:** PATH not set in Plesk shell environment

**Fix:**
```bash
# Add to the start of your deploy script:
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# Or use full paths:
/usr/bin/npm ci
/usr/bin/node build.js
```

---

## Problem: "pm2 command not found"

**Cause:** PM2 not installed or PATH not set

**Fix:**
```bash
# Install PM2
npm install -g pm2

# Add to PATH permanently
echo 'export PATH="$PATH:$(npm root -g)/.bin"' >> ~/.bashrc
source ~/.bashrc
```

---

## Problem: "OpenCart says 'STRAPI_API_URL not defined'"

**Cause:** Constant not added to config.php

**Fix:**
```bash
# Add to config.php (at the end):
nano /var/www/vhosts/yourdomain.com/httpdocs/config.php

# Add:
define('STRAPI_API_URL', 'https://yourdomain.com/api');
```

---

## Problem: "Strapi GraphQL returns 400"

**Cause:** GraphQL endpoint needs POST request

**Fix:**
```bash
# Test GraphQL with POST:
curl -X POST https://yourdomain.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}'
```

---

## Error Code Reference

| Code | Meaning | Fix |
|------|---------|-----|
| EACCES | Permission denied | `chown` files to correct owner |
| ENOENT | File/directory not found | Check paths, re-run deploy |
| ECONNREFUSED | Database connection failed | Check DB credentials in .env |
| EADDRINUSE | Port in use | `fuser -k 1337/tcp` |
| ENOMEM | Out of memory | Add swap, increase RAM |
| EROFS | Read-only filesystem | Check Plesk mount options |
| ETIMEDOUT | Connection timeout | Check firewall, network |
| 500 | Server error | Check Apache/error logs |
| 502 | Bad gateway | Proxy not working, check Strapi |
| 503 | Service unavailable | Strapi not running |
| 504 | Gateway timeout | Increase proxy timeouts |

---

## Log Files Reference

| Log | Location | Purpose |
|-----|----------|---------|
| Deploy (OpenCart) | `/tmp/plesk-opencart-deploy.log` | OpenCart module deployment |
| Deploy (Strapi) | `/tmp/plesk-strapi-deploy.log` | Strapi deployment |
| Deploy (Bundled) | `/tmp/plesk-bundled-deploy.log` | Bundled deployment |
| Apache error | `/var/www/vhosts/yourdomain.com/logs/error_log` | Apache errors |
| Apache access | `/var/www/vhosts/yourdomain.com/logs/access_log` | Request logs |
| PM2 stdout | `~/.pm2/logs/strapi-bundled-out.log` | Strapi stdout |
| PM2 stderr | `~/.pm2/logs/strapi-bundled-error.log` | Strapi stderr |
| OpenCart error | `/var/www/vhosts/yourdomain.com/httpdocs/system/storage/logs/error.log` | PHP errors |

---

## Emergency Recovery

If everything is broken and you need to start over:

```bash
# 1. Stop Strapi
pm2 delete all

# 2. Clear Strapi directory
rm -rf /var/www/vhosts/yourdomain.com/httpdocs/strapi

# 3. Clear all caches
rm -rf /var/www/vhosts/yourdomain.com/httpdocs/system/storage/cache/*
rm -rf /var/www/vhosts/yourdomain.com/httpdocs/system/storage/modification/*

# 4. Re-deploy (will re-create strapi directory)
bash install-plesk.sh bundled yourdomain.com

# 5. Edit .env with real credentials
nano /var/www/vhosts/yourdomain.com/httpdocs/strapi/.env

# 6. Restart
pm2 restart strapi-bundled

# 7. Verify
bash healthcheck.sh yourdomain.com
```