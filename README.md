# Sianetak (صيانتك)

Home maintenance marketplace for Aswan, Egypt. This repository holds the Sprint 1 and Sprint 2
increments: project foundation, customer phone OTP authentication, the guest service catalog,
customer service requests, technician onboarding, and admin verification.

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

## What Sprint 2 delivers

- **Service requests (FR-REQ-02…05).** A four-step flow — describe (with private photos), location
  (saved or new, optional current-location pin), schedule (ASAP or a server-offered slot in
  Africa/Cairo), review — then submit. Submission is idempotent, so a retried lost response never
  creates a duplicate. Customers see their request history and a detail view with the initial status.
- **Technician onboarding (FR-AUTH-06).** An application with specialties, service areas and optional
  verification documents, duplicate prevention, and a verification-status screen with resubmission
  after a rejection.
- **Admin verification (FR-AUTH-07).** A pending queue, an application detail with private documents,
  and approve / reject / suspend / reinstate with a required reason, recorded in an append-only audit
  log. Admin-only, enforced server-side.

See [docs/SPRINT_2_REPORT.md](docs/SPRINT_2_REPORT.md) for the full report, API changes and the
acceptance checklist, and screenshots in `docs/screenshots/`.

Sprint 3+ features (matching, dispatch, offers, tracking, chat, quotes, payments, ratings) are
**not** implemented.

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
npm run seed:catalog          # sample catalog + sample Aswan service areas, refuses to run in production
npm run user:create-staff -- --phone 01099999999 --role admin --name "Reviewer name"
npm run start:dev             # http://localhost:3000/api/v1

# 3. Customer app (another terminal)
cd ../mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
# Android emulator: use http://10.0.2.2:3000/api/v1
```

Check the API is up: `curl http://localhost:3000/api/v1/health`.

In development, the OTP screen displays the code returned by the stub, so you can sign in with
any valid Egyptian mobile number (`01012345678`). To demo all three Sprint 2 roles: create a
request as a customer, apply as a technician from another number, then review it from the admin
number created above (the admin screens live in the same app — use the web build for a desktop
reviewer).

See `backend/README.md` for the API reference, configuration and operator commands, and
`mobile/README.md` for the app's structure and conventions.

## Tests

```bash
cd backend && npm run lint && npm run typecheck && npm test && npm run test:e2e
cd ../mobile && flutter analyze && flutter test
```

Integration tests need PostgreSQL running and use the separate `sianetak_test` database.
