# API Contract Validation — FLT-502

**Tiket:** FLT-502  
**Sprint:** 1  
**Tanggal:** 2026-06-05  
**Penulis:** Henri Kurniawan  
**Status:** ✅ Validated — Langsung dari Backend Source Code

---

## 1. Ringkasan Eksekutif

Dokumen ini memvalidasi **seluruh API contract** antara Flutter mobile (`moneymate_mobile`) dan backend MoneyMate (`moneymate-api`). Validasi dilakukan langsung dari **source code backend** (Express.js + Knex.js), bukan dari dokumentasi atau asumsi.

### Sumber Data

| Sumber | Repository | Lokasi |
|--------|-----------|--------|
| Flutter Mobile | `moneymate_mobile` | `lib/` — models, repositories, providers |
| Backend API | `moneymate-api` | `src/` — routes, controllers, migrations, services |
| Web Frontend (referensi) | `moneymate-frontend` | `src/services/` — cross-validation |

### Metodologi

1. Full scan seluruh source code Flutter (`lib/`) — 21 file
2. Full scan seluruh backend (`src/routes/`, `src/controllers/`, `src/database/migrations/`) — 20+ file
3. Mapping route → controller → Zod schema → database column → Flutter DTO
4. Field-by-field type comparison
5. Identifikasi mismatch: field name, type, nullability, missing endpoints, missing HTTP methods

### Hasil Utama

| Metrik | Nilai |
|--------|-------|
| Total endpoint backend (dari source code) | **25** |
| Endpoint yang sudah diimplementasi di Flutter | **1** (`GET /api/dashboard`) |
| Endpoint yang belum diimplementasi di Flutter | **24** |
| Flutter ApiClient HTTP method tersedia | `GET`, `POST` |
| Flutter ApiClient HTTP method **MISSING** | `PUT`, `DELETE`, `PATCH` |
| Flutter Model/DTO yang sudah ada | 5 (Dashboard family) |
| Flutter Model/DTO yang belum dibuat | ~12+ |
| Mismatch ditemukan | **8 temuan** |
| Dashboard contract field match | **100%** ✅ |

---

## 2. Konfigurasi & Infrastruktur

### 2.1 Base URL & Server

| Aspek | Backend | Flutter |
|-------|---------|---------|
| Default URL | `http://localhost:3000` (`src/server.js`) | `http://localhost:3000` (`app_config.dart`) |
| Framework | Express.js | Dio (HTTP client) |
| DB | PostgreSQL / MySQL | N/A |
| JSON Limit | `10kb` (`app.js:31`) | Tidak ada limit client-side |
| CORS Origins | `FRONTEND_URL` env (default `localhost:5173`) | Tidak perlu (native app) |

### 2.2 Authentication Scheme

| Aspek | Backend (`middleware/auth.js`) | Flutter (`api_client.dart`) |
|-------|-------------------------------|----------------------------|
| Scheme | `Bearer <JWT>` | `Bearer <token>` |
| Header | `Authorization` | `Authorization` |
| Token creation | `jsonwebtoken` sign | N/A (terima dari backend) |
| Token revocation | `revoked_tokens` table | `clearSession()` |
| Skip auth | Route-level (`authenticate` middleware) | `_isAuthEndpoint('/api/auth/')` |
| 401 handling | Return `{ message }` | `onUnauthorized` callback → clear session |

> ✅ **Match.** Flutter `_isAuthEndpoint` mengecek prefix `/api/auth/`, konsisten dengan backend yang tidak menambahkan `authenticate` middleware pada route auth (kecuali `POST /logout`).

### 2.3 API Client HTTP Methods

| HTTP Method | Backend Routes | Flutter `ApiClient` | Status |
|-------------|---------------|---------------------|--------|
| `GET` | ✅ 10 routes | ✅ `get()` | ✅ OK |
| `POST` | ✅ 9 routes | ✅ `post()` | ✅ OK |
| `PUT` | ✅ 3 routes | ❌ **MISSING** | 🔴 BLOCKER |
| `DELETE` | ✅ 4 routes | ❌ **MISSING** | 🔴 BLOCKER |
| `PATCH` | ✅ 2 routes | ❌ **MISSING** | 🔴 BLOCKER |

> **File:** `lib/core/network/api_client.dart` L82–104

---

## 3. Daftar Lengkap Endpoint Backend (Dari Source Code)

