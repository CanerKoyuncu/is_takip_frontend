# 🚀 Hızlı Başlangıç Rehberi

## Development / Production (Docker Compose)

### 1️⃣ Başlat
```bash
cd backend

# Docker Compose başlat (MongoDB + Backend + Nginx)
docker-compose up -d

# Durumu kontrol et
docker-compose ps
```

### 2️⃣ Kontrol Et
```bash
# Nginx health check (HTTP)
curl http://localhost/health

# API test (via Nginx)
curl http://localhost/api/jobs

# Backend direct (if needed)
curl http://localhost:4000/health

# Logs
docker-compose logs -f
docker-compose logs -f nginx
docker-compose logs -f backend
```

### 3️⃣ Durdur
```bash
# Containers'ı durdur
docker-compose stop

# Containers'ı tamamen kaldır
docker-compose down
```

### 4️⃣ SSL Sertifikası (İsteğe Bağlı - Development)

Development'ta self-signed sertifika:

```bash
# SSL klasörü oluştur
mkdir -p ssl

# Self-signed certificate oluştur
openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem \
  -days 365 -nodes -subj "/CN=localhost"

# Docker Compose'ı yeniden başlat
docker-compose restart nginx
```

Production'ta Let's Encrypt sertifikası:

```bash
# Bkz. NGINX_PRODUCTION_SETUP.md
```

---

## 📊 Mimarisi

```
Docker Compose
├── Nginx (Ports 80/443)
│   └─ http://localhost → https://localhost (redirect)
│
├── Backend (Port 4000 - internal)
│   └─ curl http://localhost:4000/health
│
└── MongoDB (Port 27017 - internal)
    └─ Host: mongodb (container network içinde)
```

**Erişim Yolları:**
- Web: `http://localhost` (Nginx)
- API: `http://localhost/api/jobs` (via Nginx)
- Backend Direct: `http://localhost:4000/health` (if needed)
- MongoDB: `mongodb://mongodb:27017` (container network içinde)

---

## 🎯 Nginx Konfigürasyonu

- **Dosya:** `backend/nginx.conf`
- **Production Kurulumu:** Bkz. `NGINX_PRODUCTION_SETUP.md`
- **Özellikler:**
  - ✅ Reverse proxy (Backend 4000)
  - ✅ SSL/HTTPS (Let's Encrypt)
  - ✅ Rate limiting (DDoS protection)
  - ✅ Client IP forwarding (X-Forwarded-For)
  - ✅ CORS headers
  - ✅ Security headers
  - ✅ Gzip compression

---

## 🐛 Sorun Giderme

### Docker
```bash
# Logs kontrol et
docker-compose logs backend

# Container'a bağlan
docker-compose exec backend bash

# Service yeniden başlat
docker-compose restart backend
```

### Nginx
```bash
# Syntax kontrol et
sudo nginx -t

# Service durumu
sudo systemctl status nginx

# Logs
sudo tail -f /var/log/nginx/error.log
```

---

## 📚 Belgeler

- `DIRECTORY_STRUCTURE.md` - Tam dizin yapısı
- `NGINX_PRODUCTION_SETUP.md` - Nginx detaylı kurulumu
- `README.md` - Backend dökümanı
- `TOKEN_SYSTEM_GUIDE.md` - JWT/Token sistemi
- `PHOTO_STORAGE.md` - Dosya depolama

---

**✅ Başlamaya hazır!** 🚀

