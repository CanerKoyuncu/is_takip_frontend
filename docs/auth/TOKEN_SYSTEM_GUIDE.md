# Otomatik Token Yönetim Sistemi

## 🔒 Genel Bakış

Bu sistem **HttpOnly cookies** kullanarak JWT token'larını otomatik olarak yönetir. Token'lar:
- ✅ Client-side'de saklanmaz
- ✅ Otomatik olarak refresh'lenir
- ✅ Hata durumunda otomatik cleanup yapılır
- ✅ XSS ve CSRF saldırılarına karşı korunur

## 🏗️ Sistem Mimarisi

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│  AuthProvider (State Management)                                │
│  ├─ checkAuthStatus()    - App startup'ta çalışır              │
│  ├─ login()              - Login işlemini yönetir              │
│  ├─ logout()             - Logout ve cleanup                    │
│  └─ isAuthenticated      - Auth durumunu gösterir              │
└────────────┬──────────────────────────────────────────────────┬─┘
             │                                                    │
         ┌───▼────────────────────────────┐                     │
         │     ApiService                  │                     │
         ├─────────────────────────────────┤                     │
         │ Interceptors:                   │                     │
         │ 1. API Key injection            │                     │
         │ 2. 401 → Auto token refresh     │                     │
         │ 3. Error handling & logging     │                     │
         │ 4. Cookie management (Dio)      │                     │
         └────────┬───────────────────────┘                     │
                  │                                              │
    ┌─────────────▼──────────────────────────────────────────┐  │
    │            Backend (Python/FastAPI)                    │  │
    ├───────────────────────────────────────────────────────┤  │
    │  JWT Middleware (Auto Token Validation)                │  │
    │  ├─ Authorization Header → Token kontrol              │  │
    │  └─ Cookie → Token kontrol                            │  │
    │                                                        │  │
    │  Auth Endpoints:                                       │  │
    │  ├─ POST /auth/login    → Set-Cookie (tokens)         │  │
    │  ├─ POST /auth/register → Set-Cookie (tokens)         │  │
    │  ├─ POST /auth/refresh  → Set-Cookie (new access_token)
    │  └─ POST /auth/logout   → Clear cookies               │  │
    │                                                        │  │
    │  Protected Endpoints:                                  │  │
    │  └─ /api/* → JWT Middleware validates               │  │
    └───────────────────────────────────────────────────────┘  │
                                                                │
                         HttpOnly Cookies                        │
                         (Tarayıcı/Device yönetir)              │
                         - access_token  (30 min)               │
                         - refresh_token (7 days)               │
```

## 📱 Frontend Bileşenleri

### 1. ApiService (lib/core/services/api_service.dart)

**Sorumlulukları:**
- Tüm HTTP isteklerini yönetir
- Cookies otomatik olarak gönderilir
- 401 hatalarında otomatik token refresh
- Detaylı hata logging

**Interceptors:**
```dart
1. onRequest
   - X-API-Key header'ını ekler
   - Request'i log'lar

2. onError (Auto Retry on 401)
   - 401 hatası → POST /auth/refresh
   - Refresh başarılı → Orijinal request tekrar dene
   - Refresh başarısız → Hata return et

3. Error Handler
   - Exception'ları Türkçe mesajlara dönüştürür
   - Debug logging yapar
```

### 2. AuthApiService (lib/core/services/auth_api_service.dart)

**Metodlar:**
- `login()` - Kullanıcı girişi, cookies otomatik set
- `register()` - Kullanıcı kaydı, cookies otomatik set
- `refreshToken()` - Token yenileme (cookies'den otomatik)
- `getCurrentUser()` - Mevcut user info
- `logout()` - Logout ve cookies temizleme

**Token Yönetimi:**
- Tokens artık TokenStorageService'de saklanmaz
- Tüm yönetim Dio ve backend tarafından yapılır

### 3. AuthProvider (lib/features/auth/providers/auth_provider.dart)

**State Management:**
- `_isAuthenticated` - Giriş durumu
- `_isLoading` - İşlem durumu
- `_user` - Kullanıcı bilgileri
- `_errorMessage` - Hata mesajı

**Metodlar:**
```dart
// App startup'ta çağrılır
checkAuthStatus()
├─ API'ye istek gönder (/auth/me)
├─ Cookie varsa otomatik gönderilir
├─ Başarılı → Kullanıcı giriş yapmış
└─ Başarısız → Giriş yapılmamış

// Giriş işlemi
login(username, password)
├─ POST /auth/login gönder
├─ Cookies otomatik set edilir
├─ State güncelle
└─ Router yönlendir

// Çıkış işlemi
logout()
├─ POST /auth/logout çağır
├─ Cookies silinir
├─ State temizle
└─ Router login'e yönlendir
```

## 🔐 Backend İşlemi

### Login / Register Endpoints

```python
@router.post("/login")
async def login(credentials: UserLoginRequest):
    # 1. Kullanıcı doğrula
    user = authenticate_user(...)
    
    # 2. Token'ları oluştur
    tokens = create_tokens_for_user(username)
    
    # 3. Set-Cookie headers ile gönder
    response = LoginResponse(...)
    response.set_cookie("access_token", ..., httponly=True, secure=True)
    response.set_cookie("refresh_token", ..., httponly=True, secure=True)
    
    return response
```

### JWT Middleware

```python
class JWTAuthMiddleware:
    async def dispatch(request):
        # 1. Authorization header'dan kontrol et
        if auth_header and token:
            validate_token(token)
        
        # 2. Cookie'den kontrol et (backup)
        elif access_token_cookie:
            validate_token(access_token_cookie)
        
        # 3. Token geçersizse bağlantı kes
        else:
            drop_connection()
```

### Refresh Endpoint

```python
@router.post("/auth/refresh")
async def refresh_token(credentials: HTTPAuthorizationCredentials):
    # 1. Refresh token doğrula
    # 2. Yeni access_token oluştur
    # 3. Set-Cookie ile gönder
    # 4. Cookies otomatik güncellenir
```

### Logout Endpoint

```python
@router.post("/auth/logout")
async def logout():
    # 1. Cookies silinmesini trigger et
    response.set_cookie("access_token", "", max_age=0, ...)
    response.set_cookie("refresh_token", "", max_age=0, ...)
    
    # 2. Frontend cookies'leri temizler
    return response
```

## 🔄 İş Akışları

### 1️⃣ Uygulama Başlangıcı

```
App Start
    ↓
_initializeApp() [app.dart]
    ├─ ApiService oluştur
    ├─ AuthApiService oluştur
    ├─ AuthProvider oluştur
    └─ checkAuthStatus() çağır
        └─ GET /auth/me (cookies ile)
            ├─ Başarılı → Giriş yapılmış
            └─ Başarısız → Login ekranı
```

### 2️⃣ Login Akışı

```
User tıklar "Giriş Yap"
    ↓
login() [auth_provider.dart]
    ├─ POST /auth/login
    │   └─ Body: {username, password}
    ├─ Server döner: Set-Cookie headers
    │   ├─ access_token (30 min)
    │   └─ refresh_token (7 days)
    ├─ Dio: Cookies otomatik kaydeder
    ├─ AuthProvider state günceller
    └─ Router dashboard'a yönlendir
```

### 3️⃣ API Request Akışı

```
Widget → ApiService.get("/api/jobs")
    ↓
Dio Interceptor (onRequest)
    ├─ X-API-Key header ekle
    └─ Cookies otomatik ekle
        └─ Cookie Manager tarafından
    ↓
Request gönder
    ├─ Authorization header: None (cookies'den gelir)
    └─ Cookie: access_token=xxx
    ↓
Backend: JWT Middleware
    ├─ Cookie'den token kontrol
    ├─ Token geçerli → İstek işle
    └─ Response gönder
```

### 4️⃣ Token Expired (401) Akışı

```
API Request
    ↓
Server: 401 Unauthorized
    └─ Access token expired
    ↓
Dio Interceptor (onError)
    ├─ 401 Status Code kontrol
    ├─ POST /auth/refresh
    │   └─ Cookies: refresh_token otomatik gönder
    ├─ Server: Yeni access_token Set-Cookie ile gönder
    ├─ Dio: Cookies günceller
    ├─ Orijinal request tekrar dene
    │   └─ Yeni token ile
    └─ Response başarılı
```

### 5️⃣ Logout Akışı

```
User tıklar "Çıkış"
    ↓
logout() [auth_provider.dart]
    ├─ POST /auth/logout
    │   └─ Response: Set-Cookie max_age=0
    ├─ Dio: Cookies temizler
    ├─ AuthProvider state temizle
    │   ├─ _isAuthenticated = false
    │   ├─ _user = null
    │   └─ _errorMessage = null
    └─ Router login'e yönlendir
```

## 🛡️ Güvenlik Özellikleri

### HttpOnly Cookies
- ✅ **httpOnly=true**: JavaScript erişemez (XSS koruması)
- ✅ **secure=true**: Yalnızca HTTPS üzerinden (taşıma güvenliği)
- ✅ **sameSite=lax**: CSRF saldırılarına karşı koruma
- ✅ **path="/"**: Tüm rotalar için geçerli

### Backend Güvenliği
- ✅ Geçersiz token → Silent connection drop (bilgi sızdırmaz)
- ✅ Refresh token API'ye kullanılamaz (type kontrolü)
- ✅ Token expiry otomatik kontrol
- ✅ Logging ve audit trail

## 📊 Debug Console Mesajları

### Başarılı Akışlar

```
🍪 Cookies will be managed automatically by Dio
🔄 Request: GET /api/jobs
🚪 Logging out user...
✅ Logout successful
✅ Token refreshed successfully
✅ Retry successful
```

### Hata Durumları

```
❌ Error: badResponse - 401 Unauthorized
  ➜ HTTP 401: Token expired
⚠️ 401 Unauthorized - Attempting token refresh
❌ Token refresh failed: 403
  ➜ HTTP 403: Forbidden
🚪 Logging out user...
⚠️ Logout error: Connection refused
```

## 🔧 Yapılandırma

### Backend (.env)

```env
JWT_SECRET_KEY=your-secret-key-change-this
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7
NODE_ENV=production
```

### CORS Ayarları

```python
# main.py
CORSMiddleware(
    allow_origins=["http://localhost:3000", "https://yourdomain.com"],
    allow_credentials=True,  # IMPORTANT for cookies
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)
```

### Dio Configuration

```dart
// ApiService constructor
BaseOptions(
  baseUrl: 'http://localhost:4000/api',
  validateStatus: (status) => true,  // Tüm status kodları kabul
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
)
```

## 🧪 Test Etme

### Login Test

```bash
# 1. Login
curl -v -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"pass123"}' \
  -c cookies.txt

# 2. Protected endpoint'e istek
curl -v http://localhost:4000/api/jobs \
  -H "X-API-Key: your-key" \
  -b cookies.txt

# 3. Logout
curl -X POST http://localhost:4000/api/auth/logout \
  -b cookies.txt \
  -c cookies.txt
```

## ⚠️ Sık Karşılaşılan Sorunlar

### Problem: Cookies gönderilmiyor

**Çözüm:**
```python
# CORS settings kontrol et
CORSMiddleware(
    allow_credentials=True,  # REQUIRED
    ...
)

# Secure flag production'da
# Development'da disable edebilirsin
response.set_cookie(..., secure=False)
```

### Problem: Token refresh sonsuz loop

**Çözüm:**
```dart
// Refresh endpoint'in token gerektirmediğinden emin ol
skip_paths = [..., "/api/auth/refresh", ...]

// Refresh token'ı kontrol et
if (payload.get("type") != "refresh"):
    drop_connection()
```

### Problem: Logout sonrası cookies kalıyor

**Çözüm:**
```python
response.set_cookie(
    key="access_token",
    value="",
    max_age=0,  # IMPORTANT - hemen sil
    httponly=True,
    secure=True,
    samesite="lax",
    path="/"
)
```

## 📈 Performans

- ✅ **Fast**: API Key injection minimal overhead
- ✅ **Efficient**: Token refresh sadece gerektiğinde
- ✅ **Reliable**: Auto-retry 401 errors
- ✅ **Responsive**: User experience geri kalmıyor

## 🎯 Sonraki Adımlar

1. **Production Deploy**
   - HTTPS enforced
   - Secure flags enabled
   - CORS properly configured

2. **Monitoring**
   - Log token refresh counts
   - Monitor 401 error rates
   - Alert on unusual patterns

3. **Enhancement**
   - Multi-device logout
   - Token revocation lists
   - Rate limiting on refresh

