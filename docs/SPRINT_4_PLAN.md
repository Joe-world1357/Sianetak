# Sprint 4 Plan — Sianetak (صيانتك)

Prepared 2 Nov 2026 · Branch `claude/project-thread-561x3b` (PR #6, merged 7 Nov 2026) · Base `main` @ `6320f71` (PR #5).
Closed out 7 Nov 2026 on branch `claude/project-thread-cuqefj` (final PR): see **Sprint close-out** at the end.
Jira-ready: every story has an ID, points, priority, acceptance criteria and dependencies.
`docs/sprint4_jira_import.csv` holds the same backlog for Jira's CSV importer.

## Scope reminder

Sianetak is a **school project**: a standalone Android app with real local accounts and an
on-device database (no server, no seed data). The school plan's Sprint 4 is **"Finish, test and
present"**: completion summary, a simulated payment record clearly labelled as demo-only, local
ratings, polish, fresh-install / restart / role-switch testing, reset instructions, a
presentation sequence and a known-limitations list. The SDLC plan's production items (staging,
monitoring, finance reconciliation service, go/no-go launch) stay out of scope, as in Sprints 2–3.

"Demo seed data" in the school plan conflicts with the standing rule that the app never ships
fake accounts or records (Joe, 24 Oct 2026). This sprint keeps that rule: instead of seed data, the
presenter creates the accounts live in about three minutes (`docs/DEMO_GUIDE.md`), and an admin
can erase the device to start the next run clean.

## Sprint goal

> A presenter can install the APK and show the complete journey (request → offer → quote →
> work → completion summary → rating → problem report → admin follow-up) on one phone, reset the
> phone afterwards from inside the app, and explain honestly what is simulated and what is not.

## Starting point (verified 2 Nov 2026)

Already in `main`: the full lifecycle through cash record, 10% commission and ratings; multi-role
accounts; technician availability; offer expiry; location pin; in-app notifications and chat.
118 Flutter tests passed at the start of the sprint.

## Capacity

[Proposed] Two weeks, one developer-equivalent plus product-owner time. Capacity **21 points**,
committed **20** (same as Sprint 3; there is still no Jira velocity history).

## Prioritized backlog

