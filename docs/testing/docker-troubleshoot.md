# Docker Hub Bağlantı Sorunu Çözümleri

## Hızlı Çözümler

### 1. Docker Daemon'ı Yeniden Başlat
```bash
sudo systemctl restart docker
```

### 2. DNS Ayarlarını Düzelt
```bash
# Docker daemon config dosyasını oluştur/düzenle
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
```

İçeriğe şunu ekleyin:
```json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```

Sonra Docker'ı yeniden başlatın:
```bash
sudo systemctl restart docker
```

### 3. Manuel Image Çekme
```bash
# Önce Python image'ını manuel çekin
sudo docker pull python:3.11-slim

# Sonra build edin
sudo docker compose up --build -d
```

### 4. Proxy Kullanıyorsanız
Eğer proxy kullanıyorsanız, Docker'a proxy ayarları ekleyin:
```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo nano /etc/systemd/system/docker.service.d/http-proxy.conf
```

İçeriğe şunu ekleyin:
```ini
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1"
```

Sonra:
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 5. Alternatif: Image'ı Önceden Çek
```bash
# Başka bir makinede veya internet bağlantısı olan yerde:
docker pull python:3.11-slim
docker save python:3.11-slim | gzip > python-3.11-slim.tar.gz

# Bu makineye transfer edip:
gunzip -c python-3.11-slim.tar.gz | sudo docker load
```

## Test
```bash
# Docker Hub bağlantısını test edin
sudo docker pull hello-world

# Başarılı olursa build edin
cd /home/caner/projects/yilbasi/is_takip/backend
sudo docker compose up --build -d
```
