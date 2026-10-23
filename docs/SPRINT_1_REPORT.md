# Sprint 1 report — Sianetak (صيانتك)

**Date:** 23 October 2026
**Scope:** Sprint 1 — Foundation & Discover Services
**Increment:** `sianetak/` (local git repository, one commit, not pushed — no GitHub connection)

---

## 1. Summary of implemented features

### A. Project foundation
- NestJS 11 + TypeScript backend organized as a modular monolith (`config`, `common`, `database`,
  `users`, `auth`, `catalog`, `health`), with Flutter 3.47 customer app alongside it.
- Environment configuration is parsed and validated at startup. Invalid configuration aborts the
  boot with a list of offending variable **names** — values are never printed.
- PostgreSQL via TypeORM with a migration-only workflow (`synchronize` is never enabled). One
  migration creates users, OTP challenges, refresh tokens, categories and services, with database
  check constraints for phone format, roles, status, slugs and pricing consistency.
- Consistent error envelope `{ error: { code, message, details }, requestId }` across every
  endpoint, so clients branch on stable codes and render their own Arabic/English copy.
- Access logging limited to method, path, status, duration and request id. A custom TypeORM logger
  replaces the default one specifically because the default prints query parameters on failure.
- Tooling: ESLint, Prettier, Jest unit and integration suites, Flutter analyzer with extra lints,
  and a GitHub Actions workflow running all of it for both projects.
- Idempotent seed script for sample catalog data; refuses to run with `NODE_ENV=production`.

### B. Authentication (FR-AUTH-01, 03, 04, 05)
- Customer sign-in by Egyptian phone OTP. Numbers are accepted as `01…`, `+20…`, `0020…`, `20…`,
  with spaces, dashes and Arabic-Indic or Persian digits, and normalized to E.164.
- Codes are stored only as an HMAC bound to the challenge id and phone, compared in constant time,
  single-use, and invalidated as soon as a newer code is issued.
- Limits: 5-minute expiry, 5 verify attempts per challenge, 60-second resend cooldown, 5 requests
  per phone per hour (enforced in the database under a per-phone advisory lock so concurrent
  requests cannot bypass it), plus per-IP throttling on the OTP endpoints.
- Sessions use short-lived JWT access tokens and hashed, rotating refresh tokens; presenting an
  already-rotated token revokes the whole session family.
- Authentication is deny-by-default: a global guard protects every route not marked `@Public()`.
  The user is reloaded from the database on each request, so the role claim inside a token is
  never trusted and a suspension takes effect immediately.
- Roles `customer`, `technician` and `admin` exist and are enforced server-side. Self sign-up
  always creates a customer; elevated roles come only from an operator CLI.

### C. Service catalog (FR-AUTH-02, FR-REQ-01, FR-REQ-06)
- Guest endpoints for category listing, category detail with its services, and service detail.
- Pricing guidance is either an approved indicative range (integer piastres, EGP) or an explicit
  "price set after inspection" with an explanation of what happens next. Inconsistent rows fall
  back to inspection-required in both the API and the app — an unverified price is never shown.
- Inactive categories and services are hidden from guests; an admin-only read view includes them.

### D. UI/UX
- Arabic is the default language and the layout mirrors to RTL; English is one tap away. All copy
  lives in ARB files; nothing user-facing is hard-coded in a widget.
- Cairo is bundled (SIL OFL) so Arabic renders consistently offline, as NFR-UX-02 asks.
- Every data-loading screen handles loading, empty and error states, with retry and pull to
  refresh. API error codes map to localized copy in one place.
- Accessibility: 52px minimum button height, semantic headers and labels, live-region
  announcements for inline errors, icons excluded from the semantics tree, and layouts verified at
  1.6× text scaling. Phone numbers and OTP codes are wrapped in Unicode isolate marks so they read
  correctly inside Arabic text.

---

## 2. Important files

**Backend**

| File | Purpose |
|---|---|
| `backend/src/config/env.validation.ts` | Typed configuration, fail-fast validation, production guard on the OTP stub |
| `backend/src/database/migrations/1761264000000-InitialSchema.ts` | Full Sprint 1 schema with check constraints |
| `backend/src/database/safe-typeorm-logger.ts` | Logs failing SQL without its parameters |
| `backend/src/database/seeds/catalog.sample.ts` | Sample catalog, no invented prices |
| `backend/src/auth/otp.rules.ts` | Pure OTP rules: generation, hashing, usability, rate decisions |
| `backend/src/auth/auth.service.ts` | OTP request and verify, transactional with per-phone locking |
| `backend/src/auth/token.service.ts` | Refresh token rotation and reuse detection |
| `backend/src/auth/guards/jwt-auth.guard.ts`, `roles.guard.ts` | Deny-by-default auth, server-side roles |
| `backend/src/auth/sms/` | SMS port, development stub, factory that refuses it in production |
| `backend/src/catalog/catalog.service.ts`, `catalog.presenter.ts` | Catalog queries and pricing presentation |
| `backend/src/common/errors/http-exception.filter.ts` | Consistent error envelope |
| `backend/src/scripts/create-staff-user.ts` | Grants technician/admin roles |

