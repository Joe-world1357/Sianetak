# Sprint 2 Report — Sianetak (صيانتك)

Aswan home‑maintenance marketplace. Sprint 2 adds the three request‑and‑onboarding flows on top of
the Sprint 1 foundation: customers create service requests, technicians apply to join, and admins
verify those applications. Built on NestJS + PostgreSQL and the Flutter customer app, Arabic‑first
(RTL) with English.

Date: 23 Oct 2026 · Branch: `claude/project-thread-oakl4c` · Base: Sprint 1 (`71b0328`…).

---

## 1. Features delivered

### Customer: create a service request (FR‑REQ‑02…05)

A four‑step flow — **describe → location → schedule → review** — then a confirmation.

- **Describe.** A problem description (10–1000 chars) and up to N optional photos (default 5).
  Photos upload as they are picked, each with its own uploading / failed / uploaded state, retry
  and remove.
- **Location.** A saved address or a new one: a service area (required), free‑text details, an
  optional landmark, and an optional "use my current location" that attaches coordinates. New
  addresses can be saved for next time.
- **Schedule.** "As soon as possible", or a concrete time slot from the server’s offered windows,
  grouped by day in Africa/Cairo time.
- **Review & submit.** A summary with the service, photos, location, schedule and the pricing note
  (no fee is charged at submission). Submitting uses an idempotency key so a lost response, retried,
  never creates a second request. On success: a reference number (e.g. `SN‑261024‑AYWY6`) and a link
  to the request.
- **History & detail.** "My requests", newest first with keyset pagination, and a detail screen
  with the full description, private photos, location, pricing and a status timeline (initial status
  `submitted`).

### Technician: apply to join (FR‑AUTH‑06)

- An application form: full name, optional years of experience and bio, specialties (service
  categories), service areas, and optional verification documents (images; min count configurable,
  **default 0** — no documents are invented as mandatory).
- A verification‑status screen: pending, approved, rejected (with the reviewer’s reason) or
  suspended. A rejected applicant can correct and resubmit (the form is prefilled).
- Duplicate prevention: one application per account; a second submit of a pending application is
  rejected (`409 APPLICATION_ALREADY_SUBMITTED`).

### Admin: verify technicians (FR‑AUTH‑07)

- A queue filtered by status (pending / approved / rejected / suspended).
- An application detail with the applicant’s contact, specialties, areas, **private documents**
  (fetched with the admin’s credentials) and the full review history.
- Decisions: approve, reject (reason required, shown to the applicant), suspend (reason required),
  and reinstate a suspended technician. Approval grants the `technician` role. Every decision is
  written to an append‑only audit log with the reviewer and timestamp. Admin‑only, enforced server‑side.

Screenshots of the running app (web build against the live API) are in `docs/screenshots/`
(`sprint2-01`…`sprint2-08`).

---

## 2. Screens

| Flow | Screens |
|---|---|
| Customer request | Create request (describe / location / schedule / review), confirmation, my requests, request detail |
| Technician | Application form, verification status (with resubmission) |
| Admin | Application queue (status filter), application detail with decision dialogs |
| Shared | Private image viewer (credentialed byte fetch), profile entries by role |

Profile entry points are role‑aware: customers see **My requests** and **Join as technician**;
technicians see their **application status**; admins see **Review technician applications**.

---

## 3. API changes

