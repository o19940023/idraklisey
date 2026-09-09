# ✅ İDRAK WEB SİTE - CONFIRMED TEXNİKİ MƏLUMATLAR

**Tarix:** 07.09.2026  
**Source:** Browser Network Headers Analysis

---

## 🌐 SERVER LOCATION

### IP & Hosting
```
IP Address:    188.114.97.7
Port:          443 (HTTPS)
Location:      OTP (Otopeni, Romania - Cloudflare PoP)
```

### CDN & Security
```
CDN Provider:  ✅ Cloudflare
Server:        cloudflare
Ray ID:        a3737f628b31e598-OTP
```

**Cloudflare Features Aktiv:**
- ✅ DDoS Protection
- ✅ CDN Caching
- ✅ SSL/TLS Encryption
- ✅ Bot Protection (`cf_clearance` cookie)
- ✅ Real User Monitoring (RUM)
- ✅ Performance Monitoring

---

## 🔧 BACKEND FRAMEWORK

### Laravel Confirmation ✅

**Cookie Evidence:**
```
1. XSRF-TOKEN (Laravel CSRF protection)
2. idrak_liseyi_session (Laravel session)
```

**Laravel Session Cookie:**
```json
{
  "name": "idrak_liseyi_session",
  "encrypted": true,
  "iv": "gZQElgLrRjt0cn/miF4AcA==",
  "mac": "b873169a0d812b3bec9335855965...f5c7c65f3ca99a637f281596f4e0b3651b0"
}
```

**CSRF Token Cookie:**
```json
{
  "name": "XSRF-TOKEN",
  "encrypted": true,
  "purpose": "CSRF protection",
  "renewal": "per request"
}
```

### Session Configuration
```php
// Laravel config/session.php (təxmini)
'driver' => 'cookie',
'cookie' => 'idrak_liseyi_session',
'encrypt' => true,
'http_only' => true,
'same_site' => 'lax',
```

---

## 🔐 SECURITY HEADERS

### Access Control
```
access-control-allow-credentials: true
access-control-allow-methods:     POST, OPTIONS
access-control-allow-origin:      https://new.idrak.edu.az
access-control-max-age:           86400
```

### Cloudflare Security
```
cf-ray:           a3737f628b31e598-OTP
cf_clearance:     Bot/DDoS protection token
nel:              Network Error Logging
report-to:        Cloudflare error reporting
```

### SSL/TLS
```
Protocol:         h3 (HTTP/3 over QUIC)
alt-svc:          h3=":443"; ma=86400
```

---

## 🎯 API STRUCTURE (Təsdiqlənmiş)

### Base URL
```
https://new.idrak.edu.az
```

### Content Type
```
application/json    (API requests)
text/plain         (CDN responses)
```

### Authentication
```
Method:     Cookie-based session (Laravel default)
CSRF:       Required via XSRF-TOKEN
Cookies:    
  - idrak_liseyi_session (user session)
  - XSRF-TOKEN (CSRF protection)
  - cf_clearance (Cloudflare security)
```

---

## 📱 MOBİL APP ÜÇÜN API İNTEGRASİYA

### Current Challenge
```
❌ Web:    Cookie-based auth (Browser-only)
❌ Mobile:  Firebase (separate database)
❌ Sync:   No automatic synchronization
```

### Solution: API Token Authentication

#### Option 1: Laravel Sanctum (Tövsiyə)
```php
// Backend (Laravel)
composer require laravel/sanctum

// Mobile app API authentication
POST /api/auth/login
{
  "fin_code": "1234567",
  "password": "********"
}

Response:
{
  "token": "1|abcdef123456...",
  "user": { ... }
}

// Subsequent requests
Headers:
  Authorization: Bearer 1|abcdef123456...
```

#### Option 2: Laravel Passport (OAuth2)
```php
// More complex, for third-party integrations
composer require laravel/passport
```

---

## 🔄 REKOMENDASİYA: HYBRID APPROACH

### Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    CLOUDFLARE CDN                       │
│         (DDoS Protection, Cache, SSL)                   │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
    ┌────▼─────┐          ┌─────▼────┐
    │   WEB    │          │  MOBILE  │
    │ (Cookie) │          │  (Token) │
    └────┬─────┘          └─────┬────┘
         │                      │
         └───────────┬──────────┘
                     │
              ┌──────▼──────┐
              │   LARAVEL   │
              │   API v1    │
              └──────┬──────┘
                     │
         ┌───────────┴───────────┐
         │                       │
    ┌────▼─────┐          ┌─────▼────────┐
    │  MySQL   │          │  Firebase    │
    │  (Core)  │          │  (Cache/RT)  │
    └──────────┘          └──────────────┘
