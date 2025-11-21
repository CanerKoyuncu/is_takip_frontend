# 📑 Dokümantasyon İndeksi

Tüm dokümantasyon dosyalarının tam listesi ve açıklaması.

---

## 🏠 Hub Dosyaları

| Dosya | Konum | Amaç | Boyut |
|-------|-------|------|-------|
| [**DOCUMENTATION.md**](DOCUMENTATION.md) | Root | 🎯 Ana dokümantasyon hub | ~5 KB |
| [**backend/DOCS.md**](backend/DOCS.md) | Backend | 🔧 Backend dokümantasyon hub | ~8 KB |

---

## 📖 Setup & Kurulum

| Dosya | Konum | Amaç | Süre | Seviye |
|-------|-------|------|------|--------|
| [**SETUP_QUICK_START.md**](backend/SETUP_QUICK_START.md) | Backend | 🚀 Hızlı başlangıç (Docker) | 5 min | Başlangıç |
| [**DOCKER_NGINX_SETUP.md**](backend/DOCKER_NGINX_SETUP.md) | Backend | 🐳 Docker + Nginx detaylı | 30 min | Orta |
| [**DIRECTORY_STRUCTURE.md**](backend/DIRECTORY_STRUCTURE.md) | Backend | 📁 Dosya ve klasör yapısı | 10 min | Başlangıç |

---

## 🔧 Nginx & Proxy

| Dosya | Konum | Amaç | Seviye |
|-------|-------|------|--------|
| [**NGINX_CONFIG_SUMMARY.md**](backend/NGINX_CONFIG_SUMMARY.md) | Backend | 📋 Nginx quick reference | Başlangıç |
| [**NGINX_PRODUCTION_SETUP.md**](backend/NGINX_PRODUCTION_SETUP.md) | Backend | 🏭 Production Nginx kurulumu | İleri |
| [**nginx.conf**](backend/nginx.conf) | Backend | ⚙️ Nginx konfigürasyon dosyası | Teknik |

---

## 🔐 Kimlik Doğrulama & Token

| Dosya | Konum | Amaç |
|-------|-------|------|
| [**TOKEN_SYSTEM_GUIDE.md**](TOKEN_SYSTEM_GUIDE.md) | Root | JWT token sistemi - detaylı açıklama |
| [**TOKEN_IMPLEMENTATION_SUMMARY.md**](TOKEN_IMPLEMENTATION_SUMMARY.md) | Root | Token implementasyon - teknik detaylar |

---

## 📊 Veri & Logging

| Dosya | Konum | Amaç |
|-------|-------|------|
| [**LOG_FILES_LOCATION.md**](LOG_FILES_LOCATION.md) | Root | 📝 Log dosyaları ve izleme |
| [**PHOTO_STORAGE.md**](backend/PHOTO_STORAGE.md) | Backend | 📸 Dosya depolama ve yönetimi |

---

## 🧪 Test & Troubleshooting

| Dosya | Konum | Amaç |
|-------|-------|------|
| [**TESTING_GUIDE.md**](TESTING_GUIDE.md) | Root | 🧪 API test örnekleri ve curl komutları |
| [**docker-troubleshoot.md**](backend/docker-troubleshoot.md) | Backend | 🔧 Docker sorun giderme |

---

## 📖 Ana Dökümanlar

| Dosya | Konum | Amaç |
|-------|-------|------|
| [**README.md**](backend/README.md) | Backend | 📖 Backend ana dökümanı |

---

## 🔨 Konfigürasyon Dosyaları

| Dosya | Konum | Amaç |
|-------|-------|------|
| [**docker-compose.yml**](backend/docker-compose.yml) | Backend | 🐳 Docker Compose ayarları |
| [**nginx.conf**](backend/nginx.conf) | Backend | ⚙️ Nginx konfigürasyonu |
| [**.env.example**](backend/.env.example) | Backend | 🔐 Environment variables template |

---

## 📚 Kaynak Kodları

| Dosya | Konum | Amaç |
|-------|-------|------|
| [**main.py**](backend/main.py) | Backend | 🚀 FastAPI ana dosyası |
| [**requirements.txt**](backend/requirements.txt) | Backend | 📦 Python dependencies |
| [**query_db.py**](backend/query_db.py) | Backend | 🔍 Veritabanı sorgu araçları |

---

## 🎯 Dökümantasyonu Tipe Göre

