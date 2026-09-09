# 📋 BACKEND DEVELOPER İSTƏKLƏRİ - Mobil App Sinxronizasiya

**Tarix:** 07.09.2026  
**Layihə:** İdrak Liseyi Mobil App  
**Backend:** Laravel (new.idrak.edu.az)  
**Developer:** Globalmart Group

---

## 🎯 ƏSAS TƏLƏb

**Mobil aplikasiya ilə web panel arasında tam məlumat sinxronizasiyası üçün RESTful API lazımdır.**

---

## 1️⃣ AUTHENTİCATİON (Token-Based)

### 📌 İstək: Laravel Sanctum quraşdırılsın

**Nə lazımdır:**

#### a) Paket quraşdırma
```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

#### b) Login API
```
POST /api/v1/auth/login
Content-Type: application/json

Body:
{
  "fin_code": "1234567",
  "password": "********",
  "device_name": "iPhone 14" // opsional
}

Response (200):
{
  "success": true,
  "token": "1|abcdef123456789...",
  "user": {
    "id": 123,
    "fin_code": "1234567",
    "full_name": "Ayşe Məmmədova",
    "role": "student",
    "email": "ayse.memmedova@idrak.edu.az",
    "photo_url": "https://...",
    "class": "10-A"
  }
}

Response (401):
{
  "success": false,
  "message": "FIN kod və ya şifrə yanlışdır"
}
```

#### c) Logout API
```
POST /api/v1/auth/logout
Authorization: Bearer {token}

Response (200):
{
  "success": true,
  "message": "Uğurla çıxış edildi"
}
```

#### d) User Info
```
GET /api/v1/auth/user
Authorization: Bearer {token}

Response (200):
{
  "success": true,
  "user": { ... }
}
```

#### e) Token Refresh (opsional)
```
POST /api/v1/auth/refresh
Authorization: Bearer {old_token}

Response (200):
{
  "success": true,
  "token": "2|newtoken123..."
}
```

---

## 2️⃣ ŞAGİRD (STUDENT) API-ləri

### a) Şagird Siyahısı
```
GET /api/v1/students
Authorization: Bearer {token}
Query Parameters:
  - class: 10-A (opsional)
  - search: "ayşe" (opsional)
  - page: 1 (pagination)

