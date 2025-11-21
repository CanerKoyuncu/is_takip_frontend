# 🐳 Docker + Nginx Kurulumu

## 🎯 Yapı

```
docker-compose.yml
├── MongoDB (27017 - internal)
├── Backend (4000 - internal)
└── Nginx (80/443 - PUBLIC)
```

---

## 🚀 Hızlı Başlangıç

### Step 1: SSL Sertifikası Oluştur (Development)

```bash
cd backend

# SSL klasörü oluştur
mkdir -p ssl

# Self-signed certificate (365 gün)
openssl req -x509 -newkey rsa:4096 \
  -keyout ssl/key.pem \
  -out ssl/cert.pem \
  -days 365 \
  -nodes \
  -subj "/CN=localhost"
```

### Step 2: Docker Compose Başlat

```bash
cd backend

# Containers başlat
docker-compose up -d

# Durumu kontrol et
docker-compose ps
```

### Step 3: Test Et

```bash
# HTTP (Nginx'e yönlendir HTTPS'e)
curl -L http://localhost/health

# HTTPS (self-signed)
curl -k https://localhost/health

# API
curl -k https://localhost/api/jobs

# Backend direct
curl http://localhost:4000/health
```

---

## 📊 Container Durumu

```bash
docker-compose ps

# Output:
# NAME                           STATUS              PORTS
# servis-is-takip-mongodb        Up (healthy)        27017/tcp
# servis-is-takip-backend        Up (healthy)        4000/tcp
# servis-is-takip-nginx          Up (healthy)        0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

---

## 📝 Logları İzle

```bash
# Tüm loglar
docker-compose logs -f

# Sadece Nginx
docker-compose logs -f nginx

# Sadece Backend
docker-compose logs -f backend

# Sadece MongoDB
docker-compose logs -f mongodb

# Son 50 satır
docker-compose logs --tail=50 nginx
```

---

## 🔐 SSL Sertifikası

### Development (Self-Signed)

```bash
# Zaten oluşturuldu (Step 1'de)
# Dosya konumu: backend/ssl/
#   ├── cert.pem
#   └── key.pem
```

### Production (Let's Encrypt)

**Manual kurulum (host OS'de Nginx çalışıyorsa):**

```bash
# Server'da
sudo certbot --nginx -d example.com -d www.example.com
```

**Docker container'ında (isteğe bağlı):**

```bash
# Certbot container'ı çalıştır
docker run --rm -it \
  -v /home/user/backend/ssl:/etc/letsencrypt \
  -v /home/user/backend/certbot:/var/www/certbot \
  certbot/certbot certonly --standalone \
  -d example.com -d www.example.com
```

---

## 🏗️ Docker Network

Container'lar otomatik olarak `app-network` bridge network'ü üzerinden birbirine bağlıdır:

```
Nginx ←→ Backend ←→ MongoDB
(container network içinde iletişim)
```

**Container'dan diğerine bağlanmak:**

```bash
# Backend'den MongoDB'ye
docker-compose exec backend bash
# mongosh mongodb:27017

# Nginx container'ına bağlan
docker-compose exec nginx ash
# curl http://backend:4000/health
```

---

## 🛑 Container'ları Yönet

```bash
# Başlat
docker-compose up -d

# Durdur
docker-compose stop

# Yeniden başlat
docker-compose restart

# Kaldır (data kalır)
docker-compose down

# Kaldır (data silinir - dikkat!)
docker-compose down -v

# Rebuild et
docker-compose up -d --build

# Belirli servisi yeniden başlat
docker-compose restart nginx
```

---

## 📍 Ports Açıklaması

| Port | Servis | Erişim | Amaç |
|------|--------|--------|------|
| **80** | Nginx | PUBLIC | HTTP → HTTPS redirect |
| **443** | Nginx | PUBLIC | HTTPS (API) |
| **4000** | Backend | INTERNAL | FastAPI (Nginx'ten erişilir) |
| **27017** | MongoDB | INTERNAL | Database (Backend'ten erişilir) |

---

## 🐛 Sorun Giderme

### Nginx 80/443 port'larını alamıyor

```bash
# Hangi process port kullanıyor?
sudo lsof -i :80
sudo lsof -i :443

# Process'i öldür (eğer başka Nginx varsa)
sudo systemctl stop nginx

# Docker Compose'ı yeniden başlat
docker-compose restart nginx
```

### Backend bağlantı hatası

```bash
# Backend log'unu kontrol et
docker-compose logs backend

# MongoDB bağlantısını test et
docker-compose exec backend bash
curl http://mongodb:27017/

# Backend directly test et
curl http://localhost:4000/health
```

### SSL sertifikası hatası

```bash
# Self-signed sertifika bilgisi
openssl x509 -in backend/ssl/cert.pem -text -noout

# Expiration tarihi
openssl x509 -in backend/ssl/cert.pem -noout -enddate

# Curl'de sertifika uyarısını ignore et
curl -k https://localhost/health

# Browser'da: Advanced → Proceed anyway
```

### Nginx config hatası

```bash
# Syntax kontrol et
docker-compose exec nginx nginx -t

# Error log
docker-compose logs nginx | grep error

# Full config kontrol et
docker-compose exec nginx cat /etc/nginx/nginx.conf
```

---

## 📊 Volume'ler

```
docker-compose.yml volumes:

mongodb_data/
  └─ MongoDB veritabanı dosyaları

mongodb_config/
  └─ MongoDB ayarları

photos_data/
  └─ Yüklenen dosyalar (/app/uploads)

logs_data/
  └─ Backend logları (/app/logs)

nginx_logs/
  └─ Nginx logları (/var/log/nginx)
```

---

## 🔗 Network İçinde İletişim

**Backend'den MongoDB'ye:**
```python
# mongodb://mongodb:27017
# (container name:port, Docker resolve eder)
```

**Nginx'ten Backend'e:**
```nginx
upstream backend {
    server backend:4000;  # container_name:port
}
```

**Dış dünyadan Nginx'e:**
```
http://localhost/api/jobs
https://localhost/api/jobs (self-signed)
```

---

## 🎯 Development Workflow

```bash
# 1. Start containers
cd backend
docker-compose up -d

# 2. Watch logs
docker-compose logs -f backend

# 3. Test API
curl http://localhost/api/jobs

# 4. Code değiştir ve test et
# Backend auto-reload (dev mode)

# 5. Container'ı yeniden başlat (gerekirse)
docker-compose restart backend

# 6. Done - Ctrl+C to stop
docker-compose stop
```

---

## ✅ Checklist

- ✅ SSL sertifikası oluşturuldu (`backend/ssl/`)
- ✅ `docker-compose.yml` kuruldu
- ✅ `nginx.conf` kuruldu
- ✅ `main.py` X-Forwarded-For header'ını okuyor
- ✅ Containers başlatıldı ve sağlıklı
- ✅ Ports açık (80, 443)
- ✅ Loglar çalışıyor

---

**✅ Docker + Nginx tam olarak kuruldu!** 🚀