### 🚀 Başlangıç (İlk 1 saat)
1. [DOCUMENTATION.md](DOCUMENTATION.md) - Genel bakış
2. [SETUP_QUICK_START.md](backend/SETUP_QUICK_START.md) - Hızlı kurulum
3. [DIRECTORY_STRUCTURE.md](backend/DIRECTORY_STRUCTURE.md) - Yapı
4. [TESTING_GUIDE.md](TESTING_GUIDE.md) - API test

### 📚 Öğrenme (Sonraki 2 saat)
1. [DOCKER_NGINX_SETUP.md](backend/DOCKER_NGINX_SETUP.md) - Docker detayları
2. [NGINX_CONFIG_SUMMARY.md](backend/NGINX_CONFIG_SUMMARY.md) - Nginx ayarları
3. [TOKEN_SYSTEM_GUIDE.md](TOKEN_SYSTEM_GUIDE.md) - Token sistemi
4. [LOG_FILES_LOCATION.md](LOG_FILES_LOCATION.md) - Loglar

### 🏭 Production (Sonraki 3 saat)
1. [NGINX_PRODUCTION_SETUP.md](backend/NGINX_PRODUCTION_SETUP.md) - Production deploy
2. [TOKEN_IMPLEMENTATION_SUMMARY.md](TOKEN_IMPLEMENTATION_SUMMARY.md) - Token detayları
3. [PHOTO_STORAGE.md](backend/PHOTO_STORAGE.md) - Dosya yönetimi
4. [docker-troubleshoot.md](backend/docker-troubleshoot.md) - Sorun giderme

---

## 🗺️ Dosya Konumları

```
is_takip/
├── 📑 DOCUMENTATION_INDEX.md      ← Burası (indeks)
├── 📚 DOCUMENTATION.md             ← Ana hub
├── TOKEN_SYSTEM_GUIDE.md
├── TOKEN_IMPLEMENTATION_SUMMARY.md
├── TESTING_GUIDE.md
└── LOG_FILES_LOCATION.md

backend/
├── 📚 DOCS.md                      ← Backend hub
├── README.md
├── SETUP_QUICK_START.md
├── DOCKER_NGINX_SETUP.md
├── DIRECTORY_STRUCTURE.md
├── NGINX_CONFIG_SUMMARY.md
├── NGINX_PRODUCTION_SETUP.md
├── PHOTO_STORAGE.md
├── docker-troubleshoot.md
├── docker-compose.yml
├── nginx.conf
├── main.py
├── requirements.txt
└── query_db.py
```

---

## 🔍 Hızlı Arama

### "Nasıl başlarım?"
→ [SETUP_QUICK_START.md](backend/SETUP_QUICK_START.md)

### "Docker nasıl çalışır?"
→ [DOCKER_NGINX_SETUP.md](backend/DOCKER_NGINX_SETUP.md)

### "Nginx nasıl ayarlanır?"
→ [NGINX_CONFIG_SUMMARY.md](backend/NGINX_CONFIG_SUMMARY.md)

### "Production'da nasıl deploy ederim?"
→ [NGINX_PRODUCTION_SETUP.md](backend/NGINX_PRODUCTION_SETUP.md)

### "Token sistemi nedir?"
→ [TOKEN_SYSTEM_GUIDE.md](TOKEN_SYSTEM_GUIDE.md)

### "API nasıl test ederim?"
→ [TESTING_GUIDE.md](TESTING_GUIDE.md)

### "Logları nerede bulurum?"
→ [LOG_FILES_LOCATION.md](LOG_FILES_LOCATION.md)

### "Dosya nasıl yüklerim?"
→ [PHOTO_STORAGE.md](backend/PHOTO_STORAGE.md)

### "Sorunla karşılaştım!"
→ [docker-troubleshoot.md](backend/docker-troubleshoot.md)

### "Dizin yapısı nedir?"
→ [DIRECTORY_STRUCTURE.md](backend/DIRECTORY_STRUCTURE.md)

---

## 📊 Dokümantasyon İstatistikleri

| Kategori | Dosya Sayısı | Toplam Boyut |
|----------|--------------|--------------|
| Hub | 2 | ~13 KB |
| Setup | 3 | ~30 KB |
| Nginx | 3 | ~60 KB |
| Auth | 2 | ~50 KB |
| Data | 2 | ~40 KB |
| Testing | 2 | ~35 KB |
| **Toplam** | **~16** | **~230 KB** |

---

## 🔄 Cross-Reference Haritası

