# Sianetak (صيانتك)

Home maintenance marketplace for Aswan, Egypt. This repository holds the Sprint 1 increment:
project foundation, customer phone OTP authentication, and the guest service catalog.

> **Current state: standalone local app.** This is a school project, so the mobile app runs
> entirely on the device with its own local database and real local accounts (phone + hashed
> password) for Customers, Technicians and Administrators. It starts empty: no sample users or
> records. It no longer needs the backend or OTP. See [`mobile/README.md`](mobile/README.md). The
> `backend/` folder is kept as the reference implementation of the Sprint 1/2 API rules.

```
backend/   NestJS + PostgreSQL API (modular monolith)
mobile/    Flutter customer app (Arabic RTL by default, English available)
.github/   CI: lint, typecheck, unit and integration tests for both
```

## What Sprint 1 delivers

- **Foundation.** Validated environment configuration, PostgreSQL with TypeORM migrations,
  a consistent error format, safe request logging, lint/format/test tooling, and CI.
- **Authentication (FR-AUTH-01, 03, 04, 05).** Customer sign-in by phone OTP with expiry,
  attempt limits, per-phone and per-IP rate limiting, rotating refresh tokens, and server-side
  role enforcement for customer, technician and admin.
- **Catalog (FR-AUTH-02, FR-REQ-01, FR-REQ-06).** Guests browse categories and service details
  with approved pricing guidance, in Arabic RTL or English, with loading, empty and error states.

Sprint 2 and later features (request creation, technician onboarding, dispatch, quotes, payments)
are **not** implemented.

## Important limitation: OTP delivery

**No SMS provider is integrated.** `OTP_PROVIDER=dev` is a development-only stub that logs the
code locally and returns it in the API response; the server refuses to start with it in
production. With `OTP_PROVIDER=none` the sign-in endpoint answers `503 OTP_DELIVERY_UNAVAILABLE`
rather than pretending a message was sent. A real gateway must be added in
`backend/src/auth/sms/` before sign-in works outside development.

## Sample catalog data

The seeded categories and services are **sample data** pending decisions D-01 (final catalog) and
D-02 (pricing). Every seeded row is flagged `isSample`, the app shows a "sample data" badge, and
every seeded service uses `inspection_required` pricing — no EGP amounts are invented. The schema
and UI fully support approved indicative price ranges once operations configures them.

## Run it locally

Requires Node.js 20+, Docker (or a local PostgreSQL 14+), and the Flutter SDK.

```bash
# 1. Database
cd backend
docker compose up -d db

# 2. Backend
cp .env.example .env
# Generate two different secrets and paste them into .env:
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
npm install
npm run migration:run
npm run seed:catalog          # sample catalog, refuses to run in production
npm run start:dev             # http://localhost:3000/api/v1

# 3. Customer app (another terminal)
cd ../mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
# Android emulator: use http://10.0.2.2:3000/api/v1
```

Check the API is up: `curl http://localhost:3000/api/v1/health`.

In development, the OTP screen displays the code returned by the stub, so you can sign in with
any valid Egyptian mobile number (`01012345678`).

See `backend/README.md` for the API reference, configuration and operator commands, and
`mobile/README.md` for the app's structure and conventions.

## Tests

```bash
cd backend && npm run lint && npm run typecheck && npm test && npm run test:e2e
cd ../mobile && flutter analyze && flutter test
```

Integration tests need PostgreSQL running and use the separate `sianetak_test` database.
