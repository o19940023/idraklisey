# 🔧 Mobil App-ə Əlavə Edilməli Funksiyalar - Texniki Spesifikasiya

**Tarix:** 07.09.2026  
**Layihə:** İdrak Liseyi Flutter App  
**Status:** Planlaşdırma Mərhələsi

---

## 📋 ÜMUMİ STRUKTUR

```
lib/
├── modules/
│   ├── hr/                          # 🆕 Yeni Modul
│   │   ├── screens/
│   │   │   ├── employees_screen.dart
│   │   │   ├── contracts_screen.dart
│   │   │   ├── employee_documents_screen.dart
│   │   │   ├── employee_attendance_screen.dart
│   │   │   └── salary_calculator_screen.dart
│   │   ├── widgets/
│   │   └── models/
│   ├── finance/                     # 🆕 Yeni Modul
│   │   ├── screens/
│   │   │   ├── student_invoices_screen.dart
│   │   │   ├── payroll_screen.dart
│   │   │   ├── general_ledger_screen.dart
│   │   │   └── finance_dictionary_screen.dart
│   │   └── widgets/
│   ├── exams/                       # 🆕 Yeni Modul
│   │   ├── screens/
│   │   │   ├── exam_categories_screen.dart
│   │   │   ├── exams_screen.dart
│   │   │   ├── exam_results_screen.dart
│   │   │   └── new_student_assessment_screen.dart
│   │   └── widgets/
│   ├── warehouse/                   # 🆕 Genişləndirmə
│   │   ├── screens/
│   │   │   ├── inventorization_screen.dart
│   │   │   └── warehouse_management_screen.dart
│   │   └── widgets/
│   ├── library/                     # 🔄 Genişləndirmə
│   │   ├── screens/
│   │   │   ├── library_screen.dart           # ✅ Mövcud
│   │   │   ├── library_categories_screen.dart # 🆕 Yeni
│   │   │   ├── book_loans_screen.dart         # 🆕 Yeni
│   │   │   └── book_reservations_screen.dart  # 🆕 Yeni
│   ├── helpdesk/                    # 🔄 Genişləndirmə
│   │   ├── screens/
│   │   │   ├── parent_tickets_screen.dart    # ✅ Mövcud (məhdud)
│   │   │   ├── admin_tickets_screen.dart     # 🆕 Yeni
│   │   │   └── ticket_categories_screen.dart # 🆕 Yeni
│   ├── statistics/                  # 🆕 Yeni Modul
│   │   ├── screens/
│   │   │   ├── quality_control_screen.dart
│   │   │   ├── attendance_stats_screen.dart
│   │   │   ├── performance_stats_screen.dart
│   │   │   ├── workload_report_screen.dart
│   │   │   └── warehouse_stats_screen.dart
│   ├── academic/                    # 🔄 Genişləndirmə
│   │   ├── screens/
│   │   │   ├── graduations_screen.dart       # 🆕 Yeni
│   │   │   ├── transitions_screen.dart       # 🆕 Yeni
│   │   │   ├── excused_absences_screen.dart  # 🆕 Yeni
│   │   │   ├── curriculum_screen.dart        # 🆕 Yeni
│   │   │   ├── clubs_screen.dart             # 🆕 Yeni
│   │   │   └── academic_notes_screen.dart    # 🆕 Yeni
│   └── settings/                    # 🔄 Genişləndirmə
│       ├── screens/
│       │   ├── academic_years_screen.dart    # 🆕 Yeni
│       │   ├── subjects_screen.dart          # 🆕 Yeni
│       │   ├── rooms_screen.dart             # 🆕 Yeni
│       │   └── time_slots_screen.dart        # 🆕 Yeni
└── data/
    └── models/
        ├── employee_model.dart               # 🆕 Yeni
        ├── contract_model.dart               # 🆕 Yeni
        ├── invoice_model.dart                # 🆕 Yeni
        ├── exam_model.dart                   # 🆕 Yeni
        ├── warehouse_model.dart              # 🆕 Yeni
        └── ...
```

---

## 1️⃣ HR MODULU (İnsan Resursları)

