# SSL & Domain Setup Guide

**Domain**: tenjo.adilabs.id  
**VPS IP**: 103.129.149.67

---

## 📋 Prerequisites Checklist

- [ ] Domain `tenjo.adilabs.id` registered
- [ ] DNS access to configure A record
- [ ] VPS running on 103.129.149.67
- [ ] Nginx installed and running
- [ ] Port 80 and 443 open in firewall

---

## 🌐 Step 1: Configure DNS

### At Your Domain Provider (e.g., Cloudflare, Namecheap, GoDaddy):

1. **Add A Record:**
   ```
   Type: A
   Name: tenjo (or @tenjo for subdomain)
   Value: 103.129.149.67
   TTL: Auto (or 3600)
   ```

2. **Wait for DNS Propagation:**
   - Usually takes 5-60 minutes
   - Can take up to 48 hours in some cases

3. **Verify DNS:**
   ```bash
   # From your Mac or VPS:
   dig +short tenjo.adilabs.id
   
   # Should return:
   # 103.129.149.67
   ```

   Or use online tools:
   - https://dnschecker.org/
   - https://mxtoolbox.com/SuperTool.aspx

---

## 🔧 Step 2: Configure Nginx for Domain

### Option A: Using existing config with server_name

Edit Nginx config:
```bash
sudo nano /etc/nginx/sites-available/tenjo
```

Add or update `server_name`:
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name tenjo.adilabs.id www.tenjo.adilabs.id 103.129.149.67;
    
    root /var/www/Tenjo/dashboard/public;
    index index.php;
    
    # ... rest of config
}
```

Test and reload:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Option B: Create new config for domain

```bash
sudo nano /etc/nginx/sites-available/tenjo-domain
```

Add:
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name tenjo.adilabs.id www.tenjo.adilabs.id;
    
    root /var/www/Tenjo/dashboard/public;
    index index.php index.html;
    
    client_max_body_size 10M;
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

Enable and reload:
```bash
sudo ln -s /etc/nginx/sites-available/tenjo-domain /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔐 Step 3: Install SSL Certificate (Certbot)

### Install Certbot:

```bash
# Update packages
sudo apt update

# Install Certbot and Nginx plugin
sudo apt install -y certbot python3-certbot-nginx
```

### Install SSL Certificate:

**Method 1: Automatic (Recommended)**
```bash
sudo certbot --nginx -d tenjo.adilabs.id

# Follow prompts:
# 1. Enter email address (e.g., admin@adilabs.id)
# 2. Agree to Terms of Service (Y)
# 3. Subscribe to EFF newsletter (optional - Y/N)
# 4. Redirect HTTP to HTTPS? (2 - Yes, recommended)
```

**Method 2: Non-Interactive (for automation)**
```bash
sudo certbot --nginx \
  -d tenjo.adilabs.id \
  --non-interactive \
  --agree-tos \
  --email admin@adilabs.id \
  --redirect
```

**Method 3: Multiple Domains (with www)**
```bash
sudo certbot --nginx \
  -d tenjo.adilabs.id \
  -d www.tenjo.adilabs.id \
  --non-interactive \
  --agree-tos \
  --email admin@adilabs.id \
  --redirect
```

### Verify SSL Installation:

```bash
# Check certificate
sudo certbot certificates

# Test HTTPS
curl -I https://tenjo.adilabs.id

# Should return HTTP/2 200
```

---

## ✅ Step 4: Verify Setup

### 1. Test HTTP Redirect:
```bash
curl -I http://tenjo.adilabs.id
```
Expected: `HTTP/1.1 301 Moved Permanently` → HTTPS

### 2. Test HTTPS:
```bash
curl -I https://tenjo.adilabs.id
```
Expected: `HTTP/2 200`

### 3. Test in Browser:
- Open: https://tenjo.adilabs.id
- Should see green padlock 🔒
- No SSL warnings

### 4. Check Auto-Renewal:
```bash
# Test renewal
sudo certbot renew --dry-run

# Check renewal timer
sudo systemctl status certbot.timer
```

---

## 🔄 Auto-Renewal Setup

Certbot automatically sets up renewal via systemd timer.

### Check Timer Status:
```bash
sudo systemctl status certbot.timer
```

### Manual Renewal (if needed):
```bash
sudo certbot renew
```

### Force Renewal:
```bash
sudo certbot renew --force-renewal
```

---

## 📝 Update Laravel Configuration

### 1. Update .env (if needed):
```bash
cd /var/www/Tenjo/dashboard
nano .env
```

