# Fotoğraf Saklama Sistemi

## Genel Bakış

API fotoğrafları **gerçek dosya sistemi** üzerinde saklar. MongoDB sadece metadata (yol, boyut, hash, vb.) için kullanılır.

## Saklama Yapısı

### 1. Docker Volume (Persistent Storage)

Fotoğraflar Docker volume'unda saklanır:
- **Volume adı**: `photos_data`
- **Container içi yol**: `/app/uploads`
- **Persistent**: Container silinse bile fotoğraflar korunur

### 2. Klasör Organizasyonu

```
/app/uploads/                          # Container içi base dizin
├── jobs/                              # Aktif fotoğraflar
│   └── {job_id}/                      # Job ID'ye göre
│       └── tasks/
│           └── {task_id}/             # Task ID'ye göre
│               ├── damage/            # Hasar fotoğrafları
│               │   └── 20240101_120000_abc123.jpg
│               ├── completion/        # Tamamlanma fotoğrafları
│               │   └── 20240101_130000_def456.jpg
│               └── other/             # Diğer fotoğraflar
│                   └── 20240101_140000_ghi789.jpg
├── thumbnails/                        # Thumbnail'ler (aynı yapı)
│   └── jobs/
│       └── {job_id}/
│           └── tasks/
│               └── {task_id}/
│                   └── {photo_type}/
│                       └── thumbnails...
├── archive/                           # Arşivlenmiş fotoğraflar
│   └── {year}/
│       └── {month}/
│           └── {job_id}/
│               └── {task_id}/
│                   └── archived_photos...
└── backups/                           # Yedekler
    └── {backup_name}/
        ├── jobs/
        ├── thumbnails/
        └── archive/
```

## Fotoğraf Yükleme Akışı

### 1. İstemci → API
```http
POST /api/jobs/{job_id}/tasks/{task_id}/photos
Content-Type: multipart/form-data
X-API-Key: {api_key}

file: [binary image data]
photo_type: "damage"
```

### 2. API İşlemleri

1. **Validasyon**:
   - Dosya tipi kontrolü (JPEG, PNG, WebP)
   - Dosya boyutu kontrolü (max 10 MB)
   - Resim boyutları kontrolü (max 4000x4000px)
   - Dosya içeriği kontrolü (PIL ile)

2. **Dosya Kaydetme**:
   ```python
   # Klasör oluştur
   /app/uploads/jobs/{job_id}/tasks/{task_id}/damage/
   
   # Dosya adı oluştur (timestamp + UUID)
   20240101_120000_abc123.jpg
   
   # Dosyayı kaydet
   /app/uploads/jobs/{job_id}/tasks/{task_id}/damage/20240101_120000_abc123.jpg
   ```

3. **Thumbnail Oluşturma**:
   ```python
   # Thumbnail oluştur (300x300px)
   /app/uploads/thumbnails/jobs/{job_id}/tasks/{task_id}/damage/20240101_120000_abc123.jpg
   ```

4. **Metadata Kaydetme** (MongoDB):
   ```json
   {
     "_id": ObjectId("..."),
     "path": "jobs/{job_id}/tasks/{task_id}/damage/20240101_120000_abc123.jpg",
     "thumbnailPath": "thumbnails/jobs/{job_id}/tasks/{task_id}/damage/20240101_120000_abc123.jpg",
     "type": "damage",
     "filename": "original_name.jpg",
     "size": 2048576,
     "hash": "sha256_hash_here",
     "createdAt": ISODate("2024-01-01T12:00:00Z"),
     "archived": false
   }
   ```

## Fotoğraf Erişimi

### 1. Orijinal Fotoğraf
```http
GET /api/jobs/{job_id}/tasks/{task_id}/photos/{photo_id}
X-API-Key: {api_key}
```

**Akış**:
1. MongoDB'den fotoğraf metadata'sını al
2. `path` alanından dosya yolunu oku
3. `/app/uploads/{path}` dosyasını oku
4. `FileResponse` ile gönder