Base path `/api/v1`. Error envelope unchanged: `{ "error": { "code", "message", "details" }, "requestId" }`.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/service-areas` | public | Active service areas |
| GET | `/requests/options` | public | Form rules: description bounds, photo limits, offered slots, areas, fee (null unless configured) |
| GET | `/me/addresses` | customer | Saved addresses |
| POST | `/me/addresses` | customer | Add a saved address (max 10) |
| DELETE | `/me/addresses/:id` | customer | Soft‑delete a saved address |
| POST | `/media` | customer / technician | Upload a private file (multipart `file` + `purpose`) |
| GET | `/media/:id/content` | owner or admin | Stream a private file |
| DELETE | `/media/:id` | owner | Remove an unattached upload |
| POST | `/requests` | customer | Create a request (`Idempotency-Key` header required) |
| GET | `/requests` | customer | The caller’s requests (keyset `cursor`) |
| GET | `/requests/:id` | customer (owner) | Request detail |
| GET/PUT | `/technician/application` | customer / technician | Own application (PUT submits or resubmits) |
| GET | `/admin/technician-applications` | admin | Queue (`status`, `limit`, `offset`) |
| GET | `/admin/technician-applications/:id` | admin | Application with contact + history |
| POST | `/admin/technician-applications/:id/approve` | admin | `{ note? }` |
| POST | `/admin/technician-applications/:id/reject` | admin | `{ reason }` |
| POST | `/admin/technician-applications/:id/suspend` | admin | `{ reason }` |

`POST /requests` returns `201` on creation, or `200` with an `Idempotent-Replayed: true` header when
a matching key is replayed.

---

## 4. Database

One migration, `1761350400000-RequestsAndOnboarding`, adds eleven tables and an append‑only audit
trigger:

`service_areas`, `customer_addresses` (soft delete), `media_files`, `service_requests`,
`service_request_photos`, `service_request_events`, `technician_profiles`,
`technician_specialties`, `technician_service_areas`, `technician_documents`, `audit_logs`.

Constraints enforce invariants in the database, not only in code: request status ∈ `{submitted}`,
schedule consistency (`asap` ⇒ no times; `scheduled` ⇒ `to > from`), coordinate ranges, currency
`EGP`, a reviewer that is never the applicant, a reason present for `rejected`/`suspended`, and
per‑customer idempotency uniqueness. `audit_logs` has a `BEFORE UPDATE OR DELETE` trigger that
raises, so the trail cannot be rewritten through SQL.

Seed data adds six sample Aswan service areas (`isSample`), alongside the Sprint 1 sample catalog.

---

## 5. Key files

```
backend/src/
  locations/   service areas, saved addresses, address resolution
  media/       upload, private storage (local disk in dev), credentialed streaming, metadata stripping
  requests/    options, create (idempotent, locked, validated), list, detail; slot rules
  technicians/ application submit/resubmit, review transitions, eligibility, approved-technician guard
  audit/       append-only audit service (global)
  database/migrations/1761350400000-RequestsAndOnboarding.ts
mobile/lib/
  core/device/        image picker and one-off location services
  core/widgets/private_image.dart   credentialed image fetch (bytes kept in memory)
  features/requests/  models, repository, draft controller, four-step flow, history, detail
  features/technician/ application form, verification status view
  features/admin/     application queue and review detail with decision dialogs
```

---

## 6. Tests, build and lint

All run on this machine; results are actual, not assumed.

| Suite | Command | Result |
|---|---|---|
| Backend unit | `npm test` | **101 passed** |
| Backend integration | `npm run test:e2e` | **117 passed** (5 suites, real PostgreSQL) |
| Backend lint / types / format | `npm run lint && npm run typecheck && npm run format:check` | clean |
| Backend build | `npm run build` | ok |
| Flutter analyzer | `flutter analyze` | **No issues found** |
| Flutter tests | `flutter test` | **91 passed** |
| Flutter format | `dart format --set-exit-if-changed lib test` | clean |
| Flutter web build | `flutter build web --release` | ok |

New Flutter coverage: the request draft controller (steps, photo upload/retry/remove, idempotency
key reuse, slot refresh on an expired slot, orphan cleanup), request/application model parsing, the
API client’s multipart upload / credentialed byte fetch / extra headers, and widget tests driving
the full request flow (photo failure + retry, denied camera, denied location, idempotent retry,
saved address, history and detail), the technician application and status/resubmit flows, and the
admin review flow (approve, reject‑with‑reason, cancel, reinstate, conflict) — each in Arabic RTL
and English.

New backend coverage: 45 request e2e tests and 25 technician/admin e2e tests, plus a log‑leak test
asserting requests, addresses and photos never appear in logs.

---

## 7. Live demo against the running API

The whole chain was exercised end‑to‑end against a running server (migrated, seeded, with a CLI
admin). Verified:

- A request submitted twice with the same `Idempotency-Key` → `201` then `200 Idempotent-Replayed`,
  **one** stored request, same reference.
- Another customer reading the request → `404`; its photo → `404`; unauthenticated → `401`; the
  owner’s photo served `Cache-Control: private, no-store`, `nosniff`.
- A technician application → `pending_review`; a second submit → `409`; a customer or the applicant
  reading the admin queue → `403`.
- Admin reject without a reason → `400`; reject with a reason → `rejected`, reviewer and timestamp
  recorded; admin reads the applicant’s document → `200`; resubmit → `200`; approve → `approved`,
  role becomes `technician`.
- Audit log holds submitted → rejected → resubmitted → approved; a `DELETE` on it raises
  *"audit_logs is append-only"*.

---

## 8. Security

- **Server‑side authorization only.** Deny‑by‑default guard; `@Roles` on every new controller; the
  user is reloaded per request so a suspension or role change applies immediately.
- **Private media.** Content is sniffed from bytes (JPEG/PNG/PDF only), image metadata (EXIF/XMP/
  IPTC, PNG text chunks) is stripped on upload, files are stored with restrictive permissions and
  opaque keys, and served only to the owner or an admin with `private, no-store` + `nosniff` + a CSP
  sandbox. Non‑owners get `404`, never `403`, so existence is not disclosed.
- **No trust in the client.** Schedule slots, areas, idempotency and ownership are all re‑checked
  server‑side; the request is written in a transaction behind a per‑user advisory lock.
- **No secrets or sensitive data in logs** (verified by a test): no phone numbers, document bytes,
  tokens or SQL parameters.
- **No invented policy.** No mandatory documents, fees or legal requirements were introduced;
  document minimums, slot windows, the inspection fee and region bounds are all configurable and
  default to the least‑committal value (fee null, min documents 0).

---

## 9. Setup and how to demo

```bash
# Backend
cd backend
cp .env.example .env            # then set JWT_ACCESS_SECRET and OTP_PEPPER to two random values
npm install
npm run migration:run
npm run seed:catalog            # sample catalog + sample Aswan service areas
npm run user:create-staff -- --phone 01099999999 --role admin --name "Reviewer name"
npm run start:dev               # http://localhost:3000/api/v1

