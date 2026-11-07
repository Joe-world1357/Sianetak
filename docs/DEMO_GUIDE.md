# Sianetak demo guide (Sprint 4)

How to install the app, present the full journey in about 12 minutes, reset the phone, and what
to say about the parts that are simulated.

## 1. Install

1. On an Android phone (Android 7+), open the repository's **Releases** page and download
   `Sianetak.apk` from the `sianetak-debug` release (it is rebuilt by GitHub Actions on every push).
2. Open the file and allow "Install unknown apps" for your browser or Files app when asked.
3. Allow location when the app asks during a request (needed only for the map pin).

To build it yourself: `cd mobile && flutter pub get && flutter build apk --debug`
(Flutter 3.47.8, Android SDK). `flutter run` works on an emulator too.

## 2. Before you present (3 minutes)

The app ships with **no accounts and no sample data**, on purpose. Create the cast live, or
before the session:

| Role | Name | Phone | Password |
|------|------|-------|----------|
| Admin | منى حسن | 01200000001 | any 8+ chars with a letter and a digit |
| Technician | محمد علي | 01100000001 | same |
| Customer | أحمد محمود | 01000000001 | same |

1. First launch → **تخطي** (Skip) → **إعداد حساب المسؤول** (Set up administrator) → create the admin.
2. Sign out → **أنشئ حساباً** → **فني** (Technician) → create the technician → fill the application
   (pick **سباكة** and **وسط مدينة أسوان**) → send.
3. Sign in as the admin → **الفنيون** (Technicians) → open the application → **اعتماد** (Approve).

All three accounts live on the same phone; you switch by signing out and in.

## 3. Presentation sequence (about 12 minutes)

| # | Who | What to show | Point to make |
|---|-----|--------------|---------------|
| 1 | Customer | Sign up, browse **سباكة → إصلاح تسريب مياه**, price guidance | Arabic-first, RTL, prices in EGP |
| 2 | Customer | Request: description + photo, area + address + **current location**, "as soon as possible", review, send | Validation, step-by-step form |
| 3 | Technician | **عروض العمل** shows the offer with a countdown → accept | Dispatch to top-rated eligible technicians, 15-min expiry |
| 4 | Technician | On my way → Arrived → **Open in Maps** → send a 300 EGP quote | Status flow; address hidden until accepted |
| 5 | Customer | Notification → approve the quote; open the order chat | Work cannot start before approval |
| 6 | Technician | **تم الانتهاء وتحصيل المبلغ** → confirm | Cash recorded with 10% commission |
| 7 | Customer | **ملخص الخدمة** (job summary) → read the blue "demo only" notice → rate 5 stars | Simulated payment is disclosed |
| 8 | Customer | **الإبلاغ عن مشكلة** → describe a problem → send | Support after completion |
| 9 | Admin | Dashboard: KPIs, **بلاغ مفتوح واحد** → open → **إغلاق البلاغ** with what was done | Operations follow-up; both sides notified |
| 10 | Technician | Account → switch to customer mode | One account, two roles |

Optional: switch the language to English from Account → Language to show the bilingual UI.

## 4. Reset the phone after a demo

- **In the app (recommended):** sign in as the admin → **حسابي** (Account) → **مسح كل البيانات على
  هذا الجهاز** → enter the admin password → **مسح كل شيء**. All accounts, requests, messages,
  notifications and photos are deleted; the app opens on the welcome screen as after install.
- **Without the admin password:** Android Settings → Apps → Sianetak → Storage → **Clear storage**
  (or uninstall and reinstall). Same result.

## 5. Known limitations (say these out loud)

- **No money is processed.** The app records the cash amount the technician says they collected
  and the 10% commission; there is no payment gateway, wallet or settlement.
- **One device only.** Accounts and data live in a database on this phone. Notifications and chat
  reach only accounts on the same phone; there is no server, sync, push or SMS.
- **No password recovery.** A forgotten password can only be fixed by erasing the device.
- **No in-app map, ETA or live tracking.** The location pin opens in the phone's maps app.
- **Offers expire** while the app is open (checked every 30 s and on every screen load), not in
  the background.
- **Policies** are fixed in code (`mobile/lib/local/initial_data.dart`): 3 offers per request,
  15-minute expiry, cancel until work starts, 10% commission. Lock-out (5 tries → 5 min) and
  session length (30 days) are still `[Proposed]`.
- **Technician documents** are reviewed as images only; no PDF preview.
- The `backend/` folder is the earlier server design, kept for reference; the app does not use it.
