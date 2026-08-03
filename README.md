# Pediatric Health Hub

A pediatric healthcare platform for parents, doctors, facilities and administrators —
a Node/Express + Prisma + MySQL backend with a React web client and a Flutter
mobile client that both talk to the same API and the same database.

```
pediatric-health-hub/
├── backend/    Node.js + Express + Prisma (MySQL), JWT auth, Socket.IO
├── frontend/   React 19 + Vite + Tailwind v4
└── mobile/     Flutter (Riverpod, Dio, go_router)
```

---

## Setting up on a new laptop

You need **Node.js 18+**, **MySQL 8**, and (for the mobile app) **Flutter 3.35+**.

### 1. Clone

```bash
git clone https://github.com/caaaqil/pediatric_hub.git
cd pediatric_hub
```

### 2. Environment file

`backend/.env` is **not** in this repository — it holds live credentials. Either
ask the project owner to send you the completed file, or start from the template:

```bash
cd backend
cp .env.example .env
```

Then open `.env` and set at minimum `DATABASE_URL` (your own MySQL password) and
`JWT_SECRET` (any long random string). The AI and payment keys are optional — the
app runs without them; only the chatbot and payments need them.

### 3. Database

```bash
mysql -u root -p -e "CREATE DATABASE pediatric_hub;"
```

Then edit `backend/.env`:

```
DATABASE_URL="mysql://root:YOUR_PASSWORD@localhost:3306/pediatric_hub"
```

### 4. Backend

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate deploy      # creates all 31 tables
node prisma/seed.js            # creates the four test accounts below
npm run dev                    # http://localhost:3000
```

Optional extra content:

```bash
node seed_vaccines.js          # national vaccine protocol (otherwise the tracker is empty)
```

### 5. Frontend (web)

```bash
cd frontend
npm install
npm run dev                    # http://localhost:5173
```

### 6. Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run                    # picks the right API host automatically
```

The API base URL resolves per platform — `10.0.2.2` on an Android emulator,
`localhost` on web/desktop. For a **physical phone**, pass your laptop's LAN IP
and keep the phone on the same Wi-Fi:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api/v1
```

See [`mobile/README.md`](mobile/README.md) for the full endpoint→screen map.

---

## Test accounts

Created by `backend/prisma/seed.js`:

| Role | Email | Password |
|---|---|---|
| Admin | `admin@pediatric-hub.com` | `admin123` |
| Doctor | `doctor@pediatric-hub.com` | `doctor123` |
| Parent | `parent@pediatric-hub.com` | `parent123` |
| Facility | `facility@pediatric-hub.com` | `facility123` |

---

## Credentials

`backend/.env` is intentionally **not** committed. It contains a Gmail app
password, live WaafiPay payment credentials, AI API keys, the JWT signing secret
and the database password. Use `backend/.env.example` as the template, or ask the
owner for the real file.

`POST /payments` calls the live WaafiPay API when real credentials are present —
any payment made in the app is a real transaction, not a simulation.

---

## Notes for whoever works on this next

- Vaccine statuses are `UPCOMING` / `DUE` / `COMPLETED` / `MISSED`; transitions are
  driven by the daily cron in `backend/src/cron/vaccineCron.js`.
- The web Health Education and Emergency Guidance pages hardcode their content in
  the component rather than reading the API; the Flutter app mirrors that content
  in `mobile/lib/data/static/`.
- The payment endpoints bypass the standard `{ status, message, data }` wrapper —
  `POST /payments` returns `{ success, data }` with HTTP 402 on decline.