| ID | Story | Pts | Priority | Status | Depends on |
|----|-------|-----|----------|--------|------------|
| S4-01 | Completion summary on a finished request | 2 | Highest | **Done** in this PR | none |
| S4-02 | "Demo only, no money is processed" disclosure on the payment record | 1 | Highest | **Done** in this PR | S4-01 |
| S4-03 | Customer problem report after completion; admin queue and close-out | 5 | High | **Done** in this PR | none |
| S4-04 | Admin "erase all data on this device" (presenter reset) | 3 | High | **Done** in this PR | none |
| S4-05 | End-to-end regression: full journey, restart, reset (automated) | 3 | High | **Done** in this PR | S4-01…04 |
| S4-06 | Arabic RTL review of the new screens (screenshots) | 1 | Medium | **Done** (`docs/screenshots/sprint4-*`) | S4-01…04 |
| S4-07 | Demo guide: install, presentation script, reset, known limitations | 2 | High | **Done** (`docs/DEMO_GUIDE.md`) | S4-01…04 |
| S4-08 | Sign off sign-in lock-out and session times | 0 | High | **Done** 7 Nov 2026 (recommended values kept, D-S4-2) | Joe |
| S4-09 | Install and smoke-test the APK on a physical Android phone (incl. Sprint 3's S3-08) | 2 | Highest | **To do (Joe)**: needs a real phone | CI APK |
| S4-10 | Jira: import Sprint 3 + 4 backlogs into SIANTEK | 1 | Medium | **Blocked: Jira access** | ouragileproject.atlassian.net |
| S4-11 | *Stretch*: English-language screenshot pass and final slide deck | 3 | Low | Backlog (not committed) | S4-09 |

Committed 20 pts: 17 done (S4-01…07) plus S4-08 (0 pts); 3 pts (S4-09 phone test, S4-10 Jira) need
Joe or Jira access.

## Acceptance criteria

**S4-01 Completion summary**
- A completed request shows a "Job summary" card: service, work started (quote approval), completed, time on the job, cash recorded; commission is shown to the technician and admins, never to the customer.
- Numbers and dates use the app language's digits (Arabic-Indic in Arabic).

**S4-02 Simulated payment disclosure**
- The summary card states that the app processes no money and only records the cash the technician collected, in Arabic and English.

**S4-03 Problem report**
- On a completed request the customer sees "Report a problem"; text of 10–500 characters; one report per request; not available before completion.
- Admins and the assigned technician get a notification; the admin dashboard shows the open-report count and a "Problems" filter; request cards show an "Open problem" badge.
- An admin closes the report with what was done; customer and technician are notified and see the resolution.
- Only the request's customer can report and only admins can close (enforced in `LocalBackend`).

**S4-04 Erase the device**
- Admin only, under Account; asks for the admin's password; a wrong password changes nothing.
- Deletes every account, request, message, notification and stored photo; the app returns to the first-run welcome and offers first-admin setup again; the catalog and areas remain.
- Survives a restart (the erased state is what is on disk).

**S4-05 Regression**
- `flutter analyze` clean, `dart format` clean, all tests pass, web build succeeds, CI builds the APK and launches it on an emulator.

**S4-07 Demo guide**
- Covers install from the release, first run, the timed presentation sequence for all three roles, reset (in app and via Android settings), and the known-limitations list.

**S4-08 Policy sign-off**
- Joe approves or changes lock-out (5 failed sign-ins → 5 minutes) and session length (30 days). Approved values lose their `[Proposed]` tag in `AppRules` and `LocalStore`.

**S4-09 Device smoke test**
- Follow `docs/DEMO_GUIDE.md` end to end on a phone, including the erase step; note any clipping, keyboard overlap or crash.

## Dependencies and risks

- **S4-08** is Joe's decision; the app keeps the current values until then.
- **Jira** still blocked as in Sprint 3: this session's Atlassian access reaches only `yousifmrabeadev.atlassian.net`, which has no SIANTEK project. The CSVs are ready to import.
- **APK** is built only by GitHub Actions. No new dependencies this sprint; no schema bump (the problem report is an optional field, so existing databases keep working).
- **Erase** is irreversible by design; it is admin-only and password-gated.

## Test evidence (run 2 Nov 2026 in the cloud container, Flutter 3.47.8)

| Check | Result |
|-------|--------|
| `flutter analyze` | No issues found |
| `dart format --set-exit-if-changed lib test` | 0 changed |
| `flutter test` | **122 passed, 0 failed** (118 existing + 4 new) |
| `flutter build web` | Built |
| GitHub Actions APK build + emulator launch | runs on push; result reported in the PR |

New tests: `test/local/local_backend_test.dart` group "closeout support and device reset
(Sprint 4)" (3: report rules and permissions; admin queue, close-out and notices; erase is
admin-only, password-checked, deletes photos and survives restart). `test/local/journey_test.dart`:
the main journey now continues through the job summary, the demo disclosure, a problem report and
the admin close-out; a new journey erases the device from the admin's Account tab and lands on the
first-run welcome.

## Decisions

- **D-S4-1** No seed/demo accounts, even for the presentation; live account creation plus in-app erase instead (follows Joe's 24 Oct 2026 rule).
- **D-S4-2** Lock-out and session times: **final at 5 tries / 5 min / 30 days** (7 Nov 2026; Joe asked
  for the sprint to be finished without further questions, so the recommended values were adopted).
- **D-S4-3** Ship a release-mode APK (smaller and faster than the debug build), named **صيانتك** on
  the home screen, version 1.0.0, without the internet permission. Published from `main` only.

## Sprint close-out (7 Nov 2026)

Merged: PR #2 (Sprint 2 docs; its content had already landed with PR #5, so main's READMEs were
kept) and PR #6 (Sprint 4 features). The final PR adds:

| Change | Why |
|--------|-----|
| App name **صيانتك** on Android, iOS and web (was `sianetak_customer`) | The launcher showed the code name |
| No `INTERNET` permission in the release manifest | The app is fully on-device; nothing should look like it phones home |
| Version `1.0.0+4` | First finished build |
| Lock-out and session times final; `[Proposed]` tags removed | D-S4-2 |
| CI builds `flutter build apk --release`, emulator launch check, publishes `Sianetak.apk` on the `sianetak-apk` release from `main` | Final deliverable; branch builds no longer overwrite the download |
| Demo guide and READMEs updated | Install link, release name, final policies |

Still open, outside the code: **S4-09** phone smoke test (Joe, follow `docs/DEMO_GUIDE.md`),
**S4-10** Jira import (needs access to ouragileproject.atlassian.net), **S4-11** stretch
(English screenshots and slides, not committed).

| Check (7 Nov 2026, Flutter 3.47.8) | Result |
|-------|--------|
| `flutter analyze` | No issues found |
| `dart format --set-exit-if-changed lib test` | 0 changed |
| `flutter test` | **122 passed, 0 failed** |
| GitHub Actions release APK build + emulator launch | see the final PR's checks |
