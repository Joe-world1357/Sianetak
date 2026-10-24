# Sianetak app (standalone, local database)

Flutter app for Android and iOS. It runs entirely on the device: there is no server, no OTP and
no network dependency. Everything is kept in a local database in the app's private storage.

A fresh install contains **only the service catalog and the Aswan service areas**. There are no
sample users, technicians, requests, reviews, chats or notifications: every record is created by
someone using the app.

## First run

1. Welcome pages (once per device), then the sign-in screen.
2. **Set up the administrator.** While the device has no administrator, the sign-in screen shows
   "إعداد حساب المسؤول" (Set up the administrator). It creates the first admin once; after that
   the link disappears and only an administrator can add another (Account → Add an administrator).
3. **Create accounts.** "أنشئ حساباً" (Create an account) offers *Customer* or *Technician*.
   Administrators can never sign up.
4. A technician fills in the application (specialties, areas, optional documents) and sees only
   that until an administrator approves it under *Technicians*. Approved technicians get job
   offers and jobs; suspended or rejected ones are blocked by the data layer, not just the UI.

## Accounts and security

- Sign in with an Egyptian mobile number and password (Arabic-Indic digits accepted).
- Passwords: at least 8 characters with a letter and a digit, stored only as salted
  PBKDF2-HMAC-SHA256 hashes (60,000 iterations, run off the UI thread). Never in plaintext.
- One phone number per account. Wrong number and wrong password fail the same way; 5 failures
  lock that number for 5 minutes [Proposed].
- Sessions persist across restarts, slide forward on each launch and expire after 30 days unused.
  Sign-out (with confirmation) ends the session. Change password needs the current one.

## Workflows

| Role | What it can do |
|------|----------------|
| Customer | Browse services, create requests (photos, saved addresses, schedule), track status, chat with the assigned technician, approve or reject quotes, cancel, rate completed work |
| Technician | Apply, see verification status, accept or decline offers, move a job through on the way → arrived → quote → completed (cash recorded), see earnings |
| Admin | Dashboard, review / approve / reject / suspend technicians, assign requests nobody accepted, add administrators |

Rules (in `local/initial_data.dart`, [Proposed] where marked): offers go to up to 3 approved
technicians covering the category and area and expire after 15 minutes; the first to accept wins;
with nobody eligible or after every offer lapses the request waits for an admin to assign it;
work starts only after the customer approves the quote; payment is cash with a 10% commission.

## Limitations (honest ones)

- **One device, one database.** All roles share the device. Notifications and chat reach other
  accounts only on this same phone, and there is no sync between phones.
- No SMS, push notifications, online payment, maps or live location: these need a server or a
  provider. Location is an optional one-off pin from the phone's GPS.
- No password recovery (there is no channel to verify identity offline). An administrator can
  add a new admin, but cannot reset passwords.
- The previous demo build kept sample data in `sianetak_demo/` in app storage; this version
  leaves that folder untouched and starts clean in `sianetak_data/`. An unreadable or older
  database file is kept as `db.backup-<time>.json`, never deleted.

## Layout

```
lib/
  core/
    security/  PasswordHasher (salted PBKDF2-SHA256)
    storage/   LocalStore (JSON document, atomic writes, sessions) and the file backend
    theme/     design tokens; widgets/ shared UI pieces and loading/empty/error states
  local/       initial data, LocalBackend (validation, permissions, state transitions), wiring
  features/
    auth/      onboarding, sign-in, sign-up, admin setup, change password, Account screen
    catalog/   home, category and service detail screens
    requests/  request form, list, detail, quote/cancel/rating sheets, chat
    jobs/      technician offers, jobs and earnings
    technician/ application and verification status
    admin/     dashboard, technician review, manual assignment
    notifications/ in-app alerts
    shell/     role-based navigation
  l10n/        app_ar.arb (template) and app_en.arb
```

Presentation, domain and data stay separate. Repositories keep abstract interfaces; the `Local*`
implementations call `LocalBackend`, which enforces every permission and state transition and
answers in the API's JSON shapes and error codes. Screens refresh when the store changes.

## Running

```bash
flutter pub get
flutter run                 # Android device or emulator
flutter build apk --debug   # build/app/outputs/flutter-apk/app-debug.apk
```

CI (`.github/workflows/android-apk.yml`) analyzes, tests, builds the debug APK, installs and
launches it on an emulator, and publishes it as `Sianetak.apk` on the `sianetak-debug` release.

## Language and layout

Arabic is the default locale and the UI mirrors to RTL; English is one tap away. Layout uses
directional spacing, phone numbers are forced LTR inside Arabic text, and Cairo is bundled
(SIL OFL) so Arabic renders consistently offline. New strings go in both ARB files.

## Tests

```bash
flutter analyze
flutter test
```

`test/local` covers the local backend (clean database, backups, registration, hashing, lock-out,
sessions, admin setup, technician gating, dispatch, offer races, quote gate, payment, privacy)
and full journeys from a clean install through the real UI: admin setup → technician applies →
admin approves → customer requests → offer → quote → completion → rating, admin assignment and
chat, and persistence across restarts. `test/unit` and `test/widget` cover each screen via fakes.
