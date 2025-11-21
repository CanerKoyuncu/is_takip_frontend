# 📁 Log Dosyaları Konumu

## 🎯 Genel Bakış

Log dosyaları **backend çalıştığında** otomatik olarak `logs/` klasöründe oluşturulur:

```
backend/
├── logs/                    ← Log dosyaları burada
│   ├── app.log              ← Tüm loglar (JSON format)
│   ├── app.log.1            ← Backup (10MB limit)
│   ├── app.log.2
│   ├── error.log            ← Sadece hatalar (JSON format)
│   ├── error.log.1          ← Backup
│   └── error.log.2
├── main.py
├── requirements.txt
├── app/
├── uploads/
└── docker-compose.yml
```

## 📍 Dosya Konumları

### 1. Host Machine'de (Local Development)

```bash
# Backend klasörü içinde
/home/caner/projects/yilbasi/is_takip/backend/logs/

# Log dosyalarını görüntüle
ls -la logs/

# Tüm logları gör
cat logs/app.log

# Hata loglarını gör
cat logs/error.log
```

### 2. Docker Container'da

```bash
# Container'a gir
docker exec -it servis-is-takip-backend bash

# Container içinde log klasörü
cd /app/logs

# Log dosyalarını gör
ls -la
```

### 3. Docker Volume Mapping

`docker-compose.yml`'de:

```yaml
services:
  backend:
    volumes:
      - ./logs:/app/logs  # Host: backend/logs → Container: /app/logs
```

## 📊 Log Dosya Türleri