### 📁 Firebase Firestore Struktur

```
/employees/
  {employeeId}/
    - id: String
    - fullName: String
    - position: String
    - department: String
    - hireDate: Timestamp
    - photoUrl: String?
    - email: String
    - phone: String
    - idNumber: String
    - birthDate: Timestamp
    - contractId: String?
    - status: 'active' | 'onLeave' | 'inactive'
    - salary: Number
    - createdAt: Timestamp
    - updatedAt: Timestamp

/contracts/
  {contractId}/
    - id: String
    - employeeId: String
    - contractType: 'fullTime' | 'partTime' | 'temporary'
    - startDate: Timestamp
    - endDate: Timestamp?
    - salaryGross: Number
    - signedDate: Timestamp
    - documentUrl: String?
    - status: 'active' | 'expired' | 'terminated'
    - notes: String?

/employeeDocuments/
  {documentId}/
    - id: String
    - employeeId: String
    - documentType: String (ID, passport, diploma)
    - documentNumber: String
    - issueDate: Timestamp
    - expiryDate: Timestamp?
    - fileUrl: String
    - uploadedAt: Timestamp

/employeeAttendance/
  {attendanceId}/
    - id: String
    - employeeId: String
    - date: Timestamp
    - checkIn: Timestamp?
    - checkOut: Timestamp?
    - status: 'present' | 'absent' | 'late' | 'onLeave'
    - leaveType: 'sick' | 'vacation' | 'maternity' | 'business'?
    - notes: String?
```

### 🎨 UI Ekranlar

#### 1.1 Əməkdaşlar Ekranı (`employees_screen.dart`)
- **Görünüş:** ListView + Search + Filter
- **Filtrlər:** 
  - Status (aktiv, məzuniyyətdə, qeyri-aktiv)
  - Department (İT, Pedaqoji, İnzibati)
- **Card məlumatları:**
  - Foto
  - Ad Soyad
  - Vəzifə
  - Departament
  - Status badge

#### 1.2 Müqavilələr Ekranı (`contracts_screen.dart`)
- **Görünüş:** Grouped List (aktiv, bitmək üzrə, bitmiş)
- **Xüsusiyyətlər:**
  - Müqavilə tipi
  - Başlama/Bitmə tarixi
  - Status indicator (xəbərdarlıq 30 gün əvvəl)
  - PDF görüntüləmə

#### 1.3 Maaş Kalkulyatoru (`salary_calculator_screen.dart`)
- **Input:**
  - Gross əmək haqqı
  - Başlama/bitmə tarixi
  - İş təcrübəsi
- **Output:**
  - Net əmək haqqı
  - Gəlir vergisi (14%)
  - DSMF (3%)
  - İşsizlikdən sığorta (0.5%)
  - Sağlamlıq sığortası (2%)
- **Widget:** Real-time hesablama, breakdown chart

---

## 2️⃣ MALİYYƏ MODULU

### 📁 Firebase Firestore Struktur

```
/studentInvoices/
  {invoiceId}/
    - id: String
    - studentId: String
    - amount: Number
    - dueDate: Timestamp
    - paidDate: Timestamp?
    - status: 'pending' | 'paid' | 'overdue'
    - invoiceType: 'tuition' | 'lunch' | 'transport' | 'other'
    - notes: String?
    - createdAt: Timestamp

/payroll/
  {payrollId}/
    - id: String
    - employeeId: String
    - period: String (YYYY-MM)
    - grossSalary: Number
    - netSalary: Number
    - incomeTax: Number
    - socialFund: Number
    - unemploymentInsurance: Number
    - healthInsurance: Number
    - bonuses: Number?
    - deductions: Number?
    - paymentDate: Timestamp
    - status: 'calculated' | 'approved' | 'paid'

/generalLedger/
  {entryId}/
    - id: String
    - date: Timestamp
    - type: 'income' | 'expense'
    - category: String
    - amount: Number
    - description: String
    - externalEntity: String?
    - documentNumber: String?
    - createdBy: String
    - approvedBy: String?
```

### 🎨 UI Ekranlar