### Route Mounting (`src/app.js`)

```
/api/auth           → authRoutes.js
/api/categories     → categoryRoutes.js
/api/transactions   → transactionRoutes.js
/api/budget-periods → budgetPeriodRoutes.js
/api/dashboard      → dashboardRoutes.js
/api/notifications  → notificationRoutes.js
```

---

### 3.1 Authentication — `src/routes/authRoutes.js`

| # | Endpoint | Method | Auth | Zod Schema | Request Body | Response |
|---|----------|--------|------|------------|-------------|----------|
| 1 | `/api/auth/register` | `POST` | ❌ | `registerSchema` | `{ name: string(min:1), email: string(email), password: string(min:6) }` | `201 { message, data: { token, user: { id, name, email } } }` |
| 2 | `/api/auth/login` | `POST` | ❌ | `loginSchema` | `{ email: string(email), password: string(min:1) }` | `200 { message, data: { token, user: { id, name, email } } }` |
| 3 | `/api/auth/google` | `POST` | ❌ | `googleLoginSchema` | `{ idToken: string(min:1) }` | `200/201 { message, data: { token, user: { id, name, email } } }` |
| 4 | `/api/auth/logout` | `POST` | ✅ | — | _(kosong)_ | `200 { message }` |

**Response format (dari `buildAuthResponse`):**
```json
{
  "message": "Login successful.",
  "data": {
    "token": "<jwt>",
    "user": { "id": 1, "name": "Henri", "email": "henri@test.com" }
  }
}
```

---

### 3.2 Dashboard — `src/routes/dashboardRoutes.js`

| # | Endpoint | Method | Auth | Request | Response |
|---|----------|--------|------|---------|----------|
| 5 | `/api/dashboard` | `GET` | ✅ | — | `200 { data: { totals, budgets } }` |

**Actual response shape (dari `dashboardController.js:78–93`):**
```json
{
  "data": {
    "totals": {
      "balance": 5000000.0,
      "income": 8000000.0,
      "expense": 3000000.0
    },
    "budgets": {
      "active_count": 2,
      "effective_today": 340000.0,
      "spent_today": 180000.0,
      "remaining_today": 160000.0,
      "status": [
        {
          "budget_period_id": 3,
          "name": "Juni 2025",
          "budget_system": "carry_over",
          "category_id": null,
          "category_name": null,
          "category_type": null,
          "start_date": "2025-06-01",
          "end_date": "2025-06-30",
          "daily_status": {
            "date": "2025-06-04",
            "budget_system": "carry_over",
            "base": 150000.0,
            "carry_over": 20000.0,
            "invested_before": 0.0,
            "invested_today": 0.0,
            "invested_total": 0.0,
            "effective_budget": 170000.0,
            "total_spent": 90000.0,
            "remaining": 80000.0,
            "is_excluded_day": false,
            "is_weekend": false
          }
        }
      ]
    }
  }
}
```

---

### 3.3 Transactions — `src/routes/transactionRoutes.js`

| # | Endpoint | Method | Auth | Request | Response |
|---|----------|--------|------|---------|----------|
| 6 | `/api/transactions` | `GET` | ✅ | `?date=&type=&category=&page=&limit=` | `{ data: Transaction[], meta? }` |
| 7 | `/api/transactions/:id` | `GET` | ✅ | path param | `{ data: Transaction }` |
| 8 | `/api/transactions` | `POST` | ✅ | `createTransactionSchema` | `201 { message, data: Transaction }` |
| 9 | `/api/transactions/:id` | `PUT` | ✅ | `updateTransactionSchema` | `{ message, data: Transaction }` |
| 10 | `/api/transactions/:id` | `DELETE` | ✅ | path param | `{ message }` |
| 11 | `/api/transactions/receipt-scan` | `POST` | ✅ | `multipart/form-data` field: `receipt` (image/pdf, max 10MB) | `{ message, data: AiDraft }` |
| 12 | `/api/transactions/mutation-scan` | `POST` | ✅ | `multipart/form-data` field: `receipts` (max 10 files) | `{ message, data: AiDraft[] }` |

