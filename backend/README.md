# Sianetak backend

NestJS + PostgreSQL modular monolith. Sprint 1 scope: configuration and foundation, customer
phone OTP authentication with roles, and the guest service catalog.

## Layout

```
src/
  config/      environment validation (fails fast on bad configuration)
  common/      error format, request logging, Egyptian phone handling
  database/    TypeORM options, migrations, sample catalog seed, safe SQL logger
  users/       user entity, roles, /me profile endpoints
  auth/        OTP rules, challenges, tokens, guards, SMS port
  catalog/     categories and services, guest and admin read endpoints
  health/      /health readiness probe
test/          API integration tests against a real database
```

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

## Commands

```bash
npm run start:dev                 # development server
npm run build && npm start        # production build
npm run migration:run             # apply migrations
npm run migration:revert          # roll back the last migration
npm run seed:catalog              # sample catalog (refuses to run in production)
npm run user:create-staff -- --phone 01012345678 --role admin
npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Self sign-up always creates a **customer**. Technician and admin roles are granted only by
`user:create-staff` until technician onboarding and the admin dashboard exist (Sprint 2+).

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
