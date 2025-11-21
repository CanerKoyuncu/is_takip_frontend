# 🔧 Nginx Production Konfigürasyonu

> **Not:** Bu dosya, production ortamında backend'in önüne Nginx proxy koyarken kullanılacak referans konfigürasyonudur. Docker Compose'ta Nginx çalıştırılmamaktadır.

## 📋 İçindekiler
- [Genel Bakış](#genel-bakış)
- [Nginx Kurulumu](#nginx-kurulumu)
- [Konfigürasyon Dosyası](#konfigürasyon-dosyası)
- [SSL Sertifikası](#ssl-sertifikası)
- [Sistem Hizmetleri](#sistem-hizmetleri)
- [Loglar ve Monitoring](#loglar-ve-monitoring)

## 🎯 Genel Bakış

Production ortamında aşağıdaki yapı kullanılır:

```
User (External) 
    ↓
Nginx (Port 80/443) - Reverse Proxy
    ├─ SSL/HTTPS termination
    ├─ Rate limiting
    ├─ Security headers
    └─ Client IP forwarding
    ↓
Backend (Port 4000) - FastAPI
    ├─ Logs: logs/app.log, logs/error.log
    ├─ Uploads: uploads/
    └─ Database: MongoDB
```

## 🚀 Nginx Kurulumu

### Ubuntu/Debian

```bash
# Paket yöneticisini güncelle
sudo apt update && sudo apt upgrade -y

# Nginx yükle
sudo apt install -y nginx certbot python3-certbot-nginx

# Nginx'in çalışıp çalışmadığını kontrol et
sudo systemctl status nginx

# Nginx'i etkinleştir (boot'ta otomatik başlat)
sudo systemctl enable nginx
```

### CentOS/RHEL

```bash
# EPEL repository ekle
sudo yum install -y epel-release

# Nginx yükle
sudo yum install -y nginx certbot python3-certbot-nginx

# Nginx'i başlat ve etkinleştir
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```

## 📄 Konfigürasyon Dosyası

### 1. Dosyayı Kopyala

```bash
# Production server'a nginx.conf'u kopyala
scp backend/nginx.conf user@server:/tmp/nginx.conf

# Server'da
sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf
```

### 2. Önemli Ayarlamalar

`/etc/nginx/nginx.conf` içinde şu satırları kontrol et:

#### A. Backend Sunucusunun Adresi
```nginx
upstream backend {
    server 127.0.0.1:4000;  # Local: Docker container veya local service
    # VEYA
    server 192.168.1.100:4000;  # Remote: Başka server'daki backend
    keepalive 64;
}
```

#### B. Domain Adı
```nginx
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;  # Kendi domain'ini yaz
    
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
}
```

#### C. Rate Limiting (İsteğe Bağlı)
```nginx
# API endpoint'leri: 100 req/s (limit ise burst=200)
limit_req_zone $http_x_forwarded_for zone=api_limit:10m rate=100r/s;

# Auth endpoint'leri: 10 req/s (limit ise burst=5)
limit_req_zone $http_x_forwarded_for zone=auth_limit:10m rate=10r/s;
```

### 3. Syntax Kontrolü

```bash
# Nginx konfigürasyonunu kontrol et
sudo nginx -t

# Output:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration will be tested successfully
```

### 4. Nginx'i Yeniden Başlat

```bash
# Soft reload (connections'ları bozmadan yeniden yükle)
sudo systemctl reload nginx

# Veya restart et
sudo systemctl restart nginx

# Durumu kontrol et
sudo systemctl status nginx
```

## 🔐 SSL Sertifikası

### Let's Encrypt (Ücretsiz)

#### Otomatik Kurulum

```bash
# Certbot ile otomatik SSL kurulumu
sudo certbot --nginx -d example.com -d www.example.com

# İnteraktif kurulum adımlarını takip et
```

#### Manuel Kurulum

```bash
# Sertifika oluştur
sudo certbot certonly --standalone -d example.com -d www.example.com

# Nginx.conf'da yol güncelle
# ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
# ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

# Nginx'i yeniden başlat
sudo systemctl reload nginx
```

#### Otomatik Yenileme

```bash
# Certbot timer'ı kontrol et (otomatik olarak ayarlanır)
sudo systemctl status certbot.timer

# Manuel test et
sudo certbot renew --dry-run

# Log'ları kontrol et
sudo journalctl -u certbot.timer -f
```

### Self-Signed Sertifika (Development)

```bash
# Self-signed sertifika oluştur
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/nginx-selfsigned.key \
  -out /etc/nginx/ssl/nginx-selfsigned.crt \
  -subj "/CN=localhost"

# Permissions
sudo chmod 600 /etc/nginx/ssl/nginx-selfsigned.*

# Nginx.conf'da
ssl_certificate /etc/nginx/ssl/nginx-selfsigned.crt;
ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;
```

## 🔍 nginx.conf Detayları

### Header Forwarding

Backend'e şu header'lar iletilir:

```nginx
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Port $server_port;
```

Backend'de log'larda görülür:

```
Client IP: 192.168.1.100
X-Forwarded-For: 192.168.1.100
X-Forwarded-Proto: https
```

### Rate Limiting

API endpoint'lerine karşı DDoS saldırısını önle:

```nginx
# Zone tanımı
limit_req_zone $http_x_forwarded_for zone=api_limit:10m rate=100r/s;

# Kullanım
location /api/ {
    limit_req zone=api_limit burst=200 nodelay;
    ...
}
```

### Security Headers

```nginx
# HTTPS zorunluluğu (1 yıl)
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# Content-Type sniffing'ini önle
add_header X-Content-Type-Options "nosniff" always;

# Clickjacking saldırılarını önle
add_header X-Frame-Options "SAMEORIGIN" always;

# XSS saldırılarını önle
add_header X-XSS-Protection "1; mode=block" always;

# Referrer policy
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### CORS Headers

```nginx
add_header 'Access-Control-Allow-Origin' '*' always;
add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, PATCH, DELETE, OPTIONS' always;
add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-API-Key' always;
```

### Gzip Compression

```nginx
gzip on;
gzip_types text/plain application/json;
gzip_comp_level 6;
```

## 📊 Sistem Hizmetleri

### Nginx Kontrolü

```bash
# Durum kontrol et
sudo systemctl status nginx

# Başlat
sudo systemctl start nginx

# Durdur
sudo systemctl stop nginx

# Yeniden başlat
sudo systemctl restart nginx

# Soft reload
sudo systemctl reload nginx

# Boot'ta otomatik başlat
sudo systemctl enable nginx

# Boot'ta otomatik başlat'ı kaldır
sudo systemctl disable nginx
```

### Log'ları İzle

```bash
# Nginx access log (real-time)
sudo tail -f /var/log/nginx/access.log

# Nginx error log
sudo tail -f /var/log/nginx/error.log

# Belirli kayıtları ara
sudo grep "POST /api/auth/login" /var/log/nginx/access.log

# Log dosyası boyutu
sudo wc -l /var/log/nginx/access.log

# Status code dağılımı
sudo awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn
```

## 🔍 Loglar ve Monitoring

### Nginx Log Formatı

```
192.168.1.100 - [11/Nov/2025:14:30:22 +0000] "GET /api/jobs HTTP/2.0" 200 1024
X-Forwarded-For: "192.168.1.100" X-Forwarded-Proto: "https" X-Forwarded-Host: "example.com" 
Request-Time: 0.022
```

### Backend Log'ları

```bash
# Docker container logs
docker logs servis-is-takip-backend

# Docker container logs (real-time)
docker logs -f servis-is-takip-backend

# Log dosyaları
cat backend/logs/app.log | jq .
cat backend/logs/error.log | jq .

# Canlı izle
tail -f backend/logs/app.log | jq .
```

### Performance Monitoring

```bash
# Nginx worker process sayısı
ps aux | grep "[n]ginx"

# Connection sayısı
netstat -an | grep :443 | wc -l

# Memory/CPU usage
top -p $(pgrep -f nginx | tr '\n' ',')
```

## ⚙️ Production Checklist

```bash
# 1. Nginx kurulumu
✅ sudo apt install nginx certbot python3-certbot-nginx

# 2. Konfigürasyon
✅ sudo cp backend/nginx.conf /etc/nginx/nginx.conf
✅ sudo nginx -t

# 3. SSL Sertifikası
✅ sudo certbot --nginx -d example.com
✅ openssl x509 -in /etc/letsencrypt/live/example.com/cert.pem -text -noout

# 4. Firewall
✅ sudo ufw allow 22/tcp    # SSH
✅ sudo ufw allow 80/tcp    # HTTP
✅ sudo ufw allow 443/tcp   # HTTPS
✅ sudo ufw enable

# 5. Nginx başlat
✅ sudo systemctl start nginx
✅ sudo systemctl enable nginx
✅ sudo systemctl status nginx

# 6. Backend kontrol
✅ curl http://localhost:4000/health
✅ curl https://localhost/api/jobs -k

# 7. Log'ları izle
✅ sudo tail -f /var/log/nginx/access.log
✅ tail -f backend/logs/app.log | jq .
```

## 🐛 Sorun Giderme

### Nginx başlamadıysa

```bash
# Syntax kontrol et
sudo nginx -t

# Port alındı mı kontrol et
sudo lsof -i :80
sudo lsof -i :443

# Nginx logs kontrol et
sudo tail -50 /var/log/nginx/error.log
```

### SSL sertifikası sorunu

```bash
# Sertifika bilgisini kontrol et
sudo openssl x509 -in /etc/letsencrypt/live/example.com/cert.pem -text -noout

# Expiration tarihi kontrol et
sudo certbot certificates

# Renewal test et
sudo certbot renew --dry-run
```

### Backend bağlanamıyorsa

```bash
# Backend çalışıyor mu?
curl http://127.0.0.1:4000/health

# Nginx logs kontrol et
sudo tail -f /var/log/nginx/error.log

# Backend logs kontrol et (if Docker)
docker logs servis-is-takip-backend
```

### Client IP yanlış görünüyorsa

```bash
# Nginx header'larını gönderdiğini kontrol et
sudo grep "X-Forwarded-For" /var/log/nginx/access.log

# Backend log'unda client IP'yi kontrol et
tail -f backend/logs/app.log | grep -i "client"
```

## 📝 Referans Komutları

```bash
# Server'a nginx.conf kopyala
scp backend/nginx.conf user@server:/tmp/
ssh user@server "sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf && sudo nginx -t && sudo systemctl reload nginx"

# Nginx yeniden başlat
ssh user@server "sudo systemctl restart nginx"

# Log'ları izle
ssh user@server "sudo tail -f /var/log/nginx/access.log"

# Certbot yenileme
ssh user@server "sudo certbot renew --force-renewal"
```

---

**✅ Production Nginx konfigürasyonu hazır!** 🚀