**Create Transaction Zod Schema (`transactionController.js:15–24`):**
```
{
  category_id:      number (int, positive, required),
  budget_period_id: number (int, positive, nullable, optional),
  type:             enum("income", "expense"),
  amount:           number (positive, required),
  note:             string (max:1000, optional, nullable),
  date:             string (min:1, required),
  latitude:         number (-90..90, optional, nullable),
  longitude:        number (-180..180, optional, nullable)
}
```

**Transaction Response Fields (dari `listTransactions` query, L81–95):**
```
id, user_id, category_id, budget_period_id, type, amount, note,
date, latitude, longitude, created_at, category_name, budget_period_name
```

---

### 3.4 Categories — `src/routes/categoryRoutes.js`

| # | Endpoint | Method | Auth | Request | Response |
|---|----------|--------|------|---------|----------|
| 13 | `/api/categories` | `GET` | ✅ | `?page=&limit=` | `{ data: Category[], meta? }` |
| 14 | `/api/categories/:id` | `GET` | ✅ | path param | `{ data: Category }` |
| 15 | `/api/categories` | `POST` | ✅ | `createCategorySchema` | `201 { message, data: Category }` |
| 16 | `/api/categories/:id` | `PUT` | ✅ | `updateCategorySchema` | `{ message, data: Category }` |
| 17 | `/api/categories/:id` | `DELETE` | ✅ | path param | `{ message }` |

**Category type enum:** `"income" | "expense" | "both"`

**Category Response Fields (dari controller `select`):** `id, name, type`

> ⚠️ **Catatan:** Categories are user-scoped (`user_id` filter). Backend hanya mengembalikan `id, name, type` tanpa `user_id` di response.

---

### 3.5 Budget Periods — `src/routes/budgetPeriodRoutes.js`

| # | Endpoint | Method | Auth | Request | Response |
|---|----------|--------|------|---------|----------|
| 18 | `/api/budget-periods` | `GET` | ✅ | `?page=&limit=` | `{ data: BudgetPeriod[], meta? }` |
| 19 | `/api/budget-periods` | `POST` | ✅ | `createBudgetPeriodSchema` | `201 { message, data: BudgetPeriod }` |
| 20 | `/api/budget-periods/:id` | `PUT` | ✅ | `updateBudgetPeriodSchema` | `{ message, data: BudgetPeriod }` |
| 21 | `/api/budget-periods/:id` | `DELETE` | ✅ | path param | `{ message }` |
| 22 | `/api/budget-periods/:id/set-default` | `POST` | ✅ | — | `{ message, data: BudgetPeriod }` |
| 23 | `/api/budget-periods/:id/daily-status` | `GET` | ✅ | `?date=YYYY-MM-DD` | `{ data: DailyStatus }` |
| 24 | `/api/budget-periods/:id/daily-statuses` | `GET` | ✅ | `?start_date=&end_date=` | `{ data: DailyStatus[], meta }` |
| 25 | `/api/budget-periods/invest-savings` | `GET` | ✅ | — | `{ data: { total_invested, period_count, periods } }` |

**Create Budget Period Zod Schema:**
```
{
  category_id:       number (nullable, optional),
  name:              string (min:1, max:150, required),
  total_budget:      number (positive, required),
  start_date:        string (min:1, required),
  end_date:          string (min:1, required),
  excluded_weekdays: number[] (0-6, default:[0,6]),
  budget_system:     enum("carry_over","invest","nothing", default:"nothing"),
  is_default:        boolean (default:false)
}
```

---

### 3.6 Notifications — `src/routes/notificationRoutes.js`

| # | Endpoint | Method | Auth | Request | Response |
|---|----------|--------|------|---------|----------|
| 26 | `/api/notifications/vapid-key` | `GET` | ❌ | — | `{ publicKey }` |
| 27 | `/api/notifications/subscribe` | `POST` | ✅ | `{ subscription: { endpoint, keys: { p256dh, auth } } }` atau `{ endpoint, keys }` | `201 { message }` |
| 28 | `/api/notifications/unsubscribe` | `DELETE` | ✅ | `{ endpoint: string(url) }` | `{ message }` |
| 29 | `/api/notifications/history` | `GET` | ✅ | — | `{ data: NotifHistory[], unread_count }` |
| 30 | `/api/notifications/history/:id/read` | `PATCH` | ✅ | path param | `{ message }` |
| 31 | `/api/notifications/history/read-all` | `PATCH` | ✅ | — | `{ message }` |

---

## 4. Tabel Validasi Flutter ↔ Backend

