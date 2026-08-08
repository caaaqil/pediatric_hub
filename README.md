# Pediatric Health Hub

A pediatric healthcare platform for parents, doctors, facilities and administrators —
a Node/Express + Prisma + PostgreSQL backend with a React web client and a Flutter
mobile client that both talk to the same API and the same database.

```
pediatric-health-hub/
├── backend/    Node.js + Express + Prisma (PostgreSQL), JWT auth, Socket.IO
├── frontend/   React 19 + Vite + Tailwind v4
└── mobile/     Flutter (Riverpod, Dio, go_router)
```

Setting it up from scratch:

- **Windows 10/11** → [Windows setup](#windows-10-setup-step-by-step) (start here)
- **Linux / macOS** → [Linux & macOS setup](#linux--macos-setup)

---

## Windows 10 setup, step by step

Everything below is run in **PowerShell**. Open it from the Start menu — you do
not need Administrator except where noted.

### 1. Install the tools

Install these four, in any order. Accept the default options unless noted.

| Tool | Download | Notes |
|---|---|---|
| **Git** | [git-scm.com/download/win](https://git-scm.com/download/win) | Needed to clone the repo |
| **Node.js 20 LTS** | [nodejs.org](https://nodejs.org) | Pick the **LTS** installer, not "Current" |
| **PostgreSQL 16** | [postgresql.org/download/windows](https://www.postgresql.org/download/windows/) | See step 2 — **write the password down** |
| **Flutter 3.35+** | [docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows) | Only if you want the mobile app |

Close and reopen PowerShell after installing, then check they are on your PATH:

```powershell
git --version
node --version      # v20.x or newer
```

### 2. Install PostgreSQL

Run the installer from the table above. Two screens matter:

- **Password** — this is the password for the `postgres` superuser.
  **Write it down**; you cannot recover it later, only reset it.
- **Port** — leave it at **5432**.

You can untick *Stack Builder* at the end; it is not needed.

> **Want to skip installing PostgreSQL altogether?** Create a free Postgres on
> [Render](https://render.com), copy its **External Database URL**, and paste that
> into `DATABASE_URL` in step 5 instead. Then jump straight to step 4 — no local
> database, and your laptop and the deployed app share one dataset.

Now check `psql` works. The installer usually does **not** add it to PATH, so use
the full path:

```powershell
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" --version
```

If that path does not exist, look under `C:\Program Files\PostgreSQL\` for your
version number and use that instead. To avoid typing the full path every time,
add the `bin` folder to PATH for the current session:

```powershell
$env:Path += ";C:\Program Files\PostgreSQL\16\bin"
psql --version
```

### 3. Create the database

```powershell
psql -U postgres -c "CREATE DATABASE pediatric_hub;"
```

It prompts for the password you set in step 2. Success prints `CREATE DATABASE`.

Verify it exists:

```powershell
psql -U postgres -l
```

`pediatric_hub` should be in the list.

> Prefer clicking? **pgAdmin 4** was installed alongside PostgreSQL — open it,
> connect to *PostgreSQL 16*, right-click **Databases → Create → Database**, name
> it `pediatric_hub`, save.

### 4. Clone the project

```powershell
cd $HOME\Documents
git clone https://github.com/caaaqil/pediatric_hub.git
cd pediatric_hub
```

### 5. Configure the backend

`backend\.env` is **not** in the repository — it holds live credentials. Either
ask the project owner to send you the completed file, or start from the template:

```powershell
cd backend
Copy-Item .env.example .env
notepad .env
```

Set these two at minimum:

```ini
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/pediatric_hub"
JWT_SECRET=any_long_random_string_you_like
```

`YOUR_PASSWORD` is the one from step 2. If it contains `@`, `:`, `/` or `#`, it
must be percent-encoded (`@` → `%40`, `#` → `%23`) or the URL will not parse.

⚠️ **Windows-only gotcha:** if your `.env` contains a `PRISMA_CLI_BINARY_TARGETS`
line, delete it or comment it out. It pins Prisma to a Linux engine and
`prisma generate` will produce a client that cannot run on Windows.

The AI, email and payment keys are optional — the app runs without them. Only the
chatbot, password-reset email and payments need them.

### 6. Start the backend

```powershell
npm install
npx prisma generate
npx prisma migrate deploy      # creates all 30 tables
node prisma\seed.js            # creates the four test accounts below
npm run dev
```

You should see `🚀 Server running on port 3000`. Leave this window open and check
[http://localhost:3000/api/health](http://localhost:3000/api/health) in a
browser — it should return `{"status":"success",...}`.

Optional extra content:

```powershell
node seed_vaccines.js          # national vaccine protocol (otherwise the tracker is empty)
```

The first time you run `npm run dev`, Windows Firewall may ask whether to allow
Node.js. Allow it on **Private networks** — without that, a phone on your Wi-Fi
cannot reach the backend.

### 7. Start the web client

Open a **second** PowerShell window (leave the backend running in the first):

```powershell
cd $HOME\Documents\pediatric_hub\frontend
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) and sign in with one of the
test accounts below.

### 8. Run the mobile app (optional)

```powershell
cd $HOME\Documents\pediatric_hub\mobile
flutter doctor      # fix anything it flags before continuing
flutter pub get
flutter run
```

`flutter doctor` will usually ask you to install **Android Studio** and accept the
SDK licences:

```powershell
flutter doctor --android-licenses
```

For a quick look without setting up Android at all, run it in a browser:

```powershell
flutter run -d chrome
```

The API address is chosen automatically — `10.0.2.2` on an Android emulator,
`localhost` on Chrome/Windows. For a **physical phone on the same Wi-Fi**, find
your laptop's IP with `ipconfig` (the *IPv4 Address* under your Wi-Fi adapter) and
pass it:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api/v1
```

You can also change it inside the app: the login screen has an **API endpoint**
card with a **Change** button, and the value is remembered between launches.

### Windows troubleshooting

| Problem | Fix |
|---|---|
| `psql : The term 'psql' is not recognized` | Not on PATH — use the full path, or run `$env:Path += ";C:\Program Files\PostgreSQL\16\bin"` |
| `password authentication failed for user "postgres"` | Wrong password in `DATABASE_URL`, or a special character that needs percent-encoding |
| `Can't reach database server at localhost:5432` | The service is stopped. Run `Get-Service postgresql*`, then `Start-Service postgresql-x64-16` in an **Administrator** PowerShell |
| `EADDRINUSE: address already in use :::3000` | Something already holds the port: `netstat -ano \| findstr :3000`, then `taskkill /PID <the-number> /F` |
| Prisma errors about a query engine / `debian-openssl` | `PRISMA_CLI_BINARY_TARGETS` is set in `.env` — remove that line, delete `node_modules\.prisma`, run `npx prisma generate` again |
| Phone can't reach the backend | Same Wi-Fi? Firewall allowing Node on Private networks? Test `http://<laptop-ip>:3000/api/health` in the phone's browser first |
| `npm install` fails on `bcrypt` | Install [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) with the *Desktop development with C++* workload, then retry |

---

## Linux & macOS setup

You need **Node.js 18+**, **PostgreSQL 14+**, and (for the mobile app)
**Flutter 3.35+**.

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

Then open `.env` and set at minimum `DATABASE_URL` (see the next step) and
`JWT_SECRET` (any long random string). The AI and payment keys are optional — the
app runs without them; only the chatbot and payments need them.

### 3. Database (PostgreSQL)

The project uses PostgreSQL. The easiest route needs nothing installed: create
a free Postgres on [Render](https://render.com), copy its **External Database
URL**, and paste it into `backend/.env` as `DATABASE_URL`.

Or run one locally:

```bash
# Debian/Ubuntu — skip if PostgreSQL is already installed
sudo apt install postgresql postgresql-contrib

sudo -u postgres psql -c "ALTER ROLE postgres WITH PASSWORD 'YOUR_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE pediatric_hub;"
```

```
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/pediatric_hub"
```

### 4. Backend

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate deploy      # creates all 30 tables
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

## Deploying so the app works on any network

Running the backend on your laptop means the phone must share your Wi-Fi and you
must retype the laptop IP whenever it changes. Deploying gives one fixed HTTPS
URL that works from anywhere, including mobile data.

`render.yaml` in the repo root describes the whole setup — the API plus a free
PostgreSQL database.

### 1. Create the services

In Render: **New → Blueprint**, connect this repository. Render reads
`render.yaml`, creates `pediatric-hub-api` and `pediatric-hub-db`, and wires
`DATABASE_URL` between them automatically.

The build runs `prisma migrate deploy` and `prisma/seed.js`, so the tables and
the four test accounts are created on first deploy. Both are safe to re-run.

### 2. Add the secrets

In the service's **Environment** tab, fill in the values marked `sync: false`:
`GEMINI_API_KEY`, `GROQ_API_KEY`, `SMTP_EMAIL`, `SMTP_PASSWORD`,
`WAAFIPAY_MERCHANT_UID`, `WAAFIPAY_API_USER_ID`, `WAAFIPAY_API_KEY`. `JWT_SECRET`
is generated by Render.

If you deploy the web client too, set `CLIENT_ORIGINS` to its URL so Socket.IO
(teleconsultation signalling) accepts it.

### 3. Point the clients at it

Once Render shows a URL such as `https://pediatric-hub-api.onrender.com`:

```bash
# Mobile — build once, then it works on any network
cd mobile
flutter build apk --release \
  --dart-define=API_BASE_URL=https://pediatric-hub-api.onrender.com/api/v1

# Web
echo 'VITE_API_URL=https://pediatric-hub-api.onrender.com/api/v1' > frontend/.env
```

You can also switch address without rebuilding: the login screen has an **API
endpoint** card with a **Change** button, and the value is remembered.

### Free-tier caveat

A free Render service **sleeps after ~15 minutes idle**, and the next request
takes roughly 50 seconds to wake it. Open the app a minute before a demo, or move
to a paid instance to remove the delay.

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
