# Sianetak backend

NestJS + PostgreSQL modular monolith. Scope through Sprint 2: configuration and foundation, customer
phone OTP authentication with roles, the guest service catalog, customer service requests, private
media, technician onboarding, and admin verification with an audit trail.

## Layout

```
src/
  config/      environment validation (fails fast on bad configuration)
  common/      error format, request logging, Egyptian phone handling
  database/    TypeORM options, migrations, sample catalog + areas seed, safe SQL logger
  users/       user entity, roles, /me profile endpoints
  auth/        OTP rules, challenges, tokens, guards, SMS port
  catalog/     categories and services, guest and admin read endpoints
  locations/   service areas, saved customer addresses, address resolution
  media/       private uploads: byte sniffing, metadata stripping, credentialed streaming
  requests/    service requests: options, idempotent create, list, detail; slot rules
  technicians/ applications: submit/resubmit, review transitions, eligibility, approved-tech guard
  audit/       append-only audit log (global)
  health/      /health readiness probe
test/          API integration tests against a real database
```

The schema is defined by migrations; `synchronize` is never enabled. Every write that spans rows
(request creation, a review decision) runs in a transaction, and request creation additionally takes
a per-user advisory lock so concurrent submits with the same idempotency key cannot race.

Conventions: controllers validate and present, services hold business rules, entities and
migrations define the schema. `synchronize` is never enabled — every schema change is a migration.
Money is stored as integer minor units (piastres) with an explicit currency.

## Configuration

Copy `.env.example` to `.env`. Startup fails with a list of offending variable names (never their
values) if anything is invalid. Highlights:

| Variable | Notes |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_ACCESS_SECRET`, `OTP_PEPPER` | ≥32 chars, must differ from each other |
| `OTP_PROVIDER` | `dev` (development stub) or `none`. `dev` is rejected in production |
| `OTP_DEV_EXPOSE_CODE` | Returns the code in the API response; ignored unless provider is `dev` |
| `OTP_TTL_SECONDS`, `OTP_MAX_VERIFY_ATTEMPTS`, `OTP_RESEND_COOLDOWN_SECONDS`, `OTP_MAX_REQUESTS_PER_HOUR` | **[Proposed]** defaults (300s, 5, 60s, 5) — confirm with product and security |
| `THROTTLE_GLOBAL_PER_MINUTE`, `THROTTLE_AUTH_PER_MINUTE` | Per-IP limits |
| `MEDIA_STORAGE` | `local` (disk, development) or `none`. `local` is rejected in production — wire object storage first |
| `MEDIA_LOCAL_DIR`, `MEDIA_MAX_IMAGE_BYTES`, `MEDIA_MAX_DOCUMENT_BYTES`, `MEDIA_MAX_PENDING_PER_USER` | Local media dir and limits (defaults 5 MB image, 10 MB document, 20 pending) |
| `REQUEST_TIME_ZONE`, `REQUEST_SLOT_WINDOWS`, `REQUEST_SCHEDULE_LEAD_MINUTES`, `REQUEST_SCHEDULE_DAYS_AHEAD` | Scheduling: time zone (Africa/Cairo), offered windows, lead time, horizon |
| `REQUEST_MAX_PHOTOS`, `REQUEST_MAX_OPEN_PER_CUSTOMER` | Request limits (defaults 5 and 5) |
| `INSPECTION_FEE_MINOR` | Inspection fee in piastres; **empty by default** — no fee is invented |
| `SERVICE_REGION_BOUNDS` | Lat/long bounds for accepted coordinates (default around Aswan) |
| `TECHNICIAN_MIN_DOCUMENTS`, `TECHNICIAN_ALLOW_RESUBMIT` | Required documents (**default 0**) and whether a rejected applicant may resubmit |

## Commands

```bash
npm run start:dev                 # development server
npm run build && npm start        # production build
npm run migration:run             # apply migrations
npm run migration:revert          # roll back the last migration
npm run seed:catalog              # sample catalog + sample Aswan service areas (refuses to run in production)
npm run user:create-staff -- --phone 01012345678 --role admin --name "Reviewer name"
npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Self sign-up always creates a **customer**. The **admin** role is granted only by
`user:create-staff`. The **technician** role is granted only by approving a technician application
(Sprint 2) — the CLI no longer grants it, so a technician never bypasses verification.

