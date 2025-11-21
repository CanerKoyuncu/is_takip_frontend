# 🚗 Servis İş Takip (is_takip)

Araç servisi işi takip sistemi - Flutter frontend + FastAPI backend

> 📚 **[Tüm Dokümantasyonu Burada Bulabilirsin](docs/README.md)**

---

## 🎯 Proje Yapısı

```
📱 is_takip-frontend/ (bu repo)
├── 📚 docs/                   ← Dökümanlar (BAŞLA BURADAN!)
│   ├── README.md              ← Ana Hub
│   ├── setup/                 ← Setup & Kurulum
│   ├── auth/                  ← Token & Kimlik Doğrulama
│   ├── data/                  ← Veriler & Logging
│   └── testing/               ← Test & Troubleshooting
├── 📱 lib/                    ← Flutter frontend
├── pubspec.yaml               ← Flutter dependencies
└── README.md                  ← Proje sayfası (burası)

🔧 is_takip-backend/ (ayrı repo)
├── 📚 docs/                   ← Backend dökümanları
├── 🐳 docker-compose.yml      ← Docker yapısı
├── main.py                    ← FastAPI uygulaması
├── app/                       ← API kodu
└── README.md                  ← Backend sayfası
```

---

## 🚀 Hızlı Başlangıç

### 1️⃣ Backend'i Çalıştır (Ayrı Repo)

```bash
# https://github.com/yourusername/is_takip-backend
git clone https://github.com/yourusername/is_takip-backend
cd is_takip-backend

# SSL oluştur
mkdir -p ssl
openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem \
  -days 365 -nodes -subj "/CN=localhost"

# Docker Compose başlat
docker-compose up -d

# Kontrol et
curl http://localhost/health
```

### 2️⃣ Frontend'i Çalıştır (Bu Repo)

```bash
# Buraya dön
cd is_takip-frontend

# Dependencies yükle
flutter pub get

# Çalıştır
flutter run
```

**Backend Repo:** → [is_takip-backend](https://github.com/yourusername/is_takip-backend)

---

## 📖 Dokümantasyon (Frontend)

> ℹ️ **Backend dökümanları:** [is_takip-backend/docs](https://github.com/yourusername/is_takip-backend/tree/main/docs)

### 🚀 Başlangıç
1. **[docs/README.md](docs/README.md)** ← Merkez hub (BAŞLA BURADAN!)
2. **[docs/setup/SETUP_QUICK_START.md](docs/setup/SETUP_QUICK_START.md)** ← Hızlı kurulum
3. **[docs/setup/DIRECTORY_STRUCTURE.md](docs/setup/DIRECTORY_STRUCTURE.md)** ← Yapı

### 🔐 Token & Auth
1. **[docs/auth/TOKEN_SYSTEM_GUIDE.md](docs/auth/TOKEN_SYSTEM_GUIDE.md)** ← JWT token sistemi
2. **[docs/auth/TOKEN_IMPLEMENTATION_SUMMARY.md](docs/auth/TOKEN_IMPLEMENTATION_SUMMARY.md)** ← Detaylar

### 🧪 Testing
1. **[docs/testing/TESTING_GUIDE.md](docs/testing/TESTING_GUIDE.md)** ← API test örnekleri
2. **[docs/testing/docker-troubleshoot.md](docs/testing/docker-troubleshoot.md)** ← Sorun giderme

### 📊 Veriler
1. **[docs/data/LOG_FILES_LOCATION.md](docs/data/LOG_FILES_LOCATION.md)** ← Loglar
2. **[docs/data/PHOTO_STORAGE.md](docs/data/PHOTO_STORAGE.md)** ← Dosya depolama

### 🔍 Arama
- **[docs/INDEX.md](docs/INDEX.md)** - Detaylı indeks

---

## 🏗️ Sistem Mimarisi

```
┌─────────────────────────────────────────┐
│   Flutter App (Mobil/Web)               │
└──────────────┬──────────────────────────┘
               │ (HTTP/HTTPS)
        ┌──────▼────────┐
        │ Nginx (Docker)│
        │ 80/443        │
        └──────┬────────┘
               │ (Reverse Proxy)
        ┌──────▼────────────┐
        │ Backend (Docker)  │
        │ FastAPI - 4000    │
        └──────┬────────────┘
               │
        ┌──────▼────────────┐
        │ MongoDB (Docker)  │
        │ 27017             │
        └───────────────────┘
```

---

## 🔗 Hızlı Linkler

### Hub'lar (Başla burada!)
- 🎯 **[Ana Hub](docs/README.md)** - Tüm dökümanlar
- 🔧 **[Backend Hub](backend/docs/README.md)** - Backend dökümanları

### Setup
- 🚀 **[Hızlı Başlangıç](docs/setup/SETUP_QUICK_START.md)**
- 🐳 **[Docker Kurulumu](docs/setup/DOCKER_NGINX_SETUP.md)**
- 📁 **[Klasör Yapısı](docs/setup/DIRECTORY_STRUCTURE.md)**

### Teknik
- 🔐 **[Token Sistemi](docs/auth/TOKEN_SYSTEM_GUIDE.md)**
- 📝 **[Loglar](docs/data/LOG_FILES_LOCATION.md)**
- 🧪 **[API Test](docs/testing/TESTING_GUIDE.md)**

### Production
- 🏭 **[Production Setup](docs/nginx/NGINX_PRODUCTION_SETUP.md)**
- 📸 **[Dosya Depolama](docs/data/PHOTO_STORAGE.md)**
- 🔧 **[Sorun Giderme](docs/testing/docker-troubleshoot.md)**

---

## ✅ Kontrol Listesi

- [ ] [docs/README.md](docs/README.md) oku
- [ ] Backend'i kur: `cd backend && docker-compose up -d`
- [ ] API test et: `curl http://localhost/health`
- [ ] Flutter projesini aç: `flutter run`
- [ ] [docs/auth/TOKEN_SYSTEM_GUIDE.md](docs/auth/TOKEN_SYSTEM_GUIDE.md) oku
- [ ] [docs/testing/TESTING_GUIDE.md](docs/testing/TESTING_GUIDE.md) ile test et

---

## 📞 Sık Sorulan Sorular

**P: Nereden başlamalıyım?**
A: → [docs/README.md](docs/README.md)

**P: Backend nasıl çalışır?**
A: → [docs/setup/DOCKER_NGINX_SETUP.md](docs/setup/DOCKER_NGINX_SETUP.md)

**P: API nasıl test ederim?**
A: → [docs/testing/TESTING_GUIDE.md](docs/testing/TESTING_GUIDE.md)

**P: Token sistemi nedir?**
A: → [docs/auth/TOKEN_SYSTEM_GUIDE.md](docs/auth/TOKEN_SYSTEM_GUIDE.md)

**P: Tüm dosyaların listesi?**
A: → [docs/INDEX.md](docs/INDEX.md)

---

## 🚀 Sonraki Adımlar

1. **[docs/README.md](docs/README.md)** ile başla
2. Backend'i kur ve çalıştır
3. Frontend'i çalıştır
4. API'yi test et
5. Production'a deploy et

---

**✅ Hazır mısın?** → [docs/README.md](docs/README.md)