#### 2.1 Tələbə Maliyyə Əməliyyatları (`student_invoices_screen.dart`)
- **Görünüş:** Grouped by student/class
- **Filtrlər:** Ödəniş statusu, tip, tarix
- **Actions:** Yeni invoice yarat, ödəniş qeyd et

#### 2.2 Əmək Haqqı Hesablanması (`payroll_screen.dart`)
- **Görünüş:** Monthly list, filterable
- **Xüsusiyyətlər:**
  - Bulk calculation (ay üçün hamıya)
  - Individual adjustments
  - Approval workflow
  - Export to Excel

---

## 3️⃣ İMTAHAN SİSTEMİ

### 📁 Firebase Firestore Struktur

```
/examCategories/
  {categoryId}/
    - id: String
    - name: String (AZ/EN/RU)
    - description: String?
    - orderIndex: Number

/exams/
  {examId}/
    - id: String
    - title: String
    - categoryId: String
    - subjectId: String
    - classIds: [String]
    - examDate: Timestamp
    - duration: Number (minutes)
    - totalPoints: Number
    - passingScore: Number
    - status: 'scheduled' | 'inProgress' | 'completed'
    - createdBy: String
    - createdAt: Timestamp

/examResults/
  {resultId}/
    - id: String
    - examId: String
    - studentId: String
    - score: Number
    - percentage: Number
    - grade: String (A+, A, B+, ...)
    - isPassed: Boolean
    - submittedAt: Timestamp
    - gradedBy: String?
    - gradedAt: Timestamp?
    - feedback: String?

/studentAssessments/ # Yeni tələbələr üçün
  {assessmentId}/
    - id: String
    - studentId: String
    - applicationId: String
    - assessmentDate: Timestamp
    - subjectScores: Map<String, Number>
    - totalScore: Number
    - recommendation: 'accept' | 'waitlist' | 'reject'
    - notes: String?
    - assessedBy: String
```

### 🎨 UI Ekranlar

#### 3.1 İmtahanlar (`exams_screen.dart`)
- **Görünüş:** Calendar view + List view toggle
- **Filtrlər:** Tarix, fənn, sinif, status
- **Actions:** Yeni imtahan yarat, nəticələri gör

#### 3.2 İmtahan Nəticələri (`exam_results_screen.dart`)
- **Görünüş:** Class-wise grouped, sortable
- **Analytics:**
  - Orta bal
  - Keçid faizi
  - Top performanlar
  - Distribution chart

---

## 4️⃣ KİTABXANA GENİŞLƏNDİRMƏSİ

### 📁 Firebase Firestore Struktur (Mövcud + Yeni)

```
/libraryCategories/
  {categoryId}/
    - id: String
    - name: String
    - description: String?
    - icon: String
    - parentCategoryId: String? # subcategories
    - orderIndex: Number

/books/ # ✅ Mövcud, genişləndirilməli
  {bookId}/
    - ... (mövcud fieldlər)
    + availableCopies: Number
    + totalCopies: Number
    + isbn: String?
    + publisher: String?
    + publicationYear: Number?

/bookLoans/ # 🆕 Yeni
  {loanId}/
    - id: String
    - bookId: String
    - userId: String
    - userType: 'student' | 'teacher' | 'parent'
    - loanDate: Timestamp
    - dueDate: Timestamp
    - returnDate: Timestamp?
    - status: 'active' | 'returned' | 'overdue'
    - renewalCount: Number
    - fineAmount: Number?

/bookReservations/ # 🆕 Yeni
  {reservationId}/
    - id: String
    - bookId: String
    - userId: String
    - reservationDate: Timestamp
    - expiryDate: Timestamp
    - status: 'pending' | 'ready' | 'fulfilled' | 'cancelled'
    - notifiedAt: Timestamp?
```

### 🎨 UI Ekranlar

#### 4.1 Kitabxana Kateqoriyaları (`library_categories_screen.dart`)
- **Görünüş:** Grid view with icons
- **Xüsusiyyətlər:** Subcategory navigation