| Feature | Endpoint | Method | Flutter Impl | Repository | Model/DTO | Status |
|---------|----------|--------|-------------|------------|-----------|--------|
| Auth | `/api/auth/register` | POST | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Auth | `/api/auth/login` | POST | ❌ | ❌ | Partial (`AuthUser`, `AuthSession`) | 🟡 PARTIAL |
| Auth | `/api/auth/google` | POST | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Auth | `/api/auth/logout` | POST | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| **Dashboard** | **`/api/dashboard`** | **GET** | **✅** | **✅** | **✅** | **🟢 MATCH** |
| Transaction | `/api/transactions` | GET | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Transaction | `/api/transactions/:id` | GET | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Transaction | `/api/transactions` | POST | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Transaction | `/api/transactions/:id` | PUT | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Transaction | `/api/transactions/:id` | DELETE | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Receipt Scan | `/api/transactions/receipt-scan` | POST | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Mutation Scan | `/api/transactions/mutation-scan` | POST | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Category | `/api/categories` | GET | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Category | `/api/categories/:id` | GET | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Category | `/api/categories` | POST | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Category | `/api/categories/:id` | PUT | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Category | `/api/categories/:id` | DELETE | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Budget | `/api/budget-periods` | GET | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Budget | `/api/budget-periods` | POST | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Budget | `/api/budget-periods/:id` | PUT | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Budget | `/api/budget-periods/:id` | DELETE | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Budget | `/api/budget-periods/:id/set-default` | POST | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Budget | `/api/budget-periods/:id/daily-status` | GET | ❌ | ❌ | Partial (`DashboardDailyStatus`) | 🟡 PARTIAL |
| Budget | `/api/budget-periods/:id/daily-statuses` | GET | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Budget | `/api/budget-periods/invest-savings` | GET | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Notif | `/api/notifications/vapid-key` | GET | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Notif | `/api/notifications/subscribe` | POST | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Notif | `/api/notifications/unsubscribe` | DELETE | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Notif | `/api/notifications/history` | GET | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Notif | `/api/notifications/history/:id/read` | PATCH | ❌ | ❌ | ❌ | 🔴 NOT IMPL |
| Notif | `/api/notifications/history/read-all` | PATCH | ❌ | ❌ | ❌ | 🔴 NOT IMPL |

**Summary: 1/31 endpoint ✅ MATCH, 2/31 🟡 PARTIAL, 28/31 🔴 NOT IMPL**

---

## 5. Detail Validasi — `GET /api/dashboard` (Satu-satunya Endpoint Aktif)

### 5.1 Request Validation

| Aspek | Backend (`dashboardController.js`) | Flutter (`dashboard_repository.dart`) | Match |
|-------|-------------------------------------|---------------------------------------|-------|
| Path | `/api/dashboard` (via `app.js:54`) | `'/api/dashboard'` (L16) | ✅ |
| Method | `GET` (via `router.get`) | `_apiClient.get(_path)` (L30) | ✅ |
| Auth | `authenticate` middleware | Bearer token auto-injected | ✅ |
| Query params | none | none | ✅ |
| Request body | none | none | ✅ |

### 5.2 Response Wrapper

| Aspek | Backend (L78) | Flutter (L39–46) | Match |
|-------|---------------|-------------------|-------|
| Root key | `{ data: { totals, budgets } }` | `body['data']` → `DashboardData.fromJson()` | ✅ |

### 5.3 Field-by-Field: `data.totals`

| Backend Field | Backend Source (L80–84) | Flutter Field | Flutter Type | Flutter File (L20–26) | Match |
|--------------|-------------------------|---------------|-------------|----------------------|-------|
| `balance` | `roundTo2(totalIncome - totalExpense)` → `number` | `balance` | `double` | `dashboard_totals.dart` | ✅ |
| `income` | `toNumber(incomeSummary.total)` → `number` | `income` | `double` | | ✅ |
| `expense` | `toNumber(expenseSummary.total)` → `number` | `expense` | `double` | | ✅ |

### 5.4 Field-by-Field: `data.budgets`