Response (200):
{
  "success": true,
  "data": [
    {
      "id": 123,
      "fin_code": "1234567",
      "full_name": "Ayşe Məmmədova",
      "class": "10-A",
      "photo_url": "https://...",
      "birth_date": "2010-05-15",
      "email": "ayse@idrak.edu.az"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_items": 100
  }
}
```

### b) Şagird Detalları
```
GET /api/v1/students/{id}
Authorization: Bearer {token}

Response (200):
{
  "success": true,
  "student": {
    "id": 123,
    "full_name": "Ayşe Məmmədova",
    "class": "10-A",
    "grades": { ... },
    "attendance": { ... },
    "assignments": { ... }
  }
}
```

### c) Şagird Yaratma (Admin only)
```
POST /api/v1/students
Authorization: Bearer {token}
Body: { ... }
```

### d) Şagird Yeniləmə (Admin only)
```
PUT /api/v1/students/{id}
Authorization: Bearer {token}
Body: { ... }
```

---

## 3️⃣ TAPŞIRIQLAR (ASSIGNMENTS) API

### a) Tapşırıq Siyahısı
```
GET /api/v1/assignments
Authorization: Bearer {token}
Query Parameters:
  - class: 10-A
  - subject: Riyaziyyat
  - status: active / completed / expired
  - due_date_from: 2026-09-01
  - due_date_to: 2026-09-30

Response (200):
{
  "success": true,
  "data": [
    {
      "id": 456,
      "title": "Riyaziyyat - Çalışma 1",
      "description": "Səhifə 45-50 məsələlər",
      "subject": "Riyaziyyat",
      "class": "10-A",
      "teacher_name": "Leyla Həsənova",
      "created_date": "2026-09-01T10:00:00Z",
      "due_date": "2026-09-10T23:59:59Z",
      "status": "active",
      "attachment_url": "https://..."
    }
  ]
}
```

### b) Tapşırıq Təqdim Etmə (Şagird)
```
POST /api/v1/assignments/{id}/submit
Authorization: Bearer {token}
Content-Type: multipart/form-data

Body:
  - file: [PDF/Image file]
  - note: "Tamamlandı" (opsional)

Response (200):
{
  "success": true,
  "message": "Tapşırıq təqdim edildi",
  "submission_id": 789
}
```

### c) Tapşırıq Yaratma (Müəllim)
```
POST /api/v1/assignments
Authorization: Bearer {token}
Body: {
  "title": "...",
  "description": "...",
  "subject_id": 10,
  "class_ids": [1, 2, 3],
  "due_date": "2026-09-10"
}
```

---

## 4️⃣ QİYMƏTLƏR (GRADES) API

### a) Qiymət Siyahısı
```
GET /api/v1/grades
Authorization: Bearer {token}
Query Parameters:
  - student_id: 123
  - semester: 1 / 2
  - academic_year: 2025-2026

Response (200):
{
  "success": true,
  "data": [
    {
      "subject": "Riyaziyyat",
      "grades": [5, 4, 5, 5],
      "average": 4.75,
      "teacher": "Leyla Həsənova"
    },
    {
      "subject": "Fizika",
      "grades": [4, 5, 4],
      "average": 4.33,
      "teacher": "Ramiz Əliyev"
    }
  ],
  "overall_average": 4.54
}
```

### b) Qiymət Əlavə Etmə (Müəllim)
```
POST /api/v1/grades
Authorization: Bearer {token}
Body: {
  "student_id": 123,
  "subject_id": 10,
  "grade": 5,
  "type": "written_exam / oral_exam / homework",
  "date": "2026-09-07",
  "note": "Əla cavab"
}
```

---

## 5️⃣ DAVAMIYYƏT (ATTENDANCE) API

### a) Davamiyyət Sorğusu
```
GET /api/v1/attendance
Authorization: Bearer {token}
Query Parameters:
  - student_id: 123 (opsional)
  - class_id: 1
  - date_from: 2026-09-01
  - date_to: 2026-09-07

Response (200):
{
  "success": true,
  "data": [
    {
      "date": "2026-09-07",
      "student_id": 123,
      "status": "present / absent / late / excused",
      "note": "Həkim arayışı var"
    }
  ],
  "summary": {
    "present_days": 20,
    "absent_days": 2,
    "late_days": 1,
    "attendance_rate": 91.3
  }
}
```

### b) Davamiyyət Qeyd Et (Müəllim)
```
POST /api/v1/attendance
Authorization: Bearer {token}
Body: {
  "class_id": 1,
  "date": "2026-09-07",
  "students": [
    {"student_id": 123, "status": "present"},
    {"student_id": 124, "status": "absent", "note": "Xəstə"}
  ]
}
```

---

## 6️⃣ DƏRS CƏDVƏLİ (TIMETABLE) API

### a) Dərs Cədvəli
```
GET /api/v1/timetable
Authorization: Bearer {token}
Query Parameters:
  - class_id: 1
  - week: 2026-W36 (ISO week)

Response (200):
{
  "success": true,
  "data": {
    "monday": [
      {
        "period": 1,
        "time": "09:00-09:45",
        "subject": "Riyaziyyat",
        "teacher": "Leyla Həsənova",
        "room": "201"
      }
    ],
    "tuesday": [ ... ]
  }
}
```

---

## 7️⃣ BİLDİRİŞLƏR (NOTIFICATIONS) API

### a) Bildiriş Siyahısı
```
GET /api/v1/notifications
Authorization: Bearer {token}
Query Parameters:
  - unread_only: true / false
  - page: 1

Response (200):
{
  "success": true,
  "data": [
    {
      "id": 999,
      "title": "Yeni tapşırıq",
      "message": "Riyaziyyat üzrə yeni tapşırıq verildi",
      "type": "assignment / grade / announcement",
      "is_read": false,
      "created_at": "2026-09-07T10:00:00Z",
      "data": {
        "assignment_id": 456
      }
    }
  ],
  "unread_count": 5
}
```

### b) Bildirişi Oxunmuş Et
```
POST /api/v1/notifications/{id}/read
Authorization: Bearer {token}

Response (200):
{
  "success": true
}
```

### c) Hamısını Oxunmuş Et
```
POST /api/v1/notifications/read-all
Authorization: Bearer {token}
```

### d) Yeni Bildiriş Göndər (Admin/Müəllim)
```
POST /api/v1/notifications
Authorization: Bearer {token}
Body: {
  "title": "Elan",
  "message": "Sabah məktəb bağlıdır",
  "type": "announcement",
  "target": {
    "type": "class / student / all",
    "ids": [1, 2, 3]
  }
}
```

---

## 8️⃣ KİTABXANA (LIBRARY) API

### a) Kitab Siyahısı
```
GET /api/v1/library/books
Authorization: Bearer {token}
Query Parameters:
  - search: "riyaziyyat"
  - category: "Dərslik / Elmi / Bədii"
  - available_only: true

Response (200):
{
  "success": true,
  "data": [
    {
      "id": 111,
      "title": "Riyaziyyat 10-cu sinif",
      "author": "Əliyev R.",
      "isbn": "978-...",
      "category": "Dərslik",
      "total_copies": 50,
      "available_copies": 35,
      "cover_url": "https://..."
    }
  ]
}
```

### b) Kitab İcarəsi
```
POST /api/v1/library/loans
Authorization: Bearer {token}
Body: {
  "book_id": 111,
  "student_id": 123,
  "due_date": "2026-09-21"
}

Response (200):
{
  "success": true,
  "loan_id": 555,
  "due_date": "2026-09-21"
}
```

### c) Kitab İadəsi
```
POST /api/v1/library/loans/{loan_id}/return
Authorization: Bearer {token}
```

---

## 9️⃣ YEMƏKXANA (CAFETERIA) API

### a) Həftəlik Menyu
```
GET /api/v1/cafeteria/menu
Authorization: Bearer {token}
Query Parameters:
  - week: 2026-W36

Response (200):
{
  "success": true,
  "data": {
    "monday": {
      "breakfast": {
        "items": ["Brınza pendiri", "Çay", "Çörək"],
        "calories": 350
      },
      "lunch": {
        "items": ["Plov", "Salat", "Kompot"],
        "calories": 650
      }
    }
  }
}
```

---

## 🔟 HR (İŞÇİLƏR) API (Admin only)

### a) İşçi Siyahısı
```
GET /api/v1/employees
Authorization: Bearer {token}
Query Parameters:
  - department: "Pedaqoji / İT / İnzibati"
  - status: "active / on_leave / inactive"

Response (200):
{
  "success": true,
  "data": [
    {
      "id": 222,
      "full_name": "Leyla Həsənova",
      "position": "Riyaziyyat müəllimi",
      "department": "Pedaqoji",
      "hire_date": "2020-09-01",
      "salary": 2500,
      "status": "active"
    }
  ]
}
```

### b) Müqavilələr
```
GET /api/v1/contracts
GET /api/v1/contracts/{id}
POST /api/v1/contracts
PUT /api/v1/contracts/{id}
```

### c) İşçi Davamiyyəti
```
GET /api/v1/employee-attendance
POST /api/v1/employee-attendance
```

---

## 1️⃣1️⃣ MALİYYƏ (FINANCE) API (Admin only)

### a) Şagird Ödənişləri
```
GET /api/v1/finance/invoices
POST /api/v1/finance/invoices
PUT /api/v1/finance/invoices/{id}
```

### b) Maaş Hesablanması
```
GET /api/v1/finance/payroll
POST /api/v1/finance/payroll/calculate
```

### c) Gəlir/Xərc
```
GET /api/v1/finance/ledger
POST /api/v1/finance/ledger
```

---

## 1️⃣2️⃣ İMTAHAN (EXAMS) API

### a) İmtahan Siyahısı
```
GET /api/v1/exams
GET /api/v1/exams/{id}
POST /api/v1/exams (Müəllim/Admin)
```

### b) İmtahan Nəticələri
```
GET /api/v1/exam-results
POST /api/v1/exam-results (Müəllim)
```

---

## 1️⃣3️⃣ DƏSTƏK BİLETLƏRİ (HELPDESK) API

### a) Bilet Siyahısı
```
GET /api/v1/tickets
Authorization: Bearer {token}

Response (200):
{
  "success": true,
  "data": [
    {
      "id": 777,
      "title": "Şifrə sıfırlanması",
      "category": "Texniki",
      "priority": "high / medium / low",
      "status": "open / in_progress / resolved / closed",
      "created_at": "2026-09-07T10:00:00Z"
    }
  ]
}
```

### b) Bilet Yaratma
```
POST /api/v1/tickets
Body: {
  "title": "...",
  "description": "...",
  "category_id": 5,
  "priority": "medium"
}
```

### c) Bilet Yenilənməsi (Admin)
```
PUT /api/v1/tickets/{id}
Body: {
  "status": "resolved",
  "assigned_to": 10,
  "resolution": "Həll edildi"
}
```

---

## 1️⃣4️⃣ STATİSTİKA (STATISTICS) API (Admin)

### a) Dashboard Statistikaları
```
GET /api/v1/statistics/dashboard
Authorization: Bearer {token}

Response (200):
{
  "success": true,
  "data": {
    "total_students": 578,
    "male_students": 339,
    "female_students": 446,
    "active_employees": 219,
    "open_tickets": 5,
    "new_applications": 9,
    "attendance_rate": 94.1,
    "low_attendance_classes": [
      {"class": "10-E", "rate": 94.1}
    ],
    "at_risk_students": [
      {"student_id": 123, "average": 3.2}
    ]
  }
}
```

### b) Davamiyyət Statistikası
```
GET /api/v1/statistics/attendance
Query Parameters:
  - class_id: 1
  - date_from: 2026-09-01
  - date_to: 2026-09-07
```

### c) Performans Statistikası
```
GET /api/v1/statistics/performance
Query Parameters:
  - student_id: 123 (opsional)
  - class_id: 1 (opsional)
```

---

## 1️⃣5️⃣ AKADEMİK AYARLAR (SETTINGS) API (Admin)

### a) Akademik İllər
```
GET /api/v1/settings/academic-years
POST /api/v1/settings/academic-years
PUT /api/v1/settings/academic-years/{id}
```

### b) Fənnlər
```
GET /api/v1/settings/subjects
POST /api/v1/settings/subjects
PUT /api/v1/settings/subjects/{id}
```

### c) Otaqlar
```
GET /api/v1/settings/rooms
POST /api/v1/settings/rooms
PUT /api/v1/settings/rooms/{id}
```

### d) Zəng Vaxtları
```
GET /api/v1/settings/time-slots
POST /api/v1/settings/time-slots
PUT /api/v1/settings/time-slots/{id}
```

---

## 🔒 SECURITY & RATE LIMITING

### a) Rate Limiting
```php
// routes/api.php
Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
    // 60 request per minute
});
```

### b) Error Handling
```json
// Standart error response
{
  "success": false,
  "message": "Xəta baş verdi",
  "errors": {
    "field_name": ["Validation message"]
  },
  "code": 422
}
```

### c) HTTP Status Codes
```
200 - Success
201 - Created
400 - Bad Request
401 - Unauthorized (token yoxdur/yanlışdır)
403 - Forbidden (icazə yoxdur)
404 - Not Found
422 - Validation Error
429 - Too Many Requests (rate limit)
500 - Server Error
```

---

## 📚 DOCUMENTATION

### İstək: API Documentation

**Format:** Swagger / OpenAPI və ya Postman Collection

**Nə daxil olmalıdır:**
- ✅ Hər endpoint üçün tam təsvir
- ✅ Request/Response nümunələri
- ✅ Authentication tələbləri
- ✅ Error kodları və izahları
- ✅ Testing environment (staging URL)

**Nümunə Documentation URL:**
```
https://new.idrak.edu.az/api/documentation
```

---

## 🧪 TESTING ENVİRONMENT

### İstək: Staging Server

```
Production:  https://new.idrak.edu.az
Staging:     https://staging.idrak.edu.az (və ya subdomain)
```

**Test Credentials:**
- Admin user
- Teacher user
- Student user
- Parent user

---

## 📊 CORS SETTINGS

### İstək: CORS konfiqurasiyası

```php
// config/cors.php
'allowed_origins' => [
    'https://new.idrak.edu.az',
    'http://localhost:3000',  // Flutter mobile app (development)
],
'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
'allowed_headers' => ['Content-Type', 'Authorization', 'Accept'],
'exposed_headers' => [],
'max_age' => 86400,
'supports_credentials' => true,
```

---

## 🔔 PUSH NOTIFICATION SUPPORT

### İstək: FCM Token Qeydiyyatı

```
POST /api/v1/notifications/register-device
Authorization: Bearer {token}
Body: {
  "fcm_token": "firebase_cloud_messaging_token...",
  "device_type": "ios / android",
  "device_name": "iPhone 14"
}
```

**Server-side:**
- FCM token database-də saxlanılsın
- Backend yeni event olduqda push notification göndərsin

---

## 📝 SON TƏLƏbLƏR

### 1. Response Format (Standart)
```json
// Success
{
  "success": true,
  "data": { ... },
  "message": "Əməliyyat uğurlu" // opsional
}

