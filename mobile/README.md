# Pediatric Health Hub — Mobile (Flutter)

A Flutter client for the existing Pediatric Health Hub platform. It talks to the
**same Node/Express + Prisma backend** as the React web app (`../backend`), which
owns the MySQL database — the app never touches MySQL directly. Colours,
typography, radii and spacing are lifted from the web app's Tailwind v4 tokens so
both clients read as one product.

**Stack:** Flutter 3.35 · Riverpod · Dio · go_router · flutter_secure_storage ·
shared_preferences · google_fonts (Inter) · intl

---

## 1. Setup

```bash
# 1. Start the backend (from the repo root)
cd backend
npm install
npx prisma generate
npx prisma migrate deploy      # or: npx prisma db push
node prisma/seed.js            # creates the four test accounts below
npm run dev                    # listens on PORT (default 3000)

# 2. Run the app
cd ../mobile
flutter pub get
flutter run                    # defaults to the Android emulator base URL
```

### Pointing the app at your backend

The base URL lives in one place — [`lib/config/api_config.dart`](lib/config/api_config.dart) —
and is overridable at build time with `--dart-define`, so you never have to edit
code to switch targets.

| Target | Base URL | Command |
|---|---|---|
| **Android emulator** (default) | `http://10.0.2.2:3000/api/v1` | `flutter run` |
| **iOS simulator / desktop** | `http://localhost:3000/api/v1` | `flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1` |
| **Physical device** (same Wi‑Fi) | `http://<LAN_IP>:3000/api/v1` | `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api/v1` |

`10.0.2.2` is the Android emulator's alias for the host machine's loopback —
inside the emulator, `localhost` means the emulator itself. Find your LAN IP with
`hostname -I` (Linux), `ipconfig` (Windows) or `ipconfig getifaddr en0` (macOS).
The active endpoint is shown on the login screen and in Profile → API endpoint,
so you can always confirm what a build is pointing at.

### Platform configuration already applied