#### 4.2 İcarə Sistemi (`book_loans_screen.dart`)
- **Student View:** Mənim icarələrim, tarix, cərimə
- **Librarian View:** Bütün icarələr, gecikənlər, iade et

#### 4.3 Rezervasiya (`book_reservations_screen.dart`)
- **Actions:** Rezerv et, ləğv et, bildiriş al

---

## 5️⃣ HELPDESK SİSTEMİ (Genişləndirmə)

### 📁 Firebase Firestore Struktur

```
/tickets/ # ✅ Mövcud, genişləndirilməli
  {ticketId}/
    - ... (mövcud fieldlər)
    + priority: 'low' | 'medium' | 'high' | 'urgent'
    + assignedTo: String? # adminId
    + attachmentUrls: [String]
    + resolution: String?
    + resolvedAt: Timestamp?
    + closedAt: Timestamp?

/ticketCategories/ # 🆕 Yeni
  {categoryId}/
    - id: String
    - name: String (AZ/EN/RU)
    - description: String?
    - icon: String
    - orderIndex: Number
    - defaultPriority: String

/ticketComments/ # 🆕 Yeni
  {commentId}/
    - id: String
    - ticketId: String
    - userId: String
    - userRole: String
    - message: String
    - attachmentUrls: [String]?
    - createdAt: Timestamp
    - isInternal: Boolean # admin notes
```

### 🎨 UI Ekranlar

#### 5.1 Admin Tickets (`admin_tickets_screen.dart`)
- **Görünüş:** Kanban board (Open/In Progress/Resolved)
- **Filtrlər:** Priority, category, assigned to
- **Actions:** Assign, update status, add comment

#### 5.2 Bilet Kateqoriyaları (`ticket_categories_screen.dart`)
- **Admin Only:** CRUD operations

---

## 6️⃣ STATİSTİKA DASHBOARD-LARI

### 📁 Məlumat Strukturu (Aggregate/Computed)

```
/statistics/
  quality_control/
    - ... (web-dən alınan real-time data)
  attendance_stats/
    - ... (class/student wise)
  performance_stats/
    - ... (subject wise, teacher wise)
  workload_report/
    - ... (teacher schedule analysis)
```

### 🎨 UI Ekranlar

#### 6.1 Keyfiyyətə Nəzarət (`quality_control_screen.dart`)
- **Charts:**
  - Davamiyyət trendi (line chart)
  - Sinif müqayisəsi (bar chart)
  - Risk tələbələri (list + alerts)

#### 6.2 İş Yükü Hesabatı (`workload_report_screen.dart`)
- **Teacher View:** Həftəlik saat, sinif sayı
- **Admin View:** Department wise yük, overload alerts

---

## 7️⃣ AKADEMİK TƏMƏL AYARLAR

### 📁 Firebase Firestore Struktur

```
/academicYears/
  {yearId}/
    - id: String
    - name: String (2024-2025)
    - startDate: Timestamp
    - endDate: Timestamp
    - isCurrent: Boolean
    - status: 'active' | 'archived'

/subjects/
  {subjectId}/
    - id: String
    - name: String (AZ/EN/RU)
    - code: String (MAT-101)
    - department: String
    - credits: Number?
    - isActive: Boolean

/rooms/
  {roomId}/
    - id: String
    - roomNumber: String
    - building: String
    - floor: Number
    - capacity: Number
    - type: 'classroom' | 'lab' | 'gym' | 'library'
    - facilities: [String] # projector, whiteboard, computers

/timeSlots/
  {slotId}/
    - id: String
    - period: Number (1, 2, 3...)
    - startTime: String (HH:mm)
    - endTime: String (HH:mm)
    - dayOfWeek: Number? # if specific day
    - isBreak: Boolean
```

### 🎨 UI Ekranlar (Admin Only)

#### 7.1 Akademik İllər (`academic_years_screen.dart`)
- **Actions:** CRUD, set current year

#### 7.2 Fənnlər (`subjects_screen.dart`)
- **Görünüş:** Grouped by department

#### 7.3 Otaqlar (`rooms_screen.dart`)
- **Xüsusiyyətlər:** Filter by type, capacity, availability