### app.log
- **İçerik**: Tüm log kayıtları (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- **Format**: JSON (her satır bir JSON object)
- **Boyut**: Max 10MB (otomatik rotate)
- **Backup**: 5 adet (app.log.1 → app.log.5)

```json
{
  "timestamp": "2025-11-11T06:11:41.123456",
  "level": "INFO",
  "message": "📨 INCOMING GET /api/jobs",
  "method": "GET",
  "path": "/api/jobs",
  "client_ip": "172.19.0.1",
  "process_time": "0.022s"
}
```

### error.log
- **İçerik**: Sadece ERROR ve üzeri loglar
- **Format**: JSON
- **Boyut**: Max 10MB (otomatik rotate)
- **Backup**: 5 adet

```json
{
  "timestamp": "2025-11-11T06:17:00.654321",
  "level": "ERROR",
  "message": "❌ REQUEST ERROR GET /api/jobs",
  "error": "Database connection failed",
  "exc_info": "Traceback (most recent call last):\n  ..."
}
```

## 📈 Log Dosya Boyutu

```bash
# Dosya boyutlarını kontrol et
du -sh logs/*

# Örnek output:
# 2.5M   logs/app.log
# 1.2M   logs/app.log.1
# 856K   logs/app.log.2
# 512K   logs/error.log
# 256K   logs/error.log.1
```

## 🔍 Log Dosyaları Nasıl İncelenir?

### 1. Tüm Logları Gör

```bash
# Son 100 satırı gör
tail -100 logs/app.log

# Başından itibaren gör
head -50 logs/app.log

# Tüm dosyayı gör
cat logs/app.log
```

### 2. JSON Format ile İncelemek

```bash
# JSON olarak formatla ve gör (güzel görünüm)
cat logs/app.log | jq .

# Belirli alanları seç
cat logs/app.log | jq '.message, .status_code, .process_time'

# Filtreleme
cat logs/app.log | jq 'select(.status_code == 200)'

# Real-time monitoring
tail -f logs/app.log | jq .
```

### 3. Belirli İsteğleri Ara

```bash
# Login işlemlerini ara
grep "POST /api/auth/login" logs/app.log

# Hata loglarında ara
grep "ERROR" logs/error.log

# Status code 401 ara
grep "status_code.*401" logs/app.log

# Belirli user-agent ara
grep "Dart" logs/app.log
```

### 4. Log Analizi

```bash
# Belirli tarih/saati ara
grep "2025-11-11T06:1" logs/app.log

# İşlem süresi yavaş olanları ara (>100ms)
grep -E "process_time.*0\.[1-9][0-9]" logs/app.log

# Başarısız requestleri ara
grep "status_code.*401" logs/app.log
grep "status_code.*500" logs/app.log

# Tüm hataları ara
cat logs/error.log | wc -l  # Kaç hata var?
```

## 🚀 Log Dosyaları Okunuyor mu?

### Debug Mode (Development)

```bash
# Docker log'ları canlı olarak izle
docker logs -f servis-is-takip-backend

# Örnek çıktı:
# 2025-11-11 06:11:41 - main - INFO - 📨 INCOMING GET /api/jobs
#   📌 method: GET, path: /api/jobs, client: 172.19.0.1
```

### Log Dosyalarını Real-Time İzle

```bash
# Tüm logları canlı olarak izle
tail -f logs/app.log | jq .

# Sadece hataları canlı izle
tail -f logs/error.log | jq .

# Belirli endpoint'i canlı izle
tail -f logs/app.log | grep "POST /api/auth/login"
```

## 📅 Log Rotasyonu

### Nasıl Çalışır?

```
app.log → (10MB ulaşınca) → app.log.1
app.log.1 → (10MB ulaşınca) → app.log.2
...
app.log.4 → (10MB ulaşınca) → app.log.5
app.log.5 → (10MB ulaşınca) → SILINIR
```

### İstatistikler

- **Dosya başına**: 10MB
- **Backup sayısı**: 5
- **Toplam kapasite**: ~60MB

## 🧹 Log Yönetimi

### Log Dosyaları Silme

```bash
# Eski backup dosyalarını sil
rm logs/app.log.3 logs/app.log.4 logs/app.log.5

# Hata loglarını sil
rm logs/error.log

# Tüm logları sil (uyarı!)
rm -rf logs/*
```

### Log Arşivleme

```bash
# Günlük logları arşivle
tar -czf logs/archive/logs-$(date +%Y-%m-%d).tar.gz logs/app.log logs/error.log

# Arşiv klasörü oluştur
mkdir -p logs/archive

# Eski logları arşivle ve sil
tar -czf logs/archive/logs-backup-$(date +%s).tar.gz logs/*.log.*
rm logs/*.log.[1-9]*
```

### Otomatik Temizlik (Cron)

```bash
# Crontab düzenle
crontab -e

# 30 günden eski logları otomatik sil (haftada 1 kez çalışacak)
0 0 * * 0 find /home/caner/projects/yilbasi/is_takip/backend/logs -name "*.log*" -mtime +30 -delete
```

## 🔗 Docker'da Log Erişimi

### Yöntemi 1: Docker Volume

```bash
# logs/ klasörü host machine'de görünür
ls -la backend/logs/

# Docker'da
docker-compose exec backend ls -la /app/logs/
```

### Yöntemi 2: Docker Log Command

```bash
# Container loglarını gör (stdout)
docker logs servis-is-takip-backend

# Son 100 satırı gör
docker logs servis-is-takip-backend | tail -100

# Canlı izle
docker logs -f servis-is-takip-backend
```

### Yöntemi 3: Container'a Girerek

```bash
# Container'a bağlan
docker exec -it servis-is-takip-backend bash

# Log dosyalarını gör
cd /app/logs
ls -la
cat app.log | jq .

# Çık
exit
```

## 📊 Örnek Komutlar

### Development'ta

```bash
# Terminal 1: Backend'i çalıştır
cd backend
docker-compose up

# Terminal 2: Log dosyasını canlı izle
tail -f backend/logs/app.log | jq .

# Terminal 3: Belirli endpoint'i izle
tail -f backend/logs/app.log | grep "POST /api"
```

### Production'da

```bash
# Günlük log raporunu oluştur
grep "$(date +%Y-%m-%d)" logs/app.log | jq -s '{
  total: length,
  errors: map(select(.level == "ERROR")) | length,
  warnings: map(select(.level == "WARNING")) | length,
  success_rate: ((map(select(.status_code >= 200 and .status_code < 300)) | length) / length * 100)
}'

# Hata sayısını kontrol et
grep "ERROR" logs/error.log | wc -l
```

## 🎯 Log Dosyalarının Konumu Özeti

| Ortam | Konumu |
|-------|--------|
| **Local Development** | `/home/caner/projects/yilbasi/is_takip/backend/logs/` |
| **Docker Container** | `/app/logs/` |
| **Docker Volume** | `backend/logs/` (host'tan erişilebilir) |
| **File Type** | JSON (her satır bir log object) |
| **Dosyalar** | `app.log`, `app.log.1-5`, `error.log`, `error.log.1-5` |

## ✅ Kontrol Listesi

- ✅ Log dosyaları otomatik oluşturulur
- ✅ JSON formatında saklanır
- ✅ Rotating file handler ile boyut kontrol edilir
- ✅ 5 backup dosya tutulur
- ✅ Console'da da görülebilir
- ✅ Docker volume mapping ile host'tan erişilebilir

---

**Log dosyaları `logs/` klasöründe güvenli şekilde saklanıyor!** 📁