# Customer app (new terminal)
cd ../mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

In development the OTP code is shown on the sign‑in screen (stub provider), so any valid Egyptian
mobile number signs in. To demo all three roles: sign in as a customer and create a request; sign in
as another number and apply as a technician; sign in as the admin number above and review the
application. The admin screens are reachable from the same app (use the web build for a desktop
reviewer).

---

## 10. Acceptance checklist

| # | Criterion | Status |
|---|---|---|
| 1 | Customer picks a service and describes the problem | **Pass** — describe step, 10–1000 chars |
| 2 | Customer attaches photos | **Pass** — up to N (configurable), private upload with retry |
| 3 | Customer provides a location | **Pass** — saved or new address, optional current‑location pin |
| 4 | Customer picks a schedule | **Pass** — ASAP or a server‑offered slot (Africa/Cairo) |
| 5 | Customer reviews and submits; sees a confirmation | **Pass** — review step + reference number |
| 6 | Submission is idempotent (no duplicate on retry) | **Pass** — idempotency key; verified live |
| 7 | Customer views request history and detail with initial status | **Pass** — my requests + detail timeline |
| 8 | Technician submits a profile (skills, areas, documents) | **Pass** — application form |
| 9 | Technician onboarding validates input and prevents duplicates | **Pass** — one per account, `409` on re‑submit |
| 10 | Technician sees a verification status screen | **Pass** — pending/approved/rejected/suspended + resubmit |
| 11 | Admin lists pending applications and inspects one | **Pass** — queue + detail with private documents |
| 12 | Admin approves or rejects with a reason | **Pass** — reason required for reject/suspend |
| 13 | Decisions are audited with reviewer and timestamp | **Pass** — append‑only audit log; verified live |
| 14 | Admin verification is admin‑only (server‑enforced) | **Pass** — `@Roles(admin)`; non‑admin `403` (verified) |

---

## 11. Known gaps and blockers

- **Single role per account.** An approved technician’s account becomes a technician; it no longer
  has the customer role, so it can’t also file customer requests. Multi‑role accounts are a product
  decision (D‑tbd) deferred.
- **PDF documents** can be uploaded (and are accepted server‑side) but are not previewed in the app;
  the mobile UI only picks images. Admins see a "PDF — preview not available in the app" placeholder.
- **No cancellation.** Customers can’t cancel a request yet (policy D‑04 open); status is only
  `submitted` this sprint.
- **No orphan‑media purge job.** Unattached uploads are cleaned on normal flows (abandoned draft,
  removed photo) but there is no background sweep yet.
- **`ApprovedTechnicianGuard`** is implemented and unit‑tested but unused — it guards Sprint 3 work
  endpoints that don’t exist yet.
- **Blockers carried from Sprint 1 / infrastructure:** no SMS provider (dev OTP stub only), no object
  storage (media is local disk in development; production refuses local), and no maps provider (hence
  a coordinate capture, not a map pin). These need business/infra decisions before production.

Out of scope by design: matching, dispatch, offers, tracking, chat, quotes, payments and ratings
(Sprint 3–4).
