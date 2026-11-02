# Sprint 3 Plan — Sianetak (صيانتك)

Prepared 2 Nov 2026 · Branch `claude/project-thread-3c14bj` · Base `main` @ `019a5c1` (PR #4).
Jira-ready: every story below has an ID, points, priority, acceptance criteria and dependencies.
`docs/sprint3_jira_import.csv` holds the same backlog for Jira's CSV importer.

## Scope reminder

Sianetak is a **school project**: a standalone Android app with real local accounts and a local
database (no server, no seed data). `backend/` is reference only. The school plan's Sprint 3 is
"Demonstrate the service journey": assignment, status flow, quote, notifications, no implied live
tracking, dispatch or push. Production-only infrastructure (SMS, push, real-time server, maps
provider) is out of scope by the plan's own guardrails, so the audit's P0 conditions written for
the server are either solved with a local equivalent or closed by that scope decision. Each is
listed below with which one applies.

## Sprint goal

> A presenter can run the whole request journey on one phone, with every role reachable from one
> account where it makes sense, technicians who control their availability, offers that expire on
> their own, and a location pin anyone involved can open, with all audit P0/P1 conditions either
> verified fixed or explicitly signed off by the product owner.

## Starting point (verified 2 Nov 2026)

Already in `main` from PRs #3 and #4 and re-tested in this sprint (118 Flutter tests, see below):
dispatch to up to 3 eligible technicians with 15-minute expiry and first-accept-wins, admin
fallback assignment, status flow submitted → assigned → en route → arrived → quoted →
in progress → completed (+ cancelled, unmatched), quote approve/reject gate, customer
cancellation with reason, in-app notifications for every transition, order-bound chat, cash
record with commission, ratings. So most of the school plan's Sprint 3 functional scope is done;
this sprint closes the carryovers and readiness conditions.

## Audit readiness conditions (24 Oct audit, P0/P1)

The audit table lists **five** P0 rows (the brief said four); all five are tracked.

| # | Condition | Status now | How |
|---|-----------|------------|-----|
| P0-1 | Dispatch, offer-expiry and cancellation policy not approved (D-04) | **Open: needs product-owner sign-off** | Implemented as `[Proposed]` defaults in `mobile/lib/local/initial_data.dart` (`AppRules`): top 3 eligible by rating, 15-min expiry, fallback to admin, customer may cancel until work starts, 10% commission. Engineering cannot sign this off. |
| P0-2 | No technician availability data (FR-MAT-01) | **Resolved (built, S3-02)** | "Available for new jobs" switch; dispatch and admin assignment skip unavailable technicians; turning it off hands back pending offers. |
| P0-3 | No notification infrastructure (push, device tokens, SMS) | **Resolved by scope change** + local equivalent verified | Push/SMS need a server and are out of scope for a single-device app. In-app notification centre with unread badge fires on every key transition (tests: `local_backend_test`, journey tests). |
| P0-4 | No real-time channel or background job runner | **Resolved by scope change** + local equivalent (S3-03) | One device, one database: screens refresh on store changes (no channel needed). Offer expiry runs on every read and now on a 30-second timer while the app is open. |
| P0-5 | Location-sharing rules and maps/ETA provider not chosen | **Partly resolved**: sharing rules built; maps provider closed by scope; **map-pin form needs your OK** | Address and pin are hidden from merely-offered technicians, shown to the customer, the assigned technician and admins. No ETA/live tracking (plan forbids implying it). Pin opens in the phone's maps app (S3-04). |
| P1 | One role per account | **Resolved (built, S3-01)** | Customer and technician accounts switch roles on the same account. |
| P1 | Request/media access owner-or-admin only | **Resolved (already in local app)** | Assigned technician sees address, photos and chat; offered technician sees area only (test "requests and chats are private to their participants"). |
| P1 | PR #2 (Sprint 2 docs) unmerged | **Resolved here (S3-05)** | Its report, screenshots and `create-staff --name` brought in; its README rewrites dropped as outdated (they describe the server app). PR #2 can be closed once this merges. |
| P1 | Per-IP rate limit in memory | **Closed by scope change** | Server-only concern; no server in this project. |

## Capacity

[Proposed] One sprint of two weeks, one developer-equivalent plus product-owner time for
sign-offs and the device test. Capacity **21 points**; committed **20**. There is no Jira velocity
history for this project (the Jira site was not reachable from this session), so this is a
starting figure to correct after the sprint.

## Prioritized backlog

| ID | Story | Pts | Priority | Status | Depends on |
|----|-------|-----|----------|--------|------------|
| S3-01 | Multi-role accounts (customer ⇄ technician on one account) | 5 | Highest (P1) | **Done** in this PR | none |
| S3-02 | Technician availability switch | 3 | Highest (P0-2) | **Done** in this PR | none |
| S3-03 | Offer expiry without a server job runner | 1 | High (P0-4) | **Done** in this PR | none |
| S3-04 | Location pin: view, re-capture, open in maps (Sprint 2 carryover) | 3 | High (P0-5) | **Done in code; acceptance waits on decision D-S3-2** | none |
| S3-05 | Carry over PR #2 docs and staff `--name` flag | 1 | Medium (P1) | **Done** in this PR | none |
| S3-06 | Sign off dispatch / expiry / cancellation / commission defaults (D-04) | 1 | Highest (P0-1) | **Blocked: product decision D-S3-1** | Joe |
| S3-07 | Sprint 3 journey regression (all roles, Arabic + English) | 3 | High | **Done** (automated); see test evidence | S3-01…04 |
| S3-08 | Install and smoke-test the new APK on a physical Android phone | 2 | High | **To do (Joe)**: needs a real phone | CI APK |
| S3-09 | Jira: import this backlog into SIANTEK and link the sprint | 1 | Medium | **Blocked: Jira access** | access to ouragileproject.atlassian.net |
| S3-10 | *Stretch*: PDF preview for technician documents (P2) | 3 | Low | Backlog (not committed) | none |

Committed 20 pts: 13 done in this PR plus S3-07 (3) = 16 done; 4 pts (S3-06, S3-08, S3-09) need
Joe or Jira access.

## Acceptance criteria

**S3-01 Multi-role accounts**
- A customer or technician account shows "Switch to customer mode / technician mode" under Account; admins don't.
- Switching keeps the same account, phone and password; navigation changes to that role's tabs.
- A technician in customer mode can submit a request; they are never offered their own request.
- A customer in technician mode can apply; approval does not remove their customer side.
- Notices show in the role they concern (customer notices in customer mode, job notices as technician); chat labels the sender by their role on that request.
- The acting role survives an app restart; signing in starts in the account's stored role.
- All rules enforced in `LocalBackend`, not only hidden in the UI.

**S3-02 Technician availability**
- Approved technicians see an "Available for new jobs" switch on Offers, on by default.
- Off: no new offers, not listed or assignable by admins; pending offers are handed back (request goes to admin if no offers remain); accepted jobs continue.
- Only approved technicians can change it.

**S3-03 Offer expiry**
- A lapsed offer expires and the request falls back to admin even if nobody navigates (timer every 30 s while the app is open, plus on every read).

**S3-04 Location pin**
- After "Use my current location", the request form shows the coordinates, "Open in Maps", "Update location" and "Remove".
- The request detail shows the pin and "Open in Maps" to the customer, the assigned technician and admins; an offered technician sees neither the address nor the pin.
- If no maps app can open it, a clear message appears.
- No in-app map, ETA or live tracking is shown or implied.

**S3-05 PR #2 carryover**
- `docs/SPRINT_2_REPORT.md` and its screenshots are in the repo with a note that it describes the server-era build; `create-staff --name` works; backend lint, typecheck and unit tests pass.

**S3-06 Policy sign-off**
- Joe approves or changes: offer batch size (3), expiry (15 min), ranking (rating), cancellation window (until work starts), commission (10%), lock-out (5 tries / 5 min), session (30 days). Approved values lose their `[Proposed]` tag.

**S3-07 Regression**
- `flutter analyze` clean, `dart format` clean, all tests pass, web build succeeds, CI builds the APK and launches it on an emulator.

**S3-08 Device smoke test**
- Fresh install on a phone; admin setup → technician applies → approve → customer requests → accept → quote → complete → rate; technician switches to customer mode and books a service; "Open in Maps" opens the phone's maps app.

## Dependencies and risks

- **Decisions** D-S3-1 (policy defaults) and D-S3-2 (map-pin form) are Joe's; work proceeded on the recommended option.
- **Jira** is connected at org level, but this session's Atlassian access only reaches `yousifmrabeadev.atlassian.net`, where no SIANTEK project exists; `ouragileproject.atlassian.net` is not granted. Use the CSV until access is fixed.
- **APK** is built only by GitHub Actions (the Android SDK can't be installed here). New dependency `url_launcher` (Flutter team package) adds `<queries>` for `geo:` and `https` intents.
- **Multi-role** is a model change: existing databases keep working (no schema bump; old notices without a role show in every mode).

## Test evidence (run 2 Nov 2026 in the cloud container, Flutter 3.47.8)

| Check | Result |
|-------|--------|
| `flutter analyze` | No issues found |
| `dart format --set-exit-if-changed lib test` | 0 changed |
| `flutter test` | **118 passed, 0 failed** (104 existing + 14 new) |
| `flutter build web` | Built |
| backend `format:check`, `lint`, `typecheck`, `npm test` | clean; 101 unit tests passed |
| GitHub Actions APK build + emulator launch | runs on push; result reported in the PR |

New tests: `test/local/local_backend_test.dart` groups "multi-role accounts (P1)" (5),
"technician availability (P0)" (3) and the offer sweep (1);
`test/widget/sprint3_carryover_test.dart` (5: role switch, no switch for admins, availability
switch, pin opens maps + failure message, pin re-capture in the form).

## Decisions needed

- **D-S3-1** Approve the `[Proposed]` dispatch, expiry, cancellation and commission defaults (P0-1).
- **D-S3-2** Accept "GPS pin + open in the phone's maps app" as the map-pin requirement, instead of an in-app map (which would need internet, a tile provider and a new dependency).