Update:
```env
APP_URL=https://tenjo.adilabs.id
SESSION_DOMAIN=.tenjo.adilabs.id
SANCTUM_STATEFUL_DOMAINS=tenjo.adilabs.id,www.tenjo.adilabs.id
```

### 2. Clear Cache:
```bash
php artisan config:cache
php artisan cache:clear
php artisan route:cache
```

### 3. Update Client Config:

Already done in `client/src/core/config.py`:
```python
SERVER_URL = "https://tenjo.adilabs.id"
API_ENDPOINT = "https://tenjo.adilabs.id/api"
```

---

## 🔍 Troubleshooting

### DNS Not Resolving?

**Check DNS:**
```bash
dig +short tenjo.adilabs.id
nslookup tenjo.adilabs.id
```

**Check from VPS:**
```bash
curl -I http://tenjo.adilabs.id
```

**Common Issues:**
- DNS not propagated yet (wait 5-60 minutes)
- Wrong A record IP address
- Cloudflare proxy enabled (orange cloud - disable for Certbot)

### Certbot Fails?

**Error: DNS not resolving**
```
Solution: Wait for DNS propagation, then retry
```

**Error: Port 80/443 not accessible**
```bash
# Check firewall
sudo ufw status

# Allow ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

**Error: Nginx config error**
```bash
# Test config
sudo nginx -t

# Check logs
sudo tail -50 /var/log/nginx/error.log
```

**Error: Rate limit reached**
```
Solution: Let's Encrypt has rate limits (5 certs per domain per week)
Wait 1 hour or use staging environment for testing:
sudo certbot --nginx -d tenjo.adilabs.id --staging
```

### SSL Certificate Invalid?

**Check Certificate:**
```bash
sudo certbot certificates
```

**Renew Certificate:**
```bash
sudo certbot renew --force-renewal
```

**Check Nginx Config:**
```bash
sudo nano /etc/nginx/sites-available/tenjo
# Look for ssl_certificate and ssl_certificate_key paths
```

### Mixed Content Errors?

**Force HTTPS in Laravel:**
```php
// In app/Providers/AppServiceProvider.php boot() method:
if ($this->app->environment('production')) {
    \URL::forceScheme('https');
}
```

Then:
```bash
php artisan config:cache
```

---

## 📊 Final Verification Checklist

- [ ] DNS resolves correctly: `dig +short tenjo.adilabs.id` returns `103.129.149.67`
- [ ] HTTP redirects to HTTPS: `curl -I http://tenjo.adilabs.id` returns 301
- [ ] HTTPS works: `curl -I https://tenjo.adilabs.id` returns 200
- [ ] Green padlock in browser
- [ ] No SSL warnings
- [ ] Auto-renewal configured: `sudo certbot renew --dry-run` succeeds
- [ ] Dashboard accessible: https://tenjo.adilabs.id/login
- [ ] API accessible: https://tenjo.adilabs.id/api/health
- [ ] Client can connect with HTTPS

---

## 🎯 Quick Commands Reference

```bash
# Check DNS
dig +short tenjo.adilabs.id

# Install Certbot
sudo apt update && sudo apt install -y certbot python3-certbot-nginx

# Install SSL
sudo certbot --nginx -d tenjo.adilabs.id --non-interactive --agree-tos --email admin@adilabs.id --redirect

# Check certificates
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Test HTTPS
curl -I https://tenjo.adilabs.id

# Check Nginx config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Check auto-renewal timer
sudo systemctl status certbot.timer

# View certificate details
openssl s_client -connect tenjo.adilabs.id:443 -servername tenjo.adilabs.id < /dev/null | openssl x509 -noout -dates
```

---

## 🚀 After SSL Setup

Your application will be accessible at:

**Dashboard:**
```
https://tenjo.adilabs.id/login
```

**API:**
```
https://tenjo.adilabs.id/api
```

**Client Downloads:**
```
https://tenjo.adilabs.id/downloads/client/
```

**Client Update Check:**
```
https://tenjo.adilabs.id/api/clients/{client_id}/check-update
```

---

## 💡 Pro Tips

1. **Always use HTTPS in production** - Never send passwords over HTTP
2. **Enable HSTS** - Add to Nginx config (Certbot does this automatically)
3. **Monitor certificate expiry** - Certbot auto-renews, but monitor anyway
4. **Use Cloudflare** - For additional DDoS protection and caching (optional)
5. **Backup certificates** - Located in `/etc/letsencrypt/`

---

**Certificate Valid For**: 90 days  
**Auto-Renewal**: Every 60 days (automatic)  
**Issuer**: Let's Encrypt  
**Cost**: FREE! ✨
