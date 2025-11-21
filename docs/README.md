# 📚 Frontend Dokümantasyon Hub

Flutter frontend dökümanları burada organize edilmiştir.

> 📱 **Frontend Repo:** Burası  
> 🔧 **Backend Repo:** [is_takip-backend](https://github.com/yourusername/is_takip-backend)  
> **[← Proje Sayfasına Dön](../README.md)**

---

## 🚀 Hızlı Başlangıç

**5 Dakikada Başla:**

```bash
cd backend

# SSL oluştur
mkdir -p ssl
openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem -days 365 -nodes -subj "/CN=localhost"

# Docker Compose başlat
docker-compose up -d

# Test et
curl http://localhost/health
```

Daha detaylı → [setup/SETUP_QUICK_START.md](setup/SETUP_QUICK_START.md)

---

## 📁 Dokümantasyon Kategorileri

### 🟢 Setup & Kurulum
Yeni başlayanlar için başlangıç dökümanları

| Dosya | Amaç | Süre |
|-------|------|------|
| [**setup/SETUP_QUICK_START.md**](setup/SETUP_QUICK_START.md) | 5 dakikalık hızlı başlangıç | 5 min |
| [**setup/DOCKER_NGINX_SETUP.md**](setup/DOCKER_NGINX_SETUP.md) | Docker + Nginx detaylı kurulum | 30 min |
| [**setup/DIRECTORY_STRUCTURE.md**](setup/DIRECTORY_STRUCTURE.md) | Dosya ve klasör yapısı | 10 min |

### 🔵 Nginx & Proxy
Nginx reverse proxy konfigürasyonu

| Dosya | Amaç | Seviye |
|-------|------|--------|
| [**nginx/NGINX_CONFIG_SUMMARY.md**](nginx/NGINX_CONFIG_SUMMARY.md) | Nginx hızlı referans | Başlangıç |
| [**nginx/NGINX_PRODUCTION_SETUP.md**](nginx/NGINX_PRODUCTION_SETUP.md) | Production Nginx kurulumu | İleri |
| [**nginx/nginx.conf**](nginx/nginx.conf) | Nginx konfigürasyon dosyası | Teknik |

### 🔐 Token & Kimlik Doğrulama
JWT token sistemi ve authentication

| Dosya | Amaç |
|-------|------|
| [**auth/TOKEN_SYSTEM_GUIDE.md**](auth/TOKEN_SYSTEM_GUIDE.md) | JWT token sistemi nasıl çalışır? |
| [**auth/TOKEN_IMPLEMENTATION_SUMMARY.md**](auth/TOKEN_IMPLEMENTATION_SUMMARY.md) | Token implementasyon detayları |

### 📊 Veriler & Logging
Veri yönetimi, log dosyaları ve monitoring

| Dosya | Amaç |
|-------|------|
| [**data/LOG_FILES_LOCATION.md**](data/LOG_FILES_LOCATION.md) | Log dosyaları ve izleme |
| [**data/PHOTO_STORAGE.md**](data/PHOTO_STORAGE.md) | Dosya depolama ve yönetimi |

### 🧪 Test & Troubleshooting
API test örnekleri ve sorun giderme

| Dosya | Amaç |
|-------|------|
| [**testing/TESTING_GUIDE.md**](testing/TESTING_GUIDE.md) | API test örnekleri ve curl komutları |
| [**testing/docker-troubleshoot.md**](testing/docker-troubleshoot.md) | Docker sorun giderme |

---

## 🎯 Seviyelere Göre Öğrenme

### 🟢 Başlangıç (1 saat)
```
README.md (burası)
    ↓
setup/SETUP_QUICK_START.md (5 min)
    ↓
Docker Compose başlat (15 min)
    ↓
testing/TESTING_GUIDE.md (20 min)
    ↓
API test et
```

### 🟡 Orta (2 saat)
```
setup/DOCKER_NGINX_SETUP.md (40 min)
    ↓
auth/TOKEN_SYSTEM_GUIDE.md (50 min)
    ↓
data/LOG_FILES_LOCATION.md (30 min)
```

### 🔴 İleri (2 saat)
```
nginx/NGINX_PRODUCTION_SETUP.md (60 min)
    ↓
auth/TOKEN_IMPLEMENTATION_SUMMARY.md (40 min)
    ↓
data/PHOTO_STORAGE.md (20 min)
```

---

## 🗺️ Klasör Yapısı

```
docs/
├── README.md                      ← Burası (Hub)
├── INDEX.md                       ← Tüm dosyaların listesi
├── SUMMARY.md                     ← Dökümentasyon özeti
│
├── setup/                         ← Setup & Kurulum
│   ├── SETUP_QUICK_START.md       ← BAŞLA BURADAN
│   ├── DOCKER_NGINX_SETUP.md
│   └── DIRECTORY_STRUCTURE.md
│
├── nginx/                         ← Nginx Konfigürasyonu
│   ├── NGINX_CONFIG_SUMMARY.md
│   ├── NGINX_PRODUCTION_SETUP.md
│   └── nginx.conf
│
├── auth/                          ← Token & Authentication
│   ├── TOKEN_SYSTEM_GUIDE.md
│   └── TOKEN_IMPLEMENTATION_SUMMARY.md
│
├── data/                          ← Veriler & Logging
│   ├── LOG_FILES_LOCATION.md
│   └── PHOTO_STORAGE.md
│
└── testing/                       ← Test & Troubleshooting
    ├── TESTING_GUIDE.md
    └── docker-troubleshoot.md
```

---

## 🔗 Hızlı Linkler

### Hub'lar
- 🎯 [Ana Hub](README.md) - Burası
- 🔧 [Backend Hub](../backend/docs/README.md) - Backend dökümanları
- 📑 [İndeks](INDEX.md) - Tüm dosyaların listesi

### Başlamak İçin
- 🚀 [Hızlı Başlangıç](setup/SETUP_QUICK_START.md)
- 🐳 [Docker Kurulumu](setup/DOCKER_NGINX_SETUP.md)
- 📁 [Klasör Yapısı](setup/DIRECTORY_STRUCTURE.md)

### Teknik
- 🔐 [Token Sistemi](auth/TOKEN_SYSTEM_GUIDE.md)
- 📝 [Loglar](data/LOG_FILES_LOCATION.md)
- 🧪 [API Test](testing/TESTING_GUIDE.md)

### Production
- 🏭 [Nginx Production](nginx/NGINX_PRODUCTION_SETUP.md)
- 📸 [Dosya Depolama](data/PHOTO_STORAGE.md)
- 🔧 [Sorun Giderme](testing/docker-troubleshoot.md)

---

## ✅ Kontrol Listesi

Hızlı kurulum için:

- [ ] Bu dosyayı oku (5 min)
- [ ] [setup/SETUP_QUICK_START.md](setup/SETUP_QUICK_START.md) oku (5 min)
- [ ] Docker Compose başlat
- [ ] `curl http://localhost/health` test et
- [ ] [testing/TESTING_GUIDE.md](testing/TESTING_GUIDE.md) ile API test et

---

## 🎓 Serilik Seçin

**İlk Kez Mi?**
→ [setup/SETUP_QUICK_START.md](setup/SETUP_QUICK_START.md)

**Sistem Mi Anlamak İstiyorsun?**
→ [setup/DOCKER_NGINX_SETUP.md](setup/DOCKER_NGINX_SETUP.md)

**API Mi Test Etmek İstiyorsun?**
→ [testing/TESTING_GUIDE.md](testing/TESTING_GUIDE.md)

**Token Sistemi Mi Öğrenmek İstiyorsun?**
→ [auth/TOKEN_SYSTEM_GUIDE.md](auth/TOKEN_SYSTEM_GUIDE.md)

**Production'a Mı Deploy Etmek İstiyorsun?**
→ [nginx/NGINX_PRODUCTION_SETUP.md](nginx/NGINX_PRODUCTION_SETUP.md)

**Sorunla Karşılaştın Mı?**
→ [testing/docker-troubleshoot.md](testing/docker-troubleshoot.md)

**Tüm Dosyaları Görmek İstiyorsun?**
→ [INDEX.md](INDEX.md)

---

## 🚀 Sonraki Adımlar

1. **[setup/SETUP_QUICK_START.md](setup/SETUP_QUICK_START.md)** ile başla
2. Backend'i kur ve çalıştır
3. Flutter uygulamasını aç
4. [testing/TESTING_GUIDE.md](testing/TESTING_GUIDE.md) ile API test et
5. [auth/TOKEN_SYSTEM_GUIDE.md](auth/TOKEN_SYSTEM_GUIDE.md) oku

---

## 📞 Sık Sorulan Sorular

**P: Nereden başlamalıyım?**
A: → [setup/SETUP_QUICK_START.md](setup/SETUP_QUICK_START.md)

**P: Backend nasıl çalışır?**
A: → [setup/DOCKER_NGINX_SETUP.md](setup/DOCKER_NGINX_SETUP.md)

**P: API nasıl test ederim?**
A: → [testing/TESTING_GUIDE.md](testing/TESTING_GUIDE.md)

**P: Token sistemi nedir?**
A: → [auth/TOKEN_SYSTEM_GUIDE.md](auth/TOKEN_SYSTEM_GUIDE.md)

**P: Logları nerede bulurum?**
A: → [data/LOG_FILES_LOCATION.md](data/LOG_FILES_LOCATION.md)

**P: Production'a nasıl deploy ederim?**
A: → [nginx/NGINX_PRODUCTION_SETUP.md](nginx/NGINX_PRODUCTION_SETUP.md)

**P: Sorunla karşılaştım!**
A: → [testing/docker-troubleshoot.md](testing/docker-troubleshoot.md)

**P: Tüm dosyaların listesi?**
A: → [INDEX.md](INDEX.md)

---

## 💡 İpuçları

1. **İnsan dostu yapı**: Her kategori kendi klasöründe
2. **Hızlı erişim**: Hızlı Linkler bölümünü kullan
3. **Seviyeni seç**: Öğrenme yolunu takip et
4. **Örnekleri test et**: Tüm komutları çalıştır
5. **Sorularını sor**: Sık Sorulan Sorular bölümünü kontrol et

---

**✅ Hoşgeldin! Başlamaya hazırsan:**

→ [setup/SETUP_QUICK_START.md](setup/SETUP_QUICK_START.md)

---

[← Proje Sayfasına Dön](../README.md)
