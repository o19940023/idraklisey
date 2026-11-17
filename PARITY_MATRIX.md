# PARITY MATRIX — Web GoPanel → Mobile

Statuses: `TODO` · `IN-PROGRESS` · `DONE` · `VERIFIED` · `DELETED-NOT-ON-WEB`

Legend: API = mobile endpoint, Screen = Flutter file, Perm = web permission required.

## Auth & shell
| Web | API | Screen | Perm | Status |
|---|---|---|---|---|
| Login (email/FIN, 4 guards) | `POST auth/login` | login | — | VERIFIED (HTTP) |
| /me profile | `GET auth/me` | shell | — | VERIFIED (HTTP) |
| Role switch | `POST auth/context` | role sheet | — | DONE |
| Guard/company/branch switch | `POST auth/context` | context sheet | — | DONE |
| Logout | `POST auth/logout` | settings | — | DONE |
| Password change | `POST auth/change-password` | settings | — | DONE |

## Kitabxana
| Web | API | Screen | Perm | Status |
|---|---|---|---|---|
| Books list (search/filter/sort) | `GET library/books` | library catalog | `library.books.view` | VERIFIED (231 rows) |
| Book detail | `GET library/books/{id}` | book detail | `library.books.view` | DONE |
| Add/Edit/Delete book | `POST/PUT/DELETE library/books` | book form | books.create/update/delete | DONE |
| Categories list/CRUD | `GET/POST/PUT/DELETE library/categories` | categories | categories.* | VERIFIED |
| Loans list/filter/overdue | `GET library/loans` | loans | loans.view | DONE |
| Issue loan | `POST library/loans` | issue sheet | loans.create | DONE |
| Return book (normal/damaged/lost) | `POST library/loans/{id}/return` | return sheet | loans.return | DONE |
| Reservations list | `GET library/reservations` | reservations | reservations.view | VERIFIED |
| Reservation create | `POST library/reservations` | reserve | — | DONE |
| Approve reservation | `POST library/reservations/{id}/approve` | swipe/button | reservations.manage | DONE |
| Reject reservation | `POST library/reservations/{id}/reject` | swipe/button | reservations.manage | DONE |

## HR
| Web | API | Screen | Perm | Status |
|---|---|---|---|---|
| Employees list (EmployeeQuery filters) | `GET hr/employees` | employees | hr.employees.view | VERIFIED (216 rows) |
| Employee dossier | `GET hr/employees/{id}` | employee detail | hr.employees.view | DONE |
| Add employee (web save logic) | `POST hr/employees` | wizard | hr.employees.create | DONE (delegated) |
| Edit employee | `PUT hr/employees/{id}` | wizard | hr.employees.update | DONE (delegated) |
| Delete employee | `DELETE hr/employees/{id}` | action | hr.employees.delete | DONE |
| Contracts list | `GET hr/contracts` | contracts | hr.contracts.view | DONE |
| Contract detail | `GET hr/contracts/{id}` | contract detail | hr.contracts.view | DONE |
| Add/Edit contract | `POST/PUT hr/contracts` | form | contracts.create/update | DONE (delegated) |
| Terminate contract | `POST hr/contracts/{id}/terminate` | confirm sheet | contracts.update | DONE (document flow TODO) |
| Attendance matrix | `GET hr/attendance` | attendance | hr.attendances.view | VERIFIED (250 rows) |
| Attendance cell save | `POST hr/attendance` | matrix editor | hr.attendances.update | DONE (delegated) |
| Lock/unlock month | `POST hr/attendance/lock|unlock` | header action | hr.attendances.lock | DONE (delegated) |
| Tax rules | `GET hr/tax-rules` | tax rules | finance.tax_rules.view | DONE |
| Salary calculator | `POST hr/salary/calculate` | calculator | dashboard.salary_calculator | VERIFIED (1000→889) |
| HR dictionaries | `GET hr/meta` | dropdowns | hr.employees.view | DONE |

## Students / Admissions — TODO
Student list/detail/wizard (6 steps), admissions, parents, graduations, transitions, classes, parallel lessons, teachers, schedules, e-journal attendance/grading/assignments/curriculums, clubs, foundations (years/statuses/subjects/rooms/time slots), academic notes.

## Finance — TODO
Student contracts/invoices, payments, payroll calculation/salary list/archive, tax rules, general ledger, reports, finance dictionary.

## Exams — TODO
Categories, exams, results, questions, sections, template questions, first-time applications.

## Warehouse / Canteen — TODO
Items, logs, inventorizations, canteens, weekly menus, templates, hygiene.

## Medical / Psychology — TODO
Medical results, excuses, allergy/sickness, ambulatory, vaccination, mantoux, reference, sanitary, daily meals, psychology results/criteria.

## Statistics — TODO
Quality control, attendance, performance, assignments, admissions, leavers, monthly, vacation balances, payment schedule, warehouse, workload.

## Tickets / Notifications / Banners / Social / Site — TODO
Tickets + categories + responses/assign, notifications, admin notifications, banners, social posts/comments/likes, site content, languages/translations, users/roles/permissions, activity logs, AI assistant, clubs catalog.

## Non-web features (preserved)
| Feature | Screen | Status |
|---|---|---|
| Meet İdrak (Agora) | meet_idrak, create_meet, voice_room | PRESERVED |
| Digital ID Card | digital_id_card, teacher_id_card | PRESERVED |