| Backend Field | Backend Source (L85–91) | Flutter Field | Flutter Type | Match |
|--------------|-------------------------|---------------|-------------|-------|
| `active_count` | `budgetStatuses.length` → `int` | `activeCount` | `int` | ✅ |
| `effective_today` | `roundTo2(...)` → `number` | `effectiveToday` | `double` | ✅ |
| `spent_today` | `roundTo2(...)` → `number` | `spentToday` | `double` | ✅ |
| `remaining_today` | `roundTo2(...)` → `number` | `remainingToday` | `double` | ✅ |
| `status` | `budgetStatuses` → `array` | `status` | `List<DashboardBudgetStatus>` | ✅ |

### 5.5 Field-by-Field: `data.budgets.status[]` (Budget Status Item)

| Backend Field (L43–53) | Flutter Field | Flutter Type | Match |
|------------------------|---------------|-------------|-------|
| `budget_period_id` (`period.id`) | `budgetPeriodId` | `int` | ✅ |
| `name` (`period.name`) | `name` | `String` | ✅ |
| `budget_system` (`period.budget_system \|\| "nothing"`) | `budgetSystem` | `String` | ✅ |
| `category_id` (`period.category_id`) — nullable | `categoryId` | `int?` | ✅ |
| `category_name` (`period.category_name`) — nullable | `categoryName` | `String?` | ✅ |
| `category_type` (`period.category_type`) — nullable | `categoryType` | `String?` | ✅ |
| `start_date` (`normalizeDateString(...)`) | `startDate` | `String` | ✅ |
| `end_date` (`normalizeDateString(...)`) | `endDate` | `String` | ✅ |
| `daily_status` (`getDailyStatus(...)`) — object | `dailyStatus` | `DashboardDailyStatus?` | ✅ |

### 5.6 Field-by-Field: `daily_status` Object

Backend source: `budgetService.js:206–219`

| Backend Field | Flutter Field | Flutter Type | Match |
|--------------|---------------|-------------|-------|
| `date` | `date` | `String` | ✅ |
| `budget_system` | `budgetSystem` | `String` | ✅ |
| `base` | `base` | `double` | ✅ |
| `carry_over` | `carryOver` | `double` | ✅ |
| `invested_before` | `investedBefore` | `double` | ✅ |
| `invested_today` | `investedToday` | `double` | ✅ |
| `invested_total` | `investedTotal` | `double` | ✅ |
| `effective_budget` | `effectiveBudget` | `double` | ✅ |
| `total_spent` | `totalSpent` | `double` | ✅ |
| `remaining` | `remaining` | `double` | ✅ |
| `is_excluded_day` | `isExcludedDay` | `bool` | ✅ |
| `is_weekend` | `isWeekend` | `bool` | ✅ |

> ### ✅ Dashboard Contract: **100% MATCH** (12/12 daily_status fields, 5/5 budgets fields, 3/3 totals fields, 9/9 status item fields)

---

## 6. Temuan Mismatch & Issues

### Mismatch #1 — 🔴 CRITICAL: `ApiClient` Missing `put()`, `delete()`, `patch()`

**File:** `lib/core/network/api_client.dart` L82–104  
**Dampak:** Blocker untuk semua CRUD operations

Backend memerlukan:
- `PUT` → 3 routes (transactions, categories, budget-periods)
- `DELETE` → 4 routes (transactions, categories, budget-periods, notifications)
- `PATCH` → 2 routes (notification history mark read)

**Rekomendasi:** Tambahkan method di `ApiClient`:
```dart
Future<ApiResponse> put(String path, {Object? body, ...}) => request('PUT', path, body: body, ...);
Future<ApiResponse> delete(String path, {...}) => request('DELETE', path, ...);
Future<ApiResponse> patch(String path, {Object? body, ...}) => request('PATCH', path, body: body, ...);
```

---

### Mismatch #2 — 🔴 CRITICAL: 30 dari 31 Endpoint Belum Diimplementasi di Flutter

Backend memiliki **31 endpoint** (termasuk endpoint dari 6 route groups), Flutter hanya mengimplementasi **1 endpoint**. Ini termasuk seluruh CRUD untuk transactions, categories, budget-periods, auth flows, receipt scanning, dan notifications.

---

### Mismatch #3 — 🟡 MEDIUM: Auth Response Format — Flutter Belum Ada Normalization

**Backend (`authController.js:35–49`)** selalu mengembalikan format:
```json
{ "message": "...", "data": { "token": "...", "user": { "id", "name", "email" } } }
```