```
DOCUMENTATION.md (Hub)
├── SETUP_QUICK_START.md
├── DOCKER_NGINX_SETUP.md
├── DIRECTORY_STRUCTURE.md
├── NGINX_CONFIG_SUMMARY.md
├── NGINX_PRODUCTION_SETUP.md
├── TOKEN_SYSTEM_GUIDE.md
├── TOKEN_IMPLEMENTATION_SUMMARY.md
├── LOG_FILES_LOCATION.md
├── TESTING_GUIDE.md
├── PHOTO_STORAGE.md
└── docker-troubleshoot.md

backend/DOCS.md (Backend Hub)
├── SETUP_QUICK_START.md
├── DOCKER_NGINX_SETUP.md
├── DIRECTORY_STRUCTURE.md
├── NGINX_CONFIG_SUMMARY.md
├── NGINX_PRODUCTION_SETUP.md
├── PHOTO_STORAGE.md
└── docker-troubleshoot.md
```

---

## 🎓 Öğrenme Yolları

### Path 1: Hızlı Başlangıç (1 saat)
1. [DOCUMENTATION.md](DOCUMENTATION.md) - 10 min
2. [SETUP_QUICK_START.md](backend/SETUP_QUICK_START.md) - 15 min
3. Docker Compose çalıştır - 15 min
4. [TESTING_GUIDE.md](TESTING_GUIDE.md) - 20 min

### Path 2: Sistem Mimarisi (2 saat)
1. [DOCKER_NGINX_SETUP.md](backend/DOCKER_NGINX_SETUP.md) - 40 min
2. [DIRECTORY_STRUCTURE.md](backend/DIRECTORY_STRUCTURE.md) - 20 min
3. [NGINX_CONFIG_SUMMARY.md](backend/NGINX_CONFIG_SUMMARY.md) - 30 min
4. [LOG_FILES_LOCATION.md](LOG_FILES_LOCATION.md) - 30 min

### Path 3: Kimlik Doğrulama (1 saat)
1. [TOKEN_SYSTEM_GUIDE.md](TOKEN_SYSTEM_GUIDE.md) - 30 min
2. [TOKEN_IMPLEMENTATION_SUMMARY.md](TOKEN_IMPLEMENTATION_SUMMARY.md) - 20 min
3. [TESTING_GUIDE.md](TESTING_GUIDE.md) - 10 min

### Path 4: Production Deploy (2 saat)
1. [NGINX_PRODUCTION_SETUP.md](backend/NGINX_PRODUCTION_SETUP.md) - 60 min
2. [PHOTO_STORAGE.md](backend/PHOTO_STORAGE.md) - 30 min
3. [docker-troubleshoot.md](backend/docker-troubleshoot.md) - 30 min

---

## ✅ Kontrol Listesi

Tüm dökümanlar hazır mı?

- [x] Hub dökümanları (2)
- [x] Setup dökümanları (3)
- [x] Nginx dökümanları (3)
- [x] Auth dökümanları (2)
- [x] Data dökümanları (2)
- [x] Test dökümanları (2)
- [x] Konfigürasyon dosyaları (3)
- [x] Kaynak kodları (3)

---

## 🔗 Hızlı Linkler

### Hub'lar
- 🎯 [Ana Hub](DOCUMENTATION.md)
- 🔧 [Backend Hub](backend/DOCS.md)

### Hızlı
- 🚀 [Başla](backend/SETUP_QUICK_START.md)
- 🧪 [Test](TESTING_GUIDE.md)
- 🔍 [Ara](DOCUMENTATION_INDEX.md)

### İleri
- 🏭 [Production](backend/NGINX_PRODUCTION_SETUP.md)
- 🔐 [Token](TOKEN_SYSTEM_GUIDE.md)
- 🐳 [Docker](backend/DOCKER_NGINX_SETUP.md)

---

## 📝 Son Güncellemeler

| Tarih | Dosya | Değişiklik |
|-------|-------|-----------|
| 2025-11-11 | DOCUMENTATION.md | Oluşturuldu |
| 2025-11-11 | backend/DOCS.md | Oluşturuldu |
| 2025-11-11 | DOCUMENTATION_INDEX.md | Oluşturuldu |

---

## 💡 İpuçları

1. **Hub'lardan başla**: [DOCUMENTATION.md](DOCUMENTATION.md) veya [backend/DOCS.md](backend/DOCS.md)
2. **İndeksi kullan**: Hızlı arama için [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
3. **Cross-reference takip et**: Dosyalar arası linkler takip et
4. **Örnekleri test et**: Her komutu kendi ortamında çalıştır
5. **Güncellemeleri takip et**: Değişiklikleri bu indekste not et

---

## 🚀 Başlayalım

**Hazır mısın?**

→ [DOCUMENTATION.md](DOCUMENTATION.md) - Ana hub'a git

---

**✅ Tüm dökümentasyon organize edildi!** 📚