```

### Implementation Steps

#### Step 1: Backend (Globalmart ilə koordinasiya)
```php
// routes/api.php
Route::prefix('v1')->group(function () {
    // Public
    Route::post('/auth/login', [AuthController::class, 'login']);
    
    // Protected (Sanctum middleware)
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/user', [UserController::class, 'me']);
        Route::get('/students', [StudentController::class, 'index']);
        Route::get('/assignments', [AssignmentController::class, 'index']);
        Route::get('/grades', [GradeController::class, 'index']);
        // ... 39 more endpoints
    });
});
```

#### Step 2: Mobile App (Flutter)
```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'https://new.idrak.edu.az/api/v1';
  String? _token;

  Future<void> login(String finCode, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      body: {
        'fin_code': finCode,
        'password': password,
      },
    );
    
    final data = jsonDecode(response.body);
    _token = data['token'];
    await AuthStorageService().saveToken(_token!);
  }

  Future<List<Student>> getStudents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/students'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      },
    );
    
    return (jsonDecode(response.body) as List)
        .map((json) => Student.fromJson(json))
        .toList();
  }
}
```

#### Step 3: Firebase (Real-time only)
```dart
// Firebase yalnız real-time events üçün
FirebaseMessaging.onMessage.listen((message) {
  // Push notification
  showNotification(message);
});

// Firestore: yalnız offline cache
Future<void> cacheStudents(List<Student> students) async {
  await FirebaseFirestore.instance
      .collection('cache_students')
      .doc('local')
      .set({'students': students.map((s) => s.toJson()).toList()});
}
```

---

## 📊 BANDWIDTH & PERFORMANCE

### Cloudflare Benefits
```
✅ Global CDN:        Fast loading worldwide
✅ DDoS Protection:   99.99% uptime
✅ HTTP/3:            Faster protocol
✅ Caching:           Static assets cached
✅ Compression:       gzip, brotli, zstd
```

### Expected Performance
```
API Response Time:    <200ms (within Azerbaijan)
CDN Cache Hit:        ~80% (static assets)
SSL Handshake:        ~50ms (TLS 1.3)
```

---

## 🔍 CLOUDFLARE FEATURES DETECTed

### RUM (Real User Monitoring)
```
Endpoint:  /cdn-cgi/rum
Method:    POST
Purpose:   User experience metrics
Data:      Page load times, errors, performance
```

### NEL (Network Error Logging)
```json
{
  "report_to": "cf-nel",
  "success_fraction": 0.0,
  "max_age": 604800
}
```

### Error Reporting
```
Report URL: https://a.nel.cloudflare.com/report/v4
Purpose:    Network error tracking
```

---

## 💰 CLOUDFLARE PLAN (Təxmini)

### Features Analysis
```
✅ HTTP/3 support         → Pro+ plan
✅ Advanced DDoS          → Pro+ plan
✅ RUM monitoring         → Business+ plan
✅ Custom SSL             → Pro+ plan
✅ Origin server IP hide  → All plans

Estimated Plan: Business ($200/month) or Enterprise
```

---

## 🎯 NEXT STEPS: API Development

### Phase 1: Authentication API (1 week)
- [ ] Laravel Sanctum installation
- [ ] Login endpoint
- [ ] Token refresh endpoint
- [ ] Logout endpoint

### Phase 2: Core APIs (3-4 weeks)
- [ ] Students API (CRUD)
- [ ] Assignments API
- [ ] Grades API
- [ ] Attendance API
- [ ] Notifications API
- [ ] Library API
- [ ] Cafeteria API

### Phase 3: Admin APIs (4-5 weeks)
- [ ] HR (Employees, Contracts)
- [ ] Finance (Invoices, Payroll)
- [ ] Exams
- [ ] Statistics
- [ ] Warehouse

### Phase 4: Mobile Integration (2 weeks)
- [ ] Flutter API service layer
- [ ] Token management
- [ ] Offline caching
- [ ] Error handling
- [ ] Testing

**Total Timeline:** 10-12 weeks

---

## 📝 KOORDİNASİYA

### Globalmart ilə danışmaq lazımdır:

**Mövzular:**
1. API endpoint-lər yaratmaq
2. Laravel Sanctum quraşdırma
3. Rate limiting (API throttle)
4. Documentation (Swagger/Postman)
5. Testing environment

**Contact:**
- Footer-dən: "Develop by Globalmart Group"
- Admin panel-də contact məlumatı

---

## ✅ SUMMARY

### Təsdiqlənmiş Məlumatlar:
- ✅ **Server:** Cloudflare CDN (Romania PoP)
- ✅ **Backend:** PHP Laravel (cookie-based session)
- ✅ **IP:** 188.114.97.7
- ✅ **SSL:** HTTP/3 support
- ✅ **Security:** DDoS protection, Bot mitigation

### Mobil App üçün lazımdır:
- ❌ API Token authentication (hazırda yoxdur)
- ❌ RESTful endpoints (bəziləri var, tam deyil)
- ❌ Documentation (API docs lazımdır)

### Həll yolu:
1. Globalmart ilə danış
2. API yaratdır (Laravel Sanctum)
3. Mobil app-i API-yə qoşul
4. Firebase yalnız push notification üçün istifadə et

---

**Status:** ✅ Analysis Complete  
**Next:** Backend team koordinasiya