Flutter `AuthSession` dan `AuthUser` sudah bisa handle ini, TAPI:
- Flutter belum punya `AuthRepository` yang memanggil endpoint auth
- Perlu memastikan parsing `response.body['data']['token']` dan `response.body['data']['user']`

---

### Mismatch #4 — 🟡 MEDIUM: `AuthUser.email` Nullability

**Backend:** `user.email` selalu ada (NOT NULL di DB: `string("email", 190).notNullable()`)  
**Flutter:** `AuthUser.email` bertipe `String` (non-null) — ✅ correct  
**Tapi:** `ProfileScreen` (L403) menggunakan `session.user.email ?? '...'` — unnecessary null check

---

### Mismatch #5 — 🟡 MEDIUM: Category Type Mismatch — Backend Mendukung `"both"`

**Backend (`categoryController.js:6`):**
```javascript
const categoryType = z.enum(["income", "expense", "both"]);
```

**Flutter:** Belum ada Category model. Saat implementasi, pastikan support untuk type `"both"` selain `"income"` dan `"expense"`.

---

### Mismatch #6 — 🟡 MEDIUM: Endpoint yang Belum Terdeteksi Sebelumnya

Dibandingkan dengan web frontend, backend memiliki endpoint **tambahan** yang belum digunakan di web frontend manapun:

| Endpoint | Method | Deskripsi |
|----------|--------|-----------|
| `/api/transactions/mutation-scan` | `POST` | Multi-file scan mutasi bank |
| `/api/budget-periods/:id/daily-statuses` | `GET` | Batch daily statuses (range) |
| `/api/budget-periods/invest-savings` | `GET` | Investment savings summary |
| `/api/budget-periods/:id/set-default` | `POST` | Set default budget period |
| `/api/categories/:id` | `GET` | Get single category by ID |

---

### Mismatch #7 — 🟡 LOW: Pagination Support

**Backend:** Semua list endpoints (`GET /api/transactions`, `GET /api/categories`, `GET /api/budget-periods`) support optional `page` dan `limit` query params. Jika disediakan, response tambah `meta` object:
```json
{
  "data": [...],
  "meta": { "page": 1, "limit": 10, "total": 50, "totalPages": 5 }
}
```

**Flutter:** Belum ada pagination support di `ApiClient` atau repository layer.

---

### Mismatch #8 — 🟡 LOW: Transaction Response Includes Joined Fields

**Backend** (`transactionController.js:81–95`) mengembalikan transaction dengan JOIN fields:
- `category_name` (dari table categories)
- `budget_period_name` (dari table budget_periods)
- `latitude`, `longitude` (nullable geolocation)

Flutter Transaction model belum ada — saat implementasi perlu meng-cover semua field ini.

---

## 7. Database Schema Reference

Dari migration files (`src/database/migrations/`):

### 7.1 `users` Table

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| `id` | `increments` (int PK) | NO | auto |
| `name` | `string(150)` | NO | — |
| `email` | `string(190)` UNIQUE | NO | — |
| `password` | `string(255)` | YES* | — |
| `firebase_uid` | `string(255)` UNIQUE | YES | — |
| `auth_provider` | `string(50)` | YES | — |
| `created_at` | `timestamp` | NO | `now()` |

*password nullable untuk Google-only users

### 7.2 `categories` Table

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| `id` | `increments` (int PK) | NO | auto |
| `user_id` | `int unsigned` FK→users | NO | — |
| `name` | `string(100)` | NO | — |
| `type` | `string(20)` | NO | `"expense"` |

### 7.3 `transactions` Table

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| `id` | `increments` (int PK) | NO | auto |
| `user_id` | `int unsigned` FK→users | NO | — |
| `category_id` | `int unsigned` FK→categories | NO | — |
| `budget_period_id` | `int unsigned` FK→budget_periods | YES | — |
| `type` | `string(20)` | NO | — |
| `amount` | `decimal(14,2)` | NO | — |
| `note` | `text` | YES | — |
| `date` | `date` | NO | — |
| `latitude` | `decimal(10,7)` | YES | — |
| `longitude` | `decimal(10,7)` | YES | — |
| `created_at` | `timestamp` | NO | `now()` |