**Mobile**

| File | Purpose |
|---|---|
| `mobile/lib/l10n/app_ar.arb`, `app_en.arb` | All user-facing copy, Arabic as the template |
| `mobile/lib/core/network/api_client.dart` | JSON client, error mapping, one-shot token refresh |
| `mobile/lib/core/widgets/state_views.dart` | Loading/empty/error views and error-code → copy mapping |
| `mobile/lib/core/theme/app_theme.dart` | Design tokens, Cairo, touch targets |
| `mobile/lib/features/auth/application/auth_controller.dart` | Session state, restore, refresh coalescing, sign-out |
| `mobile/lib/features/auth/domain/egypt_phone.dart` | Client-side phone normalization mirroring the server |
| `mobile/lib/features/auth/presentation/` | Sign-in, OTP with resend countdown, profile |
| `mobile/lib/features/catalog/presentation/` | Home, category, service detail, pricing guidance |

**Project**: `README.md`, `backend/README.md`, `mobile/README.md`, `CONTRIBUTING.md`,
`.github/workflows/ci.yml`, `backend/docker-compose.yml`.

---

## 3. Architecture and data changes

Client apps talk to one REST API (`/api/v1`) backed by PostgreSQL — the modular monolith the SRS
recommends. Order state, money and authorization are server-authoritative by construction: the
app holds no business rules.

One migration, `InitialSchema1761264000000`, creates:

| Table | Notes |
|---|---|
| `users` | id, phone (unique, E.164 check), name, role, status, phone_verified_at, last_sign_in_at |
| `otp_challenges` | HMAC of the code, attempts/max, expiry, consumed_at, invalidated_at |
| `refresh_tokens` | SHA-256 hash (unique), family id, expiry, revoked_at, cascade on user delete |
| `service_categories` | slug, bilingual name/description, icon key, sort order, is_active, is_sample |
| `services` | category FK (restrict), slug, bilingual text, pricing_type, price_min/max in piastres, currency, is_active, is_sample |

A database check constraint makes the two pricing shapes mutually exclusive: an `indicative`
service must carry a positive, ordered min/max range, and an `inspection_required` service must
carry none. Money is integer minor units everywhere; no floating point is used.

---

## 4. Commands to run the application

```bash
# Database
cd sianetak/backend && docker compose up -d db

# Backend
cp .env.example .env
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"   # run twice,
# paste the two different values into JWT_ACCESS_SECRET and OTP_PEPPER
npm install
npm run migration:run
npm run seed:catalog
npm run start:dev                 # http://localhost:3000/api/v1

# Customer app
cd ../mobile && flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
# Android emulator: http://10.0.2.2:3000/api/v1
```

Health check: `curl http://localhost:3000/api/v1/health`.
Grant an admin: `npm run user:create-staff -- --phone 01012345678 --role admin`.

---

## 5. Tests executed and actual results

All of the following were run in this environment on 23 October 2026.

| Command | Result |
|---|---|
| `npm run format:check` (backend) | Pass — all files match Prettier |
| `npm run lint` (backend) | Pass — no errors |
| `npm run typecheck` (backend) | Pass |
| `npm test` (backend unit) | **52 passed**, 7 suites |
| `npm run test:e2e` (backend integration, real PostgreSQL) | **46 passed**, 3 suites |
| `npm run build` (backend) | Pass |
| `dart format --set-exit-if-changed` (mobile) | Pass — no changes |
| `flutter analyze` | Pass — no issues |
| `flutter test` | **48 passed** |
| `flutter build web --release` | Pass |

What the integration tests actually cover: OTP issuance and hash-only storage; invalid phone
formats; resend cooldown and hourly cap with retry-after; four concurrent requests for one phone
(exactly one succeeds); supersession of an older code; sign-in of a new and a returning customer;
Arabic-Indic input; wrong code with remaining-attempt count; attempt lock-out that also rejects the
correct code; malformed codes counting as attempts; expired codes; replay of a consumed code;
challenge presented with a different phone; suspended accounts at sign-in and on a live token;
refresh rotation and reuse detection; expired refresh tokens; idempotent logout; missing, invalid,
expired, foreign-signed and wrong-type tokens; admin route access decided by the database role and
not by the token claim; catalog ordering, counts, inactive filtering, empty states, 404s, malformed
slugs, indicative pricing, database rejection of inconsistent pricing, and seed idempotency; and a
dedicated test that drives a full sign-in while capturing every log line and asserting the code,
phone number and tokens appear in none of them.

