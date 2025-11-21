# 📁 Backend Dizin Yapısı ve Dosya Konumları

## 🎯 Tam Dosya Yapısı

```
backend/
│
├── 📄 docker-compose.yml          ✅ Docker Compose (MongoDB, Backend, Nginx)
├── 📄 Dockerfile                  ✅ Backend container image
├── 📄 nginx.conf                  ✅ Nginx reverse proxy configuration
├── 📄 requirements.txt             ✅ Python dependencies
├── 📄 main.py                      ✅ FastAPI application entry point
├── 📄 query_db.py                  ✅ Database query tools
│
├── 📂 app/                         ✅ Main application package
│   ├── 📄 __init__.py
│   ├── 📄 models.py                ✅ Pydantic models
│   │
│   ├── 📂 routers/                 ✅ API endpoints
│   │   ├── 📄 auth.py              ✅ Authentication (login, register, refresh, logout)
│   │   ├── 📄 jobs.py              ✅ Job management endpoints
│   │   └── ... (diğer routers)
│   │
│   ├── 📂 middleware/              ✅ Request/response middleware
│   │   ├── 📄 jwt_auth.py          ✅ JWT token verification
│   │   ├── 📄 api_key_auth.py      ✅ API key validation
│   │   └── ... (diğer middleware)
│   │
│   ├── 📂 models/                  ✅ Database models
│   │   ├── 📄 user_models.py       ✅ User Pydantic models
│   │   └── ... (diğer model dosyaları)
│   │
│   ├── 📂 core/                    ✅ Core utilities
│   │   ├── 📄 logger.py            ✅ Logging configuration
│   │   ├── 📄 config.py            ✅ Application configuration
│   │   ├── 📄 database.py          ✅ MongoDB connection
│   │   └── 📄 jwt_service.py       ✅ JWT token generation/verification
│   │
│   └── 📂 services/                ✅ Business logic services
│       ├── 📄 auth_service.py      ✅ Authentication service
│       ├── 📄 user_service.py      ✅ User management
│       └── ... (diğer services)
│
├── 📂 logs/                        📝 Application logs (persistent volume)
│   ├── 📄 app.log                  ✅ All logs (JSON format)
│   └── 📄 error.log                ✅ Error logs only (JSON format)
│
├── 📂 ssl/                         🔐 SSL certificates (create if needed)
│   ├── 📄 cert.pem                 🔐 SSL certificate
│   └── 📄 key.pem                  🔐 Private key
│
├── 📂 uploads/                     📸 Photos and files (persistent volume)
│   └── ... (uploaded files)
│
├── 📂 certbot/                     🔐 Let's Encrypt validation
│   └── .well-known/acme-challenge/
│
├── .env                            🔐 Environment variables
├── .env.example                    📋 Example environment file
│
└── README.md                       📖 Documentation
    NGINX_SETUP.md                  📖 Nginx configuration guide
    PHOTO_STORAGE.md                📖 Photo storage guide
    docker-troubleshoot.md          📖 Troubleshooting
```

## ✅ Önemli Dosyalar ve Konumları