### 7.4 `budget_periods` Table

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| `id` | `increments` (int PK) | NO | auto |
| `user_id` | `int unsigned` FK→users | NO | — |
| `category_id` | `int unsigned` FK→categories | YES | — |
| `name` | `string(150)` | NO | — |
| `total_budget` | `decimal(14,2)` | NO | — |
| `start_date` | `date` | NO | — |
| `end_date` | `date` | NO | — |
| `daily_budget_base` | `decimal(14,2)` | NO | — |
| `working_days_count` | `int` | NO | — |
| `excluded_weekdays` | `text` (JSON string) | YES | `"[0,6]"` |
| `budget_system` | `string(30)` | YES | `"nothing"` |
| `is_default` | `boolean` | NO | `false` |
| `created_at` | `timestamp` | NO | `now()` |

---

## 8. Model Flutter yang Perlu Dibuat

### 8.1 Transaction Model

```dart
class Transaction {
  final int id;
  final int userId;
  final int categoryId;
  final int? budgetPeriodId;
  final String type;           // 'income' | 'expense'
  final double amount;
  final String? note;
  final String date;            // 'YYYY-MM-DD'
  final double? latitude;
  final double? longitude;
  final String? categoryName;   // JOIN field
  final String? budgetPeriodName; // JOIN field
  final DateTime createdAt;
}
```

### 8.2 Category Model

```dart
class Category {
  final int id;
  final String name;
  final String type;  // 'income' | 'expense' | 'both'
}
```

### 8.3 BudgetPeriod Model

```dart
class BudgetPeriod {
  final int id;
  final int userId;
  final int? categoryId;
  final String? categoryName;
  final String? categoryType;
  final String name;
  final double totalBudget;
  final double dailyBudgetBase;
  final String startDate;
  final String endDate;
  final int workingDaysCount;
  final List<int> excludedWeekdays;
  final String budgetSystem;    // 'carry_over' | 'invest' | 'nothing'
  final bool isDefault;
  final DateTime createdAt;
}
```

### 8.4 CreateTransaction Request

```dart
class CreateTransactionRequest {
  final int categoryId;
  final int? budgetPeriodId;
  final String type;
  final double amount;
  final String? note;
  final String date;
  final double? latitude;
  final double? longitude;
}
```

---

## 9. Daftar File yang Diperiksa

### 9.1 Flutter Files (21 files)

| # | File | Status |
|---|------|--------|
| 1 | `lib/main.dart` | ✅ Reviewed |
| 2 | `lib/core/config/app_config.dart` | ✅ OK |
| 3 | `lib/core/network/api_client.dart` | ⚠️ Missing PUT/DELETE/PATCH |
| 4 | `lib/core/network/api_exception.dart` | ✅ OK |
| 5 | `lib/core/auth/auth_session.dart` | ⚠️ Minor (email nullability) |
| 6 | `lib/core/auth/auth_controller.dart` | ✅ OK |
| 7 | `lib/core/storage/key_value_storage.dart` | ✅ OK |
| 8 | `lib/core/storage/secure_key_value_storage.dart` | ✅ OK |
| 9 | `lib/core/providers.dart` | ✅ OK |
| 10 | `lib/features/dashboard/repositories/dashboard_repository.dart` | ✅ Contract verified |
| 11 | `lib/features/dashboard/providers.dart` | ✅ OK |
| 12 | `lib/features/dashboard/models/dashboard_data.dart` | ✅ Contract verified |
| 13 | `lib/features/dashboard/models/dashboard_totals.dart` | ✅ Contract verified |
| 14 | `lib/features/dashboard/models/dashboard_budgets.dart` | ✅ Contract verified |
| 15 | `lib/features/dashboard/models/dashboard_budget_status.dart` | ✅ Contract verified |
| 16 | `lib/features/dashboard/models/dashboard_daily_status.dart` | ✅ Contract verified |
| 17 | `lib/app/moneymate_app.dart` | ⚠️ Placeholder data, email null check |
| 18 | `lib/app/theme/moneymate_theme.dart` | ✅ No API impact |
| 19 | `test/core/network/api_client_test.dart` | ✅ Reviewed |
| 20 | `test/core/auth/auth_session_store_test.dart` | ✅ Reviewed |
| 21 | `test/widget_test.dart` | ✅ Reviewed |

### 9.2 Backend Files (20+ files)

