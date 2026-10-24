# Sianetak app (standalone demo)

Flutter app for Android and iOS. It runs entirely on the device: there is no server, no OTP and
no network dependency. Data lives in a local JSON database that is seeded with demo accounts, a
sample catalog for Aswan and a couple of sample requests.

## Demo accounts

Sign in by picking an account on the sign-in screen. Switch accounts from the Account tab.

| Role | Name | What it can do |
|------|------|----------------|
| Customer | أحمد محمود | Browse services, submit and track requests, approve or reject quotes, chat, pay cash, rate |
| Technician | محمد علي | Accept or decline offers, move a job through en route / arrived / quote / complete, see earnings |
| Admin | منى حسن | Dashboard KPIs, assign unmatched requests, review technician applications |

Account > "Reset demo data" wipes the database and restores the seed.

## Layout

```
lib/
  core/
    storage/   LocalStore (JSON document + change notifications) and the file backend
    theme/     design tokens; widgets/ shared UI pieces and loading/empty/error states
  demo/        seed data, DemoBackend (the business rules the server used to own), DemoApp wiring
  features/
    auth/      demo sign-in, AuthController, Account screen
    catalog/   home, category and service detail screens
    requests/  request form, list, detail, quote/cancel/rating sheets, chat
    jobs/      technician offers, jobs and earnings
    technician/ application and verification status
    admin/     dashboard, technician review, manual assignment
    notifications/ in-app alerts
    shell/     role-based bottom navigation
  l10n/        app_ar.arb (template) and app_en.arb
```

Presentation, domain and data stay separate. Each repository keeps its abstract interface; the
`Local*` implementations call `DemoBackend`, which returns the same JSON shapes and error codes as
the old API, so models and screens did not need to change. Screens refresh themselves when the
store changes (`AsyncView.refreshOn`).

Demo rules (in `demo/demo_seed.dart`, marked [Proposed] in the requirements): offers go to up to 3
matching technicians and expire after 15 minutes, the first to accept wins, work starts only after
the customer approves the quote, payment is cash with a 10% commission.

## Running

```bash
flutter pub get
flutter run            # Android device or emulator
flutter build apk      # release APK in build/app/outputs/flutter-apk/
```

## Language and layout

Arabic is the default locale and the UI mirrors to RTL; English is one tap away in the app bar.
Layout uses directional spacing, phone numbers are forced LTR inside Arabic text, and Cairo is
bundled (SIL OFL) so Arabic renders consistently offline. New strings go in both ARB files.

## Tests

```bash
flutter analyze
flutter test
```

`test/demo` covers the local backend rules (dispatch, offer races, quote gate, payment, permissions)
and two full Customer → Technician → Admin journeys through the real UI. `test/unit` and
`test/widget` cover formatting, models, the auth controller and each screen through fakes.
