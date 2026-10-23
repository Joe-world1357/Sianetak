# Sianetak customer app

Flutter customer app. Sprint 1 scope: guest catalog browsing, service details with pricing
guidance, phone OTP sign-in, and a profile foundation.

## Layout

```
lib/
  core/        config, API client, theme tokens, shared state widgets, localization plumbing
  features/
    catalog/   domain models, repository, home / category / service detail screens
    auth/      phone rules, auth models, token store, AuthController, sign-in / OTP / profile
  l10n/        app_ar.arb (template) and app_en.arb; generated code is not committed
```

Presentation, domain and data are kept separate (NFR-MNT-01). Business rules live on the server;
the app validates input for fast feedback and renders what the API returns. Dependencies are
provided through `AppScope`, so tests inject fakes instead of hitting the network.

## Running

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

`API_BASE_URL` defaults to `http://localhost:3000/api/v1`. On an Android emulator the host machine
is `10.0.2.2`. Generated localizations are produced by `flutter gen-l10n` (run automatically by
`flutter run` and `flutter test`).

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

`test/unit` covers phone normalization, money formatting, model parsing, the API client and the
auth controller. `test/widget` drives the real screens through fakes: Arabic RTL rendering,
language switching, loading/empty/error states, the full OTP sign-in flow, wrong and expired
codes, the resend countdown, profile editing and sign-out.