| # | File | Endpoints Covered |
|---|------|-------------------|
| 1 | `src/app.js` | Route mounting, middleware |
| 2 | `src/routes/authRoutes.js` | 4 auth endpoints |
| 3 | `src/routes/dashboardRoutes.js` | 1 dashboard endpoint |
| 4 | `src/routes/transactionRoutes.js` | 7 transaction endpoints |
| 5 | `src/routes/categoryRoutes.js` | 5 category endpoints |
| 6 | `src/routes/budgetPeriodRoutes.js` | 8 budget endpoints |
| 7 | `src/routes/notificationRoutes.js` | 6 notification endpoints |
| 8 | `src/controllers/authController.js` | Auth logic, Zod schemas, response format |
| 9 | `src/controllers/dashboardController.js` | Dashboard response shape |
| 10 | `src/controllers/transactionController.js` | Transaction CRUD, receipt scan |
| 11 | `src/controllers/categoryController.js` | Category CRUD |
| 12 | `src/controllers/budgetPeriodController.js` | Budget CRUD, daily status, invest savings |
| 13 | `src/controllers/notificationController.js` | Push subscribe, history |
| 14 | `src/services/budgetService.js` | Daily status calculation (12 fields) |
| 15 | `src/middleware/auth.js` | JWT verification |
| 16 | `src/database/migrations/202604020001_create_core_tables.js` | DB schema |
| 17 | `src/database/migrations/...` (7 more) | Schema additions |

---

## 10. Rekomendasi Perbaikan

### 🔴 Prioritas 1 — Blocker (Harus sebelum Sprint 2)

| # | Action | Target File |
|---|--------|-------------|
| 1 | Tambahkan `put()`, `delete()`, `patch()` di ApiClient | `api_client.dart` |
| 2 | Buat `AuthRepository` (login, register, google, logout) | `lib/features/auth/` (baru) |
| 3 | Hubungkan `DashboardScreen` ke `dashboardProvider` | `moneymate_app.dart` |

### 🟡 Prioritas 2 — Sprint 2

| # | Action | Target File |
|---|--------|-------------|
| 4 | Buat `TransactionRepository` + model + provider | `lib/features/transactions/` |
| 5 | Buat `CategoryRepository` + model (include type `"both"`) | `lib/features/categories/` |
| 6 | Buat `BudgetRepository` + model + provider | `lib/features/budget/` |
| 7 | Implement pagination support di repository layer | All repositories |

### 🟢 Prioritas 3 — Sprint 3+

| # | Action | Target File |
|---|--------|-------------|
| 8 | Receipt scan (multipart upload) | `lib/features/transactions/` |
| 9 | Mutation scan (multi-file) | `lib/features/transactions/` |
| 10 | Notification subscribe/unsubscribe | `lib/features/notifications/` |
| 11 | Notification history + read/unread | `lib/features/notifications/` |
| 12 | Invest savings summary | `lib/features/budget/` |

---

## 11. Kesimpulan

### ✅ Yang Sudah Benar

1. **Dashboard contract 100% match** — semua 29 fields verified langsung dari backend source
2. **Auth interceptor** konsisten antara Flutter (`_isAuthEndpoint`) dan backend (route-level `authenticate`)
3. **Base URL default** sama (`http://localhost:3000`)
4. **Type safety** pada Flutter model parsing sangat robust (`_toDouble`, `_toInt`, null-safe)
5. **Arsitektur layering** Flutter sudah benar dan siap untuk scale

### ⚠️ Yang Perlu Diperbaiki

1. **ApiClient MISSING 3 HTTP methods** (PUT, DELETE, PATCH) — blocker
2. **30 dari 31 endpoint belum diimplementasi** — roadmap Sprint 2+
3. **6 endpoint di backend belum digunakan bahkan oleh web frontend** — perlu koordinasi
4. **Category type `"both"`** harus di-handle di Flutter model
5. **Pagination** harus ditambahkan di repository layer

### Risk Assessment

| Risk | Level | Note |
|------|-------|------|
| API contract mismatch saat add fitur | **LOW** | Dashboard sudah proven match; pattern bisa diikuti |
| Missing HTTP methods block CRUD | **HIGH** | Harus diperbaiki sebelum Sprint 2 |
| Category type `"both"` not handled | **LOW** | Mudah ditambahkan |
| Pagination missing | **MEDIUM** | Perlu untuk infinite scroll |

---

*Dokumen ini divalidasi langsung dari source code `moneymate-api` (commit terbaru). Update diperlukan jika backend berubah.*