#### 7.4 Zəng Cədvəli (`time_slots_screen.dart`)
- **Görünüş:** Timeline view, editable

---

## 8️⃣ ANBAR İDARƏETMƏSİ

### 📁 Firebase Firestore Struktur

```
/warehouses/
  {warehouseId}/
    - id: String
    - name: String
    - location: String
    - type: 'main' | 'branch' | 'storage'
    - managerId: String?

/inventoryItems/
  {itemId}/
    - id: String
    - name: String
    - category: String
    - qrCode: String
    - warehouseId: String
    - quantity: Number
    - unit: String (pcs, kg, liters)
    - purchaseDate: Timestamp?
    - purchasePrice: Number?
    - supplier: String?
    - status: 'available' | 'inUse' | 'damaged' | 'disposed'
    - lastInventoryDate: Timestamp?

/inventorizations/ # periodic audits
  {inventorizationId}/
    - id: String
    - warehouseId: String
    - conductedBy: String
    - conductedDate: Timestamp
    - items: [
        {
          itemId: String
          expectedQuantity: Number
          actualQuantity: Number
          discrepancy: Number
          notes: String?
        }
      ]
    - status: 'inProgress' | 'completed' | 'approved'
```

### 🎨 UI Ekranlar

#### 8.1 İnventorizasiya (`inventorization_screen.dart`)
- **Actions:** Start audit, scan QR, record counts
- **Report:** Discrepancy report, approval flow

#### 8.2 Anbar İdarəetməsi (`warehouse_management_screen.dart`)
- **Görünüş:** Item list, search, QR scan
- **Actions:** Add item, update quantity, transfer

---

## 9️⃣ AKADEMİK QEYDLər (İkinci Mərhələ)

### 📁 Firebase Firestore Struktur

```
/graduations/
  {graduationId}/
    - studentId: String
    - graduationDate: Timestamp
    - gpa: Number
    - rank: Number?
    - diploma: String? # URL
    - awards: [String]?

/transitionExceptions/
  {exceptionId}/
    - studentId: String
    - fromClass: String
    - toClass: String
    - reason: String
    - requestDate: Timestamp
    - approvedBy: String?
    - status: 'pending' | 'approved' | 'rejected'

/excusedAbsences/
  {absenceId}/
    - studentId: String
    - date: Timestamp
    - reason: String
    - documentUrl: String? # medical note
    - requestedBy: String # parent
    - approvedBy: String? # teacher/admin
    - status: 'pending' | 'approved' | 'rejected'

/clubs/
  {clubId}/
    - name: String (AZ/EN/RU)
    - description: String
    - supervisorId: String # teacher
    - members: [String] # studentIds
    - schedule: String
    - photoUrl: String?
```

---

## 🔟 TEŞKİLAT STRUKTURU (İkinci Mərhələ)

### 📁 Firebase Firestore Struktur

```
/companies/
  {companyId}/
    - id: String
    - name: String
    - address: String
    - phone: String
    - email: String
    - logo: String?

/branches/
  {branchId}/
    - id: String
    - companyId: String
    - name: String
    - location: String
    - managerId: String?

/organizationalStructures/
  {structureId}/
    - id: String
    - department: String
    - parentDepartment: String?
    - headOfDepartment: String # employeeId
    - members: [String] # employeeIds

/documentTypes/
  {typeId}/
    - name: String
    - category: String
    - requiredFields: [String]
    - templateId: String?

/documentTemplates/
  {templateId}/
    - name: String
    - typeId: String
    - templateUrl: String # PDF/DOCX
    - version: String
```

---

## 📦 PAKETLər (dependencies to add)