### 2. Thumbnail
```http
GET /api/jobs/{job_id}/tasks/{task_id}/photos/{photo_id}/thumbnail
X-API-Key: {api_key}
```

**Akış**:
1. MongoDB'den fotoğraf metadata'sını al
2. `thumbnailPath` alanından thumbnail yolunu oku
3. `/app/uploads/{thumbnailPath}` dosyasını oku
4. `FileResponse` ile gönder

## Docker Volume Yönetimi

### Volume Konumu

```bash
# Volume bilgilerini görüntüle
docker volume inspect servis-is-takip_photos_data

# Çıktı:
# {
#   "Mountpoint": "/var/lib/docker/volumes/servis-is-takip_photos_data/_data"
# }
```

### Volume'a Erişim

```bash
# Volume içeriğini görüntüle
docker run --rm \
  -v servis-is-takip_photos_data:/data \
  ubuntu ls -la /data

# Volume'u yedekle
docker run --rm \
  -v servis-is-takip_photos_data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar czf /backup/photos-backup-$(date +%Y%m%d).tar.gz /data

# Volume'u geri yükle
docker run --rm \
  -v servis-is-takip_photos_data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar xzf /backup/photos-backup-20240101.tar.gz -C /data
```

## Örnek Kullanım

### Fotoğraf Yükleme

```bash
curl -X POST \
  -H "X-API-Key: your-api-key" \
  -F "file=@photo.jpg" \
  -F "photo_type=damage" \
  http://localhost:4000/api/jobs/507f1f77bcf86cd799439011/tasks/507f191e810c19729de860ea/photos
```

**Yanıt**:
```json
{
  "success": true,
  "message": "Photo uploaded successfully",
  "data": {
    "photoId": "507f1f77bcf86cd799439012",
    "path": "jobs/507f1f77bcf86cd799439011/tasks/507f191e810c19729de860ea/damage/20240101_120000_abc123.jpg"
  }
}
```

### Fotoğraf İndirme

```bash
curl -H "X-API-Key: your-api-key" \
  http://localhost:4000/api/jobs/507f1f77bcf86cd799439011/tasks/507f191e810c19729de860ea/photos/507f1f77bcf86cd799439012 \
  --output photo.jpg
```

### Thumbnail İndirme

```bash
curl -H "X-API-Key: your-api-key" \
  http://localhost:4000/api/jobs/507f1f77bcf86cd799439011/tasks/507f191e810c19729de860ea/photos/507f1f77bcf86cd799439012/thumbnail \
  --output thumbnail.jpg
```

## Güvenlik

1. **Dosya Validasyonu**: Sadece resim dosyaları kabul edilir
2. **Path Traversal Koruması**: Dosya adları sanitize edilir
3. **API Key Authentication**: Tüm endpoint'ler korumalı
4. **Rate Limiting**: Dakikada 60, saatte 1000 istek limiti
5. **Dosya Hash**: SHA256 hash ile bütünlük kontrolü

## Avantajlar

1. **Gerçek Dosya Sistemi**: Fotoğraflar gerçek dosya olarak saklanır
2. **Persistent Storage**: Docker volume ile kalıcı saklama
3. **Organize Yapı**: Job/Task bazlı klasör organizasyonu
4. **Thumbnail Desteği**: Performans için otomatik thumbnail
5. **Arşivleme**: Eski fotoğrafları arşivleme desteği
6. **Yedekleme**: Kolay yedekleme ve geri yükleme

## Notlar

- Fotoğraflar MongoDB'de **değil**, dosya sisteminde saklanır
- MongoDB sadece metadata (yol, boyut, hash) için kullanılır
- Docker volume sayesinde container silinse bile fotoğraflar korunur
- Fotoğraflar API endpoint'leri üzerinden erişilir (doğrudan dosya erişimi yok)