- **Android** — `INTERNET` and `ACCESS_NETWORK_STATE` permissions, plus
  `android:usesCleartextTraffic="true"` so plain-HTTP local development works
  ([`AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml)). Remove the
  cleartext flag before shipping against an HTTPS backend.
- **iOS** — `NSAppTransportSecurity` with `NSAllowsLocalNetworking` and a
  `localhost` exception, plus `NSLocalNetworkUsageDescription`
  ([`Info.plist`](ios/Runner/Info.plist)). iOS needs no INTERNET permission.

### Verify

```bash
flutter pub get
flutter analyze     # 0 issues
dart format lib/ test/
flutter test        # boot smoke test
```

There is also a **live end-to-end test** that drives the real Riverpod providers
and repositories against a running backend — it signs in as all four seeded
roles, books and cancels an appointment, completes a vaccine dose and
creates/deletes a chatbot template:

```bash
# with the backend running:
flutter test test/live_backend_test.dart \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

It self-skips when the backend is unreachable, so a plain `flutter test` still
passes on a machine with no server. It creates rows named `ZZTest Harness` /
`ZZ Harness Vaccine`; delete them afterwards if you care about a clean database.

No code generation is used — models are hand-written null-safe `fromJson`
factories, so there is no `build_runner` step and no generated files to keep in
sync.

---

## 2. Seeded test accounts

From [`../backend/prisma/seed.js`](../backend/prisma/seed.js):

| Role | Email | Password |
|---|---|---|
| Admin | `admin@pediatric-hub.com` | `admin123` |
| Doctor | `doctor@pediatric-hub.com` | `doctor123` |
| Parent | `parent@pediatric-hub.com` | `parent123` |
| Facility | `facility@pediatric-hub.com` | `facility123` |

The seeder also upserts six chatbot keyword templates (fever, cough, vomiting,
diarrhea, rash, vaccination).

### Optional seeds — otherwise these screens are legitimately empty

`prisma/seed.js` does **not** populate the vaccine protocol or the content
tables, so on a fresh database:

| Empty table | Screen that looks empty | Fix |
|---|---|---|
| `VaccineTemplate` | Vaccine tracker — “Sync schedule” returns nothing | `node backend/seed_vaccines.js` |
| `EducationalContent` | Health education | add rows via `POST /education` (ADMIN) |
| `EmergencyContact` | Emergency guidance | add rows via `POST /emergency` (ADMIN) |
| `HealthService` | Doctor detail → Services | add them in the Facility portal |

`Child`, `Appointment` and `Notification` also start empty — add a child in the
app and the dashboards fill in. (Vaccine notifications are produced by the daily
cron once doses exist.)

Note the seeded passwords do **not** satisfy the
registration password policy (8+ chars, letter, number, symbol) — that rule only
applies to `POST /auth/register`, `POST /auth/reset-password` and `POST /users`,
not to seeded rows.

---

## 3. Folder structure

```
lib/
├── main.dart                      ProviderScope + MaterialApp.router
├── config/
│   ├── api_config.dart            base URL, timeouts, public (no-auth) paths
│   └── theme/
│       ├── app_colors.dart        Tailwind @theme colours + AppPalette extension
│       ├── app_dimens.dart        radii, spacing, shadows, control heights
│       └── app_theme.dart         light/dark ThemeData built from those tokens
├── core/
│   ├── errors/api_exception.dart  normalises { status, message, errors[] }
│   ├── network/api_client.dart    Dio + JWT interceptor + refresh-on-401
│   ├── router/
│   │   ├── app_routes.dart        every path in one place
│   │   └── app_router.dart        go_router with auth guard + role redirects
│   ├── storage/auth_storage.dart  tokens → secure storage, user → prefs
│   ├── utils/                     formatters (intl) and validators (mirror Zod)
│   └── widgets/                   AppCard, AsyncView, StatusBadge, StatTile, …
├── data/
│   ├── models/                    null-safe models mirroring the Prisma schema
│   └── repositories/              one class per backend domain
└── presentation/
    ├── providers/                 Riverpod DI, auth controller, data providers
    └── screens/
        ├── auth/                  login, register, forgot password, verify email
        ├── parent/ doctor/ facility/ admin/
        ├── shared/                screens used by more than one role
        └── shell/                 bottom-tab portal per role
```

**Architecture notes**

- **State:** Riverpod. `AuthController` (a `StateNotifier`) owns the session;
  every list screen is an `autoDispose` `FutureProvider` refreshed with
  `ref.refresh(provider.future)` from a `RefreshIndicator`.
- **HTTP:** a single `Dio` instance attaches `Authorization: Bearer <jwt>` to
  every non-public request. On a 401 it calls `POST /auth/refresh-token` once
  with the stored refresh token and replays the original request; if that fails
  the session is cleared and the router redirects to `/login`. (The web app never
  uses the refresh endpoint — it just logs you out.)
- **Response contract:** all endpoints except payments answer
  `{ status, message, data }`, so `ApiClient` unwraps `data` for you. The payment
  endpoints bypass that wrapper and are read from the raw response.
- **Routing:** `go_router` with a redirect that gates on auth status and keeps
  each role inside its own portal (`/parent/…`, `/doctor/…`, `/facility/…`,
  `/admin/…`).
- **Null safety:** no `!` on any API-derived value; the `Json.*` helpers coerce
  missing or odd fields to safe defaults, so one bad row cannot crash a screen.
- **Every screen** has explicit loading, empty and error states, and every list
  screen supports pull-to-refresh.

---

## 4. Endpoint → screen map

Every call below was read from `backend/src/routes/*` — nothing is invented.

### Auth
| Method | Endpoint | Screen |
|---|---|---|
| POST | `/auth/login` | Login |
| POST | `/auth/register` | Register (all four roles) |
| GET | `/auth/profile` | Splash (session check), Profile |
| POST | `/auth/forgot-password` | Forgot password — step 1 (emails a 6-digit OTP) |
| POST | `/auth/reset-password` | Forgot password — step 3 (`token` = the OTP) |
| POST | `/auth/verify-email` | Verify email |
| POST | `/auth/refresh-token` | Dio interceptor (silent) |

### Parent
| Method | Endpoint | Screen |
|---|---|---|
| GET | `/dashboard/telemetry` | Parent dashboard |
| GET | `/children/my-children` | Dashboard, Children, Book appointment |
| POST | `/children` | Add child |
| GET | `/children/:id` | Child detail |
| PUT | `/children/:id` | Edit child |
| GET | `/vaccinations/child/:childId` | Vaccine tracker, child detail, dashboard |
| POST | `/vaccinations/child/:childId/generate` | Vaccine tracker → “Sync schedule” |
| PATCH | `/vaccinations/:id/status` | Vaccine tracker → “Mark as completed” |
| GET | `/health-records/child/:childId/baseline` | Health records (allergies/meds/illnesses) |
| POST | `/health-records/allergies` | Health records → Add allergy |
| POST | `/health-records/medications` | Health records → Add medication |
| POST | `/health-records/illnesses` | Health records → Add illness |
| GET | `/health-records/child/:childId/consultations` | Health records → Consultations tab |
| GET | `/growth/child/:childId` | Growth log |
| POST | `/growth` | Growth log → Add measurement |
| GET | `/parent-info?childId=` | Child detail → Guardians |
| POST | `/parent-info` | Child detail → Add guardian |
| DELETE | `/parent-info/:id` | Child detail → Remove guardian |
| GET | `/users/doctors` | Find a doctor, Book appointment |
| GET | `/doctors/:id` | Doctor detail |
| GET | `/health-services/by-facility/:facilityId` | Doctor detail → Services |
| GET | `/appointments/my-schedule` | Appointments, dashboard, teleconsult |
| POST | `/appointments` | Book appointment |
| GET | `/appointments/:id` | Appointment detail |
| PATCH | `/appointments/:id/status` | Appointment detail → Cancel |
| POST | `/chatbot/session` | PediaBot (start / new chat) |
| POST | `/chatbot/:sessionId/chat` | PediaBot (send) |
| GET | `/chatbot/:sessionId/history` | PediaBot (load conversation) |
| GET | `/chatbot/sessions` | PediaBot → History |
| POST | `/chatbot/:sessionId/close` | PediaBot → New chat |
| GET | `/payments` | Payments |
| POST | `/payments` | Payments → Pay with EVC Plus |
| PUT | `/parents/:id` | Profile → Edit |

### Doctor
| Method | Endpoint | Screen |
|---|---|---|
| GET | `/dashboard/telemetry` | Doctor dashboard |
| GET | `/appointments/my-schedule` | Dashboard, Schedule, Teleconsult |
| PATCH | `/appointments/:id/status` | Schedule (approve/reject), Appointment detail |
| GET | `/children` | Patients |
| GET | `/children/:id` | Patient detail |
| GET | `/health-records/child/:childId/baseline` | Patient detail → Overview |
| GET | `/health-records/child/:childId/consultations` | Patient detail → Notes |
| POST | `/health-records/consultations` | Patient detail → New note |
| POST | `/health-records/medications` | Patient detail → Prescribe |
| GET · PATCH | `/vaccinations/child/:id` · `/vaccinations/:id/status` | Patient detail → Vaccines |
| GET | `/growth/child/:childId` | Patient detail → Growth |
| POST · GET · PATCH | `/teleconsultations/generate` · `/:appointmentId` · `/:appointmentId/end` | Teleconsult |
| PUT | `/doctors/:id` | Profile → Edit |

### Facility
| Method | Endpoint | Screen |
|---|---|---|
| GET | `/facilities/my-scope` | Facility dashboard (counts, staff, services, appointments, patients) |
| GET | `/doctors` | Clinical staff (auto-scoped to the facility) |
| POST · PUT · DELETE | `/doctors` · `/doctors/:id` | Staff → Add / Edit / Archive |
| GET | `/health-services` | Services |
| POST · PUT · DELETE | `/health-services` · `/health-services/:id` | Services → Add / Edit / Archive |
| GET | `/appointments/my-schedule` | Appointments overview |
| PATCH | `/appointments/:id/status` | Appointments → Approve / Reject |
| PUT | `/facilities/:id` | Profile → Edit |

### Admin
| Method | Endpoint | Screen |
|---|---|---|
| GET | `/admin/telemetry` | Admin dashboard |
| GET | `/dashboard/telemetry` | Admin dashboard → 6-month chart |
| GET | `/admin/users` | User management |
| POST | `/admin/users/suspend` | User management → Suspend / Reactivate |
| POST | `/users` | User management → New user |
| PUT | `/users/:id/role` | User management → Change role |
| DELETE | `/users/:id` | User management → Delete |
| GET | `/admin/audits` | Audit log |
| GET · POST · DELETE | `/chatbot/templates` · `/chatbot/templates/:id` | Chatbot templates |

### Shared
| Method | Endpoint | Screen |
|---|---|---|
| GET | `/notifications` | Notifications (badge in every portal header) |
| PATCH | `/notifications/:id/read` | Notifications |
| GET | `/education` | Health education |
| GET | `/emergency` | Emergency guidance |

---

## 5. Backend changes made for this app

Three endpoints were extended so requested mobile features had real APIs behind
them. These are the only backend edits:

1. **Parents can cancel their own appointments.**
   `PATCH /appointments/:id/status` now accepts `PARENT` in `authorize(...)`;
   the controller restricts parents to `status: 'CANCELLED'` on an appointment
   belonging to one of their own children (403 otherwise).
   → `routes/appointment.routes.js`, `controllers/appointment.controller.js`

2. **Parents can check a dose off as completed.**
   `PATCH /vaccinations/:id/status` now accepts `PARENT`; the controller
   restricts parents to `status: 'COMPLETED'` on their own child's dose.
   → `routes/vaccination.routes.js`, `controllers/vaccination.controller.js`

3. **Chatbot templates can be listed and deleted.**
   Added `GET /chatbot/templates` and `DELETE /chatbot/templates/:id` (ADMIN),
   alongside the existing upsert `POST /chatbot/templates`.
   → `routes/chatbot.routes.js`, `controllers/chatbot.controller.js`,
   `services/chatbot.service.js`

---

## 6. Backend gaps and quirks worth knowing

Found while reading the backend; none are blocking, but they shape what the app
can and cannot do.

1. **`PATCH /vaccinations/:id/notes` is a no-op.**
   `services/vaccination.service.js` has the update commented out and just
   re-reads the row, so notes never persist — the app therefore displays vaccine
   notes but does not offer editing. The `notes` column does exist in the
   migration, so re-enabling it is a one-line change.

2. **`GET /children/:id` has no ownership check.** Any authenticated user can
   read any child by id (`child.routes.js` uses bare `authenticate`). The app
   only ever requests children the user legitimately reached, but this is worth
   tightening server-side.

3. **No per-article endpoint.** `GET /education` returns the published list and
   there is no `GET /education/:id`, so the article view renders the row already
   fetched with the list.

4. **Admins have no profile record.** There is no `AdminProfile` model and no
   admin profile-update endpoint, so the admin Profile screen is read-only
   account info.

5. **No delete-child endpoint.** `child.routes.js` exposes create, read and
   update only — the app offers no delete.

6. **Doctor search only matches `lastName`.** `doctor.service.js` builds
   `where.lastName = { contains: search }`, so the doctor browse screen filters
   name/specialisation/facility on the client on top of the server call.

7. **`POST /auth/register` returns the verification token in the response body**
   rather than emailing it (`auth.service.js` says so explicitly). The app
   forwards that token to the Verify email screen. Only the *password reset* flow
   actually sends mail (a 6-digit OTP via Gmail SMTP).

8. **Payments bypass the response wrapper.** `POST /payments` returns
   `{ success, data, message }` with **HTTP 402** on a decline, and `GET /payments`
   returns a bare `{ data }`. Handled specially in `SupportRepository`.

9. **Socket.IO is WebRTC signalling only, and its CORS is pinned to
   `http://localhost:5173`.** The app therefore manages teleconsultation *room
   state* (open / status / end) but does not join video calls; that stays in the
   web app. Adding mobile video would need `flutter_webrtc` plus widening the
   Socket.IO origin list in `backend/src/server.js`.

10. **The web page `ManageChatbotTemplates.jsx` calls `/admin/chatbot/templates`,
    which does not exist** (and the page isn't routed in `App.jsx`). The real
    endpoints are under `/chatbot/templates` — which is what the mobile admin
    screen uses.

11. **Vaccine statuses are `UPCOMING` / `DUE` / `COMPLETED` / `MISSED`** — there
    is no `PENDING` or `OVERDUE`. Transitions are driven by the daily cron in
    `backend/src/cron/vaccineCron.js`: `UPCOMING → DUE` inside a 7-day window, and
    `UPCOMING|DUE → MISSED` more than 7 days past the scheduled date. That cron
    also generates the vaccine notifications shown in the app.

12. **`POST /users` creates a bare account.** It makes a `User` row (already
    email-verified) but no `ParentProfile`/`DoctorProfile`/`FacilityProfile`, so
    such accounts sign in with an empty profile. The admin create-user sheet says
    so inline.