```yaml
dependencies:
  # Existing
  flutter:
    sdk: flutter
  provider: ^6.1.2
  firebase_core: ^2.32.0
  cloud_firestore: ^4.17.5
  firebase_auth: ^4.20.0
  
  # 🆕 New Required
  syncfusion_flutter_charts: ^25.1.35      # Charts for statistics
  syncfusion_flutter_calendar: ^25.1.35    # Calendar view
  fl_chart: ^0.66.0                        # Lightweight charts
  pdf: ^3.10.8                             # PDF generation
  printing: ^5.12.0                        # PDF printing
  excel: ^4.0.2                            # Excel export
  file_picker: ^6.2.1                      # File uploads
  image_picker: ^1.0.7                     # Photo uploads
  qr_flutter: ^4.1.0                       # QR code display
  mobile_scanner: ^4.0.0                   # QR scanning (already exists)
  intl: ^0.19.0                            # Date formatting (already exists)
  uuid: ^4.3.3                             # ID generation
  cached_network_image: ^3.3.1             # Image caching (already exists)
  animations: ^2.0.11                      # Smooth transitions
  badges: ^3.1.2                           # Badge widgets
  shimmer: ^3.0.0                          # Loading animations
```

---

## 🔄 AppState Genişləndirilməsi

```dart
class AppState extends ChangeNotifier {
  // ... existing properties

  // 🆕 HR
  List<Employee> _employees = [];
  List<Contract> _contracts = [];
  List<EmployeeDocument> _employeeDocuments = [];
  List<EmployeeAttendance> _employeeAttendance = [];

  // 🆕 Finance
  List<StudentInvoice> _studentInvoices = [];
  List<PayrollEntry> _payrollEntries = [];
  List<GeneralLedgerEntry> _ledgerEntries = [];

  // 🆕 Exams
  List<ExamCategory> _examCategories = [];
  List<Exam> _exams = [];
  List<ExamResult> _examResults = [];

  // 🆕 Warehouse
  List<WarehouseItem> _inventoryItems = [];
  List<Inventorization> _inventorizations = [];

  // 🆕 Academic Settings
  List<AcademicYear> _academicYears = [];
  List<Subject> _subjects = [];
  List<Room> _rooms = [];
  List<TimeSlot> _timeSlots = [];

  // ... getters, setters, Firebase methods
}
```

---

## 🎯 İMPLEMENTASIYA SİRASI

### Faza 1: Kritik Admin Funksiyaları (4-6 həftə)
**Week 1-2: HR Modulu**
- Models (Employee, Contract, Document, Attendance)
- Screens (4 screens)
- Firebase CRUD
- AppState integration

**Week 3-4: Maliyyə Modulu**
- Models (Invoice, Payroll, Ledger)
- Screens (4 screens)
- Maaş kalkulyatoru
- Export functionality

**Week 5-6: Akademik Təməl Ayarlar**
- Models (AcademicYear, Subject, Room, TimeSlot)
- Screens (4 screens)
- Admin CRUD operations

### Faza 2: Genişləndirmə (4-5 həftə)
**Week 7-8: İmtahan Sistemi**
- Models + Screens (4 screens)
- Result analytics

**Week 9-10: Kitabxana Genişləndirilməsi**
- Loan system
- Reservation system

**Week 11: Helpdesk Tam Sinxronizasiya**
- Categories, comments, admin view

### Faza 3: İkinci Dəstə (4-5 həftə)
**Week 12-13: Statistika**
- Dashboard widgets (6 screens)
- Charts integration

**Week 14-15: Anbar + Təşkilat**
- Warehouse management
- QR integration
- Structure screens

---

## 📝 Test Planı

### Unit Tests
- Model serialization/deserialization
- Business logic (salary calculator, grade calculations)
- Date/time utilities

### Integration Tests
- Firebase CRUD operations
- Authentication flows
- Navigation flows

### Widget Tests
- Form validation
- Button states
- List rendering

### End-to-End Tests
- Complete user journeys (e.g., create employee → assign contract → calculate salary)

---

## 🚀 Deployment Strategy

1. **Dev Environment** - Test with dummy data
2. **Staging** - Test with production-like data
3. **Production Rollout** - Incremental module releases
   - Module 1: HR (internal testing with admin)
   - Module 2: Finance (controlled release to finance dept)
   - Module 3: Academic Settings (admin only)
   - Module 4-7: Public release

---

**Son Yeniləmə:** 07.09.2026  
**Prepared by:** Kiro AI Assistant