// Error
{
  "success": false,
  "message": "Xəta mesajı",
  "errors": { ... } // validation errors
}
```

### 2. Pagination (Siyahı üçün)
```json
{
  "success": true,
  "data": [ ... ],
  "pagination": {
    "current_page": 1,
    "total_pages": 10,
    "per_page": 20,
    "total_items": 200
  }
}
```

### 3. DateTime Format
```
ISO 8601: "2026-09-07T10:30:00Z"
Timezone: UTC
```

### 4. Localization
```
Query Parameter: ?lang=az / en / ru
Response messages: həmin dildə
```

---

## 🚀 İMPLEMENTASİYA TİMELİNE

### Prioritet 1 (1-2 həftə) - KRİTİK
- ✅ Authentication (login, logout, token)
- ✅ Students API
- ✅ Assignments API
- ✅ Grades API
- ✅ Attendance API
- ✅ Notifications API

### Prioritet 2 (2-3 həftə) - ÖNƏMLİ
- ✅ Timetable API
- ✅ Library API
- ✅ Cafeteria API
- ✅ Tickets API

### Prioritet 3 (3-4 həftə) - ADMIN
- ✅ HR APIs
- ✅ Finance APIs
- ✅ Exams APIs
- ✅ Statistics APIs
- ✅ Settings APIs

---

## 📞 ƏLAQƏ

**Developer Team:**
- Company: Globalmart Group
- Project: İdrak Liseyi Panel
- Backend: Laravel

**Mobil Team:**
- Platform: Flutter
- Client: İdrak Liseyi

---

## ✅ CHECKLIST

Developer-ə göndərməmişdən əvvəl yoxla:

- [ ] Bütün endpoint-lər siyahılandı
- [ ] Authentication metodu aydındır (Sanctum)
- [ ] Response format-ları göstərildi
- [ ] Error handling izah edildi
- [ ] Rate limiting tələbləri var
- [ ] CORS settings tələbləri var
- [ ] Documentation formatı göstərildi
- [ ] Testing environment istənildi
- [ ] Timeline və prioritetlər aydındır
- [ ] Push notification support tələb edildi

---

**Status:** ✅ Hazır  
**Action:** Bu sənədi Globalmart developer team-ə göndər  
**Contact:** Backend project manager

---

## 💡 ƏK QEYD

Bu sənədi **PDF** və ya **Google Docs** formatında göndərməyi tövsiyə edirəm.

Əgər developer sualları olarsa, texniki meeting təşkil edin və bu sənədi screen share edin.

**Estimated Development Time:** 6-8 həftə (1-2 backend developer)

Good luck! 🚀