| Dosya | Konum | Amaç |
|-------|-------|------|
| **nginx.conf** | `backend/nginx.conf` | Reverse proxy (client IP, SSL, rate limiting) |
| **docker-compose.yml** | `backend/docker-compose.yml` | Container orchestration |
| **main.py** | `backend/main.py` | FastAPI uygulaması |
| **jwt_auth.py** | `backend/app/middleware/jwt_auth.py` | JWT doğrulama |
| **logger.py** | `backend/app/core/logger.py` | Logging configuration |
| **auth.py** | `backend/app/routers/auth.py` | Auth endpoints |
| **requirements.txt** | `backend/requirements.txt` | Python paketleri |
| **.env** | `backend/.env` | Ortam değişkenleri |
| **logs/** | `backend/logs/` | Log dosyaları |
| **ssl/** | `backend/ssl/` | SSL sertifikaları |

## 🚀 Docker Compose Başlatmak

```bash
# Backend klasöründen çalıştır
cd backend

# Development certificate oluştur (ilk kez)
mkdir -p ssl
openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem \
  -days 365 -nodes -subj "/CN=localhost"

# Docker Compose başlat
docker-compose up

# Arka planda çalıştır
docker-compose up -d

# Logları izle
docker-compose logs -f
```

## 📊 Kontainer Yapısı

```
docker-compose.yml başlattığında:

1. MongoDB
   - Image: mongo:7.0
   - Container: servis-is-takip-mongodb
   - Port: 27017 (internal)
   - Volume: mongodb_data (persistent)

2. Backend (FastAPI)
   - Build: ./Dockerfile
   - Container: servis-is-takip-backend
   - Port: 4000 (internal only, exposed through nginx)
   - Volumes:
     - logs_data (persistent logs)
     - photos_data (persistent uploads)

3. Nginx (Reverse Proxy)
   - Image: nginx:alpine
   - Container: servis-is-takip-nginx
   - Ports: 80 (HTTP), 443 (HTTPS)
   - Config: ./nginx.conf ← backend/nginx.conf
   - Volumes:
     - ./ssl (certificates)
     - ./certbot (Let's Encrypt validation)
     - nginx_logs (persistent logs)
```

## 🔐 SSL Sertifikaları

SSL sertifikası kurulumu **production ortamında** Nginx server üzerinde yapılır.
Detaylı bilgi için: `NGINX_PRODUCTION_SETUP.md`

```bash
# Production server'da
sudo certbot --nginx -d example.com -d www.example.com
```

## 📝 Dosya Yolları Referansı

```bash
# Docker Container'ında (Backend)

# Backend application
- /app/main.py
- /app/app/routers/
- /app/app/middleware/
- /app/app/core/

# Logs (persistent volume: logs_data)
- /app/logs/app.log
- /app/logs/error.log

# Uploads (persistent volume: photos_data)
- /app/uploads/
```

Production'da Nginx ise host işletim sistemi üzerinde çalışır:

```bash
# Production Server'da

# Nginx configuration
- /etc/nginx/nginx.conf

# SSL certificates (Let's Encrypt)
- /etc/letsencrypt/live/example.com/fullchain.pem
- /etc/letsencrypt/live/example.com/privkey.pem

# Nginx logs
- /var/log/nginx/access.log
- /var/log/nginx/error.log
```

## 🎯 Çalıştırma Adımları

### 1. Hazırlık
```bash
cd backend

# Environment file oluştur
cp .env.example .env
# .env dosyasını düzenle (gerekirse)
```

### 2. Docker Compose ile Başlat
```bash
# Containers'ı başlat
docker-compose up -d

# Durum kontrol et
docker-compose ps

# Logları izle
docker-compose logs -f
```

### 3. Kontrol Et
```bash
# Backend sağlık kontrolü
curl http://localhost:4000/health

# API'ye erişim
curl http://localhost:4000/api/jobs

# MongoDB bağlantı kontrolü
docker-compose exec mongodb mongosh

# Backend logs
docker-compose logs -f backend

# Container'a bağlan
docker-compose exec backend bash
```

### 4. Production'da (Nginx ile)
Production ortamında Nginx setup'ı için: `NGINX_PRODUCTION_SETUP.md`

```bash
# Server'da Nginx konfigürasyonunu kopyala
sudo cp backend/nginx.conf /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl reload nginx

# SSL sertifikası (Let's Encrypt)
sudo certbot --nginx -d example.com

# Logları izle
sudo tail -f /var/log/nginx/access.log
```

## 🛑 Durdur

```bash
# Containers'ı durdur
docker-compose stop

# Containers'ı kaldır
docker-compose down

# Volume'leri de kaldır (dikkat!)
docker-compose down -v
```

## 📋 Docker Compose Komutları

```bash
# Build and start
docker-compose up -d --build

# Stop
docker-compose stop

# Restart
docker-compose restart

# Remove containers
docker-compose down

# Remove containers and volumes
docker-compose down -v

# View logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f [service_name]

# Check status
docker-compose ps

# Execute command in container
docker-compose exec [service_name] [command]

# Examples
docker-compose exec backend bash
docker-compose exec mongodb mongosh
docker-compose exec backend curl http://localhost:4000/health
```

---

**✅ Backend klasöründeki tüm dosyalar doğru konumda!** 🚀

