# PROGRESS — Web Parity Rebuild

> Branch: `feature/web-parity-rebuild`
> Web source (read-only except additive API): `D:\IdrakSchoolManagment\Idrak_Backend_Panel\source`
> Mobile: `D:\IdrakLiseyiGUNCEL`
> DB: MariaDB 13.0.2 `idrak_panel_2026_2027` @ 127.0.0.1:3306 (207 tables, backup taken)

## Current state

### Faz 0 — Baseline & Safety — DONE
- Git checkpoint committed, branch `feature/web-parity-rebuild` created.
- DB backup: `backups/backup_20261102_1543.sql` (602 MB), `backups/` gitignored.
- Baseline `flutter analyze`: 0 errors, 1 warning (unused field in notification_listener_service), 162 infos.
- Web boots: Laravel 10.50.2, `php artisan db:show` OK (207 tables, ~2 GB).
- Route inventory exported: `docs/routes_export.json` (918 routes).
- Firebase admin key is NOT tracked (gitignored); no secret committed.

### Faz 1 — Web inventory — PARTIAL (docs/WEB_INVENTORY.md)
- Full admin sidebar read (see `WEB_INVENTORY.md`).
- Route counts per controller extracted (918 routes, ~170 controllers).
- Parent/student sidebars still to be fully mapped.

### Faz 2 — Parity matrix — IN PROGRESS (`../PARITY_MATRIX.md`)
- Library + HR modules fully catalogued from web controllers/datatables/enums.

### Faz 2b — Mobile foundation — TODO (next)

### API layer (additive ONLY, no existing controller/route/blade changed)
New files under `app/Http/Controllers/Api/Mobile/V1/`, `app/Http/Middleware/Mobile/` and an additive `routes/api.php` group.

Only shared-model touch (minimal, additive): `HasApiTokens` trait added to `Admin`, `Employees`, `Parents`
(`User` already had it) so Sanctum personal access tokens work for every guard.

Implemented:
- `POST /api/mobile/v1/auth/login` — email/FIN across 4 guards, same password fallback as web.
- `GET  /api/mobile/v1/auth/me` — profile, roles, active role, full Spatie permissions, scope, linked entities.
- `POST /api/mobile/v1/auth/context` — role/branch/company switch (reissues token).
- `POST /api/mobile/v1/auth/logout`, `POST /api/mobile/v1/auth/change-password`.
- Library: books (list/show/CRUD), categories (list/CRUD), loans (list/show/issue/return), reservations (list/show/create/approve/reject) — real MariaDB data verified (231 books, 216 active employees).
- HR: employees (list via `EmployeeQuery`, show, create/update delegated to web `EmployeeController::save`, delete), contracts (list/show/create/update/delete/terminate), attendance matrix + store/lock/unlock (delegated), tax rules, salary calculator (reuses `NetSalaryService`; verified 1000 gross → 889 net, PRIVATE_NO rules).

Verified with live HTTP calls against `http://127.0.0.1:8000`.

## Known gaps / notes
- Web real-time broadcasting (Reverb/Pusher) is not installed in this source → mobile uses polling now; FCM push handles notifications.
- Company type enum includes `PRIVATE_NON_OIL` but tax rules are seeded for `PRIVATE_NO`; API falls back automatically.
- Employee contract termination on web is document-driven (`ISDEN_AZAD_ETME`); mobile currently sets contract `status=terminated` + employee inactive + activity log. Document flow still TODO.