**Manual end-to-end verification.** The release web build of the app was driven against the real
backend and database in a browser: the Arabic home screen listed the six seeded categories with
service counts and sample badges; a category opened to its services; a service detail showed the
"price set after inspection" explanation; the request button sent the guest to sign-in; a code was
requested for `01099887766`, entered, and accepted; the app returned to the service detail signed
in. The user row and session were confirmed in PostgreSQL afterwards, and the server log contained
no phone number, code or token outside the single, clearly marked development-stub line.
Screenshots are in `docs/screenshots/`.

---

## 6. Acceptance criteria checklist

| # | Criterion | Result |
|---|---|---|
| 1 | Project starts using documented instructions | **Pass** — verified from a clean `.env`; migration, seed and server all ran |
| 2 | Guest can browse configured service categories | **Pass** — API and app, verified in the browser |
| 3 | Guest can open service details | **Pass** |
| 4 | Customer OTP authentication works in the supported environment | **Pass in development.** Blocked for production: no SMS provider exists |
| 5 | Expired/invalid OTP and auth error cases are handled | **Pass** — covered by tests and surfaced as localized copy |
| 6 | Protected endpoints enforce authentication and authorization | **Pass** — deny-by-default guard, role checks from the database |
| 7 | Roles are represented correctly | **Pass** — customer/technician/admin, with an operator CLI to grant |
| 8 | Catalog and authentication tests pass | **Pass** — 146 automated tests across both projects |
| 9 | Arabic RTL works on delivered screens | **Pass** — asserted in widget tests and confirmed in screenshots |
| 10 | Loading, empty and error states handled | **Pass** |
| 11 | No secrets or sensitive OTP information exposed in logs | **Pass** — enforced by a dedicated test and the custom SQL logger |
| 12 | No critical known Sprint 1 defect remains | **Pass** — see section 8 |
| 13 | CI runs successfully | **Written, not executed** — the workflow cannot run without a GitHub repository |

Sprint-plan criteria additionally met: guest sees pricing guidance (FR-REQ-06), and the app is
navigable in Arabic RTL for every delivered screen.

---

## 7. External setup still required

1. **SMS/OTP gateway (blocker for real sign-in).** Contract an Egyptian SMS provider, add an
   `OtpSender` implementation in `backend/src/auth/sms/`, and add its provider value to the config
   validation. Until then production sign-in is deliberately unavailable rather than fake.
2. **Catalog and pricing approval (D-01, D-02).** Operations must confirm the launch categories
   and services and decide which carry indicative prices. The sample rows are placeholders.
3. **OTP policy approval.** The current values are proposals: 6 digits, 5-minute expiry, 5
   attempts, 60-second resend, 5 per hour.
4. **GitHub repository.** Nothing is pushed. Connecting GitHub and creating a repository would let
   the CI workflow actually run.
5. **Hosting, managed PostgreSQL and secret storage** for a development/test environment, plus a
   Redis instance once more than one API instance runs (see below).
6. Not needed yet, but coming: maps, object storage and push notifications for Sprint 2+.

---

## 8. Known gaps and remaining work

No known critical or high-severity defects in the Sprint 1 increment. Open items, all deliberate:

- **Per-IP throttling is in-memory.** Correct on one instance; it must move to a shared Redis
  store before horizontal scaling. Per-phone OTP limits are in the database and already correct
  across instances.
- **No refresh-token or OTP cleanup job.** Expired rows accumulate. A scheduled purge is worth
  adding in Sprint 2.
- **Admin catalog access is read-only.** Editing the catalog (FR-ADM-04) belongs to the admin
  dashboard, which is not in Sprint 1 scope.
- **No technician or admin client.** Roles exist and are enforced; the apps that use them do not.
- **Account deletion, saved addresses and Google/Apple sign-in** are not implemented (FR-AUTH-04
  covers profile basics only; saved addresses arrive with request creation in Sprint 2).
- **Two defects were found and fixed during the sprint**, both caught by the tests written for
  them: a layout overflow in the category card at narrow widths, and a `setState` that returned a
  Future, which broke the error-state retry.

---

## 9. Recommended next step for Sprint 2

Start Sprint 2 with **request creation**, not technician onboarding — it is the step that turns
browsing into a marketplace and it exercises the parts most likely to surface design problems
(media upload, location, idempotency). Concretely, in this order:

1. Secure the SMS provider decision now, in parallel with engineering. It is the only thing
   standing between this increment and a usable pilot, and procurement takes longer than code.
2. Build request creation end to end: `orders` with a unique human-readable reference, description,
   photos through private object storage, address or map pin, and now-or-later scheduling — with
   an idempotency key so a retry on a flaky Aswan connection cannot create two jobs.
3. Then technician registration, documents and the admin verification queue, which is what makes
   the Sprint 3 dispatch work meaningful.

Before implementation starts, get decisions D-01 and D-02 signed off, so the catalog the request
form points at is real rather than sample data.
