# 📋 Nginx Konfigürasyon Özeti

## 🎯 Durum

✅ **Nginx Docker'da çalışıyor**
✅ **Backend Nginx arkasında (internal)**
✅ **MongoDB Nginx arkasında (internal)**
✅ **SSL ready (self-signed for dev, Let's Encrypt for prod)**

---

## 📁 Dosyalar

| Dosya | Konum | Amaç |
|-------|-------|------|
| **nginx.conf** | `backend/nginx.conf` | Production Nginx konfigürasyonu |
| **docker-compose.yml** | `backend/docker-compose.yml` | MongoDB + Backend (Nginx YOK) |
| **NGINX_PRODUCTION_SETUP.md** | `backend/NGINX_PRODUCTION_SETUP.md` | Detaylı Nginx kurulum rehberi |
| **SETUP_QUICK_START.md** | `backend/SETUP_QUICK_START.md` | Hızlı başlangıç |

---

## 🏗️ Mimarisi

### Docker Compose (Development & Production)
```
http://localhost (Nginx) → https://localhost (Nginx)
    ↓ (Reverse Proxy)
Backend:4000 (internal, FastAPI)
    ↓
MongoDB:27017 (internal)
```

**Port Açılış:**
- Nginx: 80 (HTTP) ve 443 (HTTPS) - PUBLIC
- Backend: 4000 - INTERNAL (only accessible from Nginx)
- MongoDB: 27017 - INTERNAL (only accessible from Backend)

---

## 🔧 Nginx.conf Bölümleri

### 1. Upstream (Backend)
```nginx
upstream backend {
    server backend:4000;  # Docker container network içinde
    keepalive 64;
}
```

**Docker Compose'da:**
- `backend:4000` → Container ismi ve port
- Container network içinde otomatik olarak çözülür

### 2. HTTP → HTTPS Redirect
```nginx
server {
    listen 80;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;  # Let's Encrypt verification
    }
    
    location / {
        return 301 https://$host$request_uri;  # HTTPS'e yönlendir
    }
}
```

### 3. HTTPS Server
```nginx
server {
    listen 443 ssl http2;
    server_name _;  # Kendi domain'i yazarsan: example.com
    
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
}
```

**Değiştirmesi Gereken Yerler:**
- `server_name _;` → `server_name example.com www.example.com;`
- SSL sertifika yolları

### 4. API Endpoints (Rate Limiting)
```nginx
location /api/ {
    limit_req zone=api_limit burst=200 nodelay;
    proxy_pass http://backend;
    # ... headers ve ayarlar
}
```

### 5. Auth Endpoints (Daha Sıkı Rate Limiting)
```nginx
location /api/auth/ {
    limit_req zone=auth_limit burst=5 nodelay;  # 10 req/s limit
    proxy_pass http://backend;
}
```

### 6. Header Forwarding
```nginx
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Port $server_port;
```

Backend'de `X-Forwarded-For` header'ı okunur ve client IP bulunur.

---

## 🚀 Production'da Kurulma Adımları

### Step 1: Nginx Yükleme
```bash
sudo apt update && sudo apt install -y nginx certbot python3-certbot-nginx
```

### Step 2: Konfigürasyonu Kopyalama
```bash
# Local'den
scp backend/nginx.conf user@server:/tmp/

# Server'da
sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf

# Syntax kontrol
sudo nginx -t
```

### Step 3: nginx.conf'u Düzenleme
```bash
# Production değerlerini gir
sudo nano /etc/nginx/nginx.conf

# Değiştirilmesi gereken yerler:
# - Line 58: upstream backend → domain/IP
# - Line 81: server_name → domain adı
# - Line 84-85: SSL sertifika yolları
```

### Step 4: SSL Sertifikası
```bash
# Let's Encrypt otomatik kurulumu
sudo certbot --nginx -d example.com -d www.example.com

# Manual kurulumu ise
sudo certbot certonly --standalone -d example.com
```

### Step 5: Nginx'i Başlatma
```bash
# Yeniden başlat
sudo systemctl restart nginx

# Otomatik başlat'ı etkinleştir
sudo systemctl enable nginx

# Durumu kontrol et
sudo systemctl status nginx
```

### Step 6: Backend Container'ını Başlatma
```bash
cd backend

# Containers başlat
docker-compose up -d

# Durumu kontrol et
docker-compose ps
```

---

## 📊 Rate Limiting Ayarları

```nginx
# Tanım
limit_req_zone $http_x_forwarded_for zone=api_limit:10m rate=100r/s;
limit_req_zone $http_x_forwarded_for zone=auth_limit:10m rate=10r/s;

# Kullanım
location /api/ {
    limit_req zone=api_limit burst=200 nodelay;
}

location /api/auth/ {
    limit_req zone=auth_limit burst=5 nodelay;
}
```

**Anlamı:**
- `100r/s` = 100 request/saniye
- `burst=200` = 200 request'e kadar bufferleme
- `nodelay` = Hemen yanıt ver, buffer etmeyi bekleme
- `$http_x_forwarded_for` = Client IP bazında limit

---

## 🔐 Security Headers

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

---

## 🔗 Client IP Okuma

### Nginx'ten Backend'e
```nginx
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

### Backend'de (main.py)
```python
x_forwarded_for = request.headers.get("x-forwarded-for")
if x_forwarded_for:
    client_ip = x_forwarded_for.split(",")[0].strip()
else:
    client_ip = request.client.host
```

---

## 📊 Nginx Komutları (Production)

```bash
# Syntax kontrol
sudo nginx -t

# Başlat
sudo systemctl start nginx

# Durdur
sudo systemctl stop nginx

# Yeniden başlat
sudo systemctl restart nginx

# Soft reload (connections'ları bozmadan)
sudo systemctl reload nginx

# Durumu kontrol et
sudo systemctl status nginx

# Logları izle
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Boot'ta otomatik başlat
sudo systemctl enable nginx

# Boot'ta otomatik başlat'ı kaldır
sudo systemctl disable nginx
```

---

## 🎯 Önemli Noktalar

1. **Backend Server Adresi**
   - Docker: `backend:4000`
   - Local: `127.0.0.1:4000`
   - Remote: `192.168.x.x:4000`

2. **SSL Sertifikası**
   - Development: Self-signed
   - Production: Let's Encrypt (ücretsiz)

3. **Rate Limiting**
   - API: 100 req/s (DDoS protection)
   - Auth: 10 req/s (Brute-force protection)

4. **Client IP**
   - Backend'de `X-Forwarded-For` header'ından okunur
   - Log'larda görülür

5. **CORS**
   - Tüm origin'lere izin (gerekirse kısıtlanabilir)

---

## 📚 Daha Fazla Bilgi

- Detaylı kurulum: `NGINX_PRODUCTION_SETUP.md`
- Hızlı başlangıç: `SETUP_QUICK_START.md`
- Dizin yapısı: `DIRECTORY_STRUCTURE.md`

---

**✅ Nginx konfigürasyonu production'a hazır!** 🚀

