# WEB INVENTORY — GoPanel (source of truth)

Generated from `config/gopanel/sidebar_menu_list.php`, `routes/gopanel.php` (1,477 lines),
`routes/api.php`, `docs/routes_export.json` (918 total routes) and the controller tree.

## Route totals
- 918 routes total; ~170 GoPanel controllers.
- Auth: multi-guard `gopanel` (Admin), `employer` (Employees), `student` (User), `parent` (Parents), `web` (User).
- Middleware: `auth.any` + `student.timeout`; route switches for role (`switch.role`) and guard (`switch.guard`).
- Permissions: Spatie (`23 roles`, `1,190 permissions`), active-role aware (`HasActiveRole`).
- Installed: Sanctum 3.3, Spatie permission/activitylog/query-builder, DomPDF. **No Reverb/Pusher.**

## Sidebar (admin panel)

### 1. Dashboard — `gopanel.index` (no permission)
- Role-specific dashboards, quick notes, grade detail, journal fill stats, leaves/ambulatory/finance AJAX.
- Parent weekly menu `gopanel.parent.weekly_menu` (`gopanel.canteen.preview.view`).
- Parent contracts `gopanel.parent.contracts.index`.
- Clubs catalog + join/cancel (`clubs.catalog`).
- AI assistant `POST /ai/ask`.

### 2. Akademik idarəetmə (`gopanel.academic.students.view`)
| Menu | Route | Permission |
|---|---|---|
| Qəbul (admissions) | `gopanel.academic.students.admissions` | `gopanel.academic.students.admissions` |
| Ambulator müraciətlər | `gopanel.admissions.ambulatory_requests.index` | `gopanel.admissions.ambulatory_requests.view` |
| Şagirdlər | `gopanel.academic.students.index` | `gopanel.academic.students.view` |
| Məzunlar | `gopanel.academic.graduations.index` | `gopanel.academic.graduations.view` |
| Keçid istisnaları | `gopanel.academic.transitions.exceptions.index` | ...view |
| Valideynlər | `gopanel.academic.parents.index` | `gopanel.academic.parents.view` |
| Siniflər | `gopanel.academic.teachers.classes.index` | `gopanel.academic.classes.view` |
| Paralel dərslər | `gopanel.academic.parallel_lessons.index` | ...view |
| Müəllimlər | `gopanel.academic.teachers.teachers.index` | `gopanel.academic.teachers.view` |
| Cədvəl | `gopanel.academic.scheduling.index` | `gopanel.academic.schedules.view` |
| Davamiyyət jurnalı | `gopanel.academic.operations.attendance.index` | `gopanel.academic.ejournal.attendance.view` |
| Sinif rəhbəri bəhanələri | `gopanel.academic.homeroom.excuses.index` | ...view |
| Klub jurnalı | `gopanel.academic.clubs.journal.index` | ...view |
| Yekun qiymətləndirmə | `gopanel.academic.operations.grading.final` | ...grading.final |
| Tapşırıqlar | `gopanel.academic.operations.assignments.index` | ...assignments.view |
| Kurikulumlar | `gopanel.academic.operations.curriculums.manage` | ...curriculums.view |
| Klublar | `gopanel.academic.clubs.index` | `gopanel.academic.clubs.view` |
| Tədris illəri | `gopanel.academic.foundations.academic_years.index` | ...years.view |
| Statuslar | `gopanel.academic.foundations.statuses.index` | ...statuses.view |
| Fənlər | `gopanel.academic.foundations.subjects.index` | ...subjects.view |
| Otaqlar | `gopanel.academic.foundations.rooms.index` | ...rooms.view |
| Dərs saatları | `gopanel.academic.foundations.time_slots.index` | ...time_slots.view |
| Akademik qeydlər | `gopanel.academic.notes.index` | ...notes.view |

### 3. İnsan resursları
- Təşkilati struktur: `structures`, `positions`, `staffing_tables`.
- Əməkdaşlar `gopanel.employees.index` (`gopanel.hr.employees.view`).
- Müqavilələr `gopanel.contracts.index` (`gopanel.hr.contracts.view`), sənədlər `employee_documents`.
- Sənəd idarəetməsi: `document_types`, `document_templates`.
- Davamiyyət `gopanel.attendances.index` (`gopanel.hr.attendances.view`), istehsalat təqvimləri `teqvims`.
- Dinamik bölmələr: `field_groups`, `fields`.

### 4. Maliyyə və mühasibatlıq
- Şagird maliyyəsi: `student_contracts` (invoices), `student_payments`.
- Əməkhaqqı: `payroll_calculation`, `salary_list`, `payroll_archive`, `tax_rules`.
- Baş kitab: `ledger.index`, `reports.index`.
- Maliyyə lüğəti: bank accounts, external entities, note templates, transport rates, tuition fees, categories.

### 5. Təsərrüfat, nəqliyyat, inventar
- Anbar `warehouse_actions.items.index`, `item_logs`, `inventorizations`.
- Yeməkxana: `canteens.index`, `canteen.index` (weekly menus), `canteen_templates`.

### 6. Tibb
- `medical_results`, `excuses`, `allergy_sickness`; journals: ambulatory, vaccination, mantoux, reference, sanitary, daily meals, psychology (4 routes).

### 7. Psixologiya
- `psicology_results`, `psicology_creterions`, `student_first_time_applications`, `transition_exceptions`.

### 8. İmtahanlar
- `exam_categories`, `exams`, `results`, `student_first_time_applications`, `transition_exceptions`.
- Also questions, sections, template questions, student exam results.

### 9. Ticket sistemi
- `tickets.index` (`view` / `view.assigned`), `tickets.categories`, responses, assign, respond.

### 10. Kitabxana
- `categories`, `books`, `loans`, `book_reservations` (+ barcode/lookup endpoints).

### 11. Statistika və hesabatlar
- quality_control, attendance, performance, assignments, admissions, leavers, monthly, vacation balances, payment schedule, warehouse, workload_report_v2.

### 12. Məktəb tənzimləmələri
- companies, filials, warehouses, code_generators.

### 13. Sistem və jurnallar
- site settings, dashboard banners, admin notifications, languages/translations, admins/roles/permissions, activity history, file logs.

## Additional (3B) modules found
- Auth/profile (login by email/FIN, profile, password change, avatar, inventory confirm).
- Notifications (index, get-latest, read, read-all, delete).
- Admin notifications (CRUD + send), dashboard banners (CRUD + toggle).
- Social posts/comments/likes.
- Site content: menus, FAQs, teams, graduates, education systems, standard pages, contact info.
- Geometry: countries, states, cities.
- Bell IoT API (`/api/v1/bells/*`).
- Employee import, student import, curriculum import, attendance import/export, PDF exports (employee card, invoices, contracts).

## Key note
Web lists are **server-rendered Blade + DataTables AJAX**. The mobile API therefore reuses the same models,
query filters (Datatable/EmployeeQuery), enums, and services (e.g. `NetSalaryService`), never duplicating business logic.