## API

Base path `/api/v1`. Errors always look like:

```json
{ "error": { "code": "OTP_EXPIRED", "message": "…", "details": {} }, "requestId": "…" }
```

Clients should branch on `code`, not on `message`, and render their own localized copy.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | public | Readiness, including a database check |
| GET | `/catalog/categories` | public | Active categories with active service counts |
| GET | `/catalog/categories/:slug` | public | Category with its active services |
| GET | `/catalog/services/:slug` | public | Service detail and pricing guidance |
| POST | `/auth/otp/request` | public | `{ phone }` → challenge (`devCode` only with the stub) |
| POST | `/auth/otp/verify` | public | `{ challengeId, phone, code }` → tokens + user |
| POST | `/auth/refresh` | public | Rotates a refresh token |
| POST | `/auth/logout` | public | Revokes a refresh token |
| GET | `/me` | bearer | Signed-in profile |
| PATCH | `/me` | bearer | `{ name }` |
| GET | `/admin/catalog/categories` | bearer, admin | Catalog including inactive entries |
| GET | `/service-areas` | public | Active service areas |
| GET | `/requests/options` | public | Form rules: description bounds, photo limits, offered slots, areas, fee (null unless configured) |
| GET / POST | `/me/addresses` | customer | List / add saved addresses (max 10) |
| DELETE | `/me/addresses/:id` | customer | Soft-delete a saved address |
| POST | `/media` | customer / technician | Upload a private file (multipart `file` + `purpose`) |
| GET | `/media/:id/content` | owner or admin | Stream a private file (`private, no-store`) |
| DELETE | `/media/:id` | owner | Remove an unattached upload |
| POST | `/requests` | customer | Create a request (`Idempotency-Key` header required) |
| GET | `/requests` | customer | The caller's requests (keyset `cursor`) |
| GET | `/requests/:id` | customer (owner) | Request detail with status timeline |
| GET / PUT | `/technician/application` | customer / technician | Own application (PUT submits or resubmits) |
| GET | `/admin/technician-applications` | admin | Queue (`status`, `limit`, `offset`) |
| GET | `/admin/technician-applications/:id` | admin | Application with contact + history |
| POST | `/admin/technician-applications/:id/approve` | admin | `{ note? }` — grants the technician role |
| POST | `/admin/technician-applications/:id/reject` | admin | `{ reason }` |
| POST | `/admin/technician-applications/:id/suspend` | admin | `{ reason }` |

`POST /requests` returns `201` on creation, or `200` with an `Idempotent-Replayed: true` header when
a matching key is replayed.

Phone numbers are accepted as `01…`, `+20…`, `0020…` or `20…`, with spaces, dashes and
Arabic-Indic digits, and normalized to E.164.

## Security notes

- Authentication is deny-by-default: a global guard protects every route not marked `@Public()`.
- The role in a JWT is never trusted; the user is reloaded per request, so suspensions and role
  changes apply immediately.
- OTP codes are stored only as an HMAC bound to the challenge id and phone, compared in constant
  time, single-use, and invalidated when a newer code is issued.
- Rate limiting is layered: per-phone cooldown and hourly cap (in the database, serialized with an
  advisory lock) plus per-IP throttling. The IP throttle store is in memory — move it to Redis
  before running more than one instance.
- Refresh tokens are stored hashed and rotated; reusing a rotated token revokes the whole family.
- Logs contain no phone numbers, OTP codes, tokens or SQL parameters. `SafeTypeOrmLogger` exists
  specifically because TypeORM's default logger prints query parameters on failure.
- **Private media.** Uploads are type-checked by sniffing the bytes (JPEG/PNG/PDF only), image
  metadata (EXIF/XMP/IPTC, PNG text chunks) is stripped, files are stored with restrictive
  permissions under opaque keys, and content is served only to the owner or an admin. A non-owner
  gets `404`, not `403`, so the file's existence is never disclosed.
- **Audit trail.** Every verification decision is appended to `audit_logs`, which has a database
  trigger that rejects `UPDATE` and `DELETE` — the trail cannot be rewritten through SQL.
- **No invented policy.** Document minimums, slot windows, the inspection fee and region bounds are
  configuration, defaulting to the least-committal value (fee empty, min documents 0); no mandatory
  documents, fees or legal requirements are hard-coded.
