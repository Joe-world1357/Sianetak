# Sianetak customer app

Flutter customer app. Scope through Sprint 2: guest catalog browsing, service details with pricing
guidance, phone OTP sign-in, service requests, technician onboarding, and admin verification.

## Layout

```
lib/
  core/        config, API client, theme tokens, shared state widgets, localization plumbing
    device/    image picker and one-off location services (abstracted for tests)
    widgets/   state views, private_image (credentialed byte fetch, kept in memory)
  features/
    catalog/    domain models, repository, home / category / service detail screens
    auth/       phone rules, auth models, token store, AuthController, sign-in / OTP / profile
    requests/   models, repository, draft controller, four-step flow, history, detail
    media/      private upload models and repository
    technician/ application form and verification-status view
    admin/      technician application queue and review detail
  l10n/        app_ar.arb (template) and app_en.arb; generated code under l10n/generated is committed
```

Dependencies are provided through `AppScope`, so widget tests inject fakes (repositories, image
picker, location) instead of touching the network or platform channels. Business rules live on the
server; the app validates input for fast feedback and renders what the API returns.

Presentation, domain and data are kept separate (NFR-MNT-01). Business rules live on the server;
the app validates input for fast feedback and renders what the API returns. Dependencies are
provided through `AppScope`, so tests inject fakes instead of hitting the network.

## Running

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

`API_BASE_URL` defaults to `http://localhost:3000/api/v1`. On an Android emulator the host machine
is `10.0.2.2`. Generated localizations are produced by `flutter gen-l10n` and committed under
`lib/l10n/generated`; regenerate after changing the ARB files.

The app requests camera, photo-library and location permissions at the point of use (attaching a
request or document photo, or the optional "use my current location"). The platform manifests
(`AndroidManifest.xml`, `Info.plist`) declare these plus `INTERNET`. A release web build is produced
with `flutter build web --release`.

## Language and layout

Arabic is the default locale and the UI mirrors to RTL automatically; English is one tap away in
the app bar. Layout uses directional spacing (`EdgeInsetsDirectional`, `AlignmentDirectional`), so
nothing is hard-coded to the left or right. Phone numbers and OTP codes are wrapped in Unicode
isolate marks and forced LTR so they read correctly inside Arabic text. Cairo is bundled
(SIL OFL, see `assets/fonts/OFL.txt`) so Arabic renders consistently offline.

New user-facing strings go in `lib/l10n/app_ar.arb` **and** `lib/l10n/app_en.arb`; never hard-code
display text in a widget.

## Error handling

The API's stable error codes are mapped to localized copy in one place,
`core/widgets/state_views.dart` (`messageForError`). Every screen that loads data handles loading,
empty and error states, with retry where a retry makes sense.

## Tests

```bash
flutter analyze
flutter test
```

`test/unit` covers phone normalization, money formatting, model parsing (requests and
applications), the API client (JSON, multipart upload, credentialed byte fetch, extra headers),
the auth controller, and the request draft controller (steps, photo upload/retry/remove,
idempotency-key reuse, slot refresh on an expired slot, orphan cleanup). `test/widget` drives the
real screens through fakes: the full OTP sign-in flow, the four-step request flow (photo failure and
retry, denied camera, denied location, idempotent retry, saved address, history and detail), the
technician application and status/resubmit flows, and the admin review flow (approve,
reject-with-reason, cancel, reinstate, conflict) — each in Arabic RTL and English.
