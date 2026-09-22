# StockFlow - Firebase stock tracker

Flutter app configured for project stocktracker-f8f91 (Android, web, Windows).

## Repairs and rule compatibility

The current firestore.rules is the exact supplied rules file. The previous rules and documentation are preserved as firestore.previous.rules and README.previous.md; they do not describe the current policy.

- Restored the missing Provider state layer and service aliases, using the existing repositories. Fixed compile errors in the unfinished BLoC implementation as well.
- Stock writes use stock_added, stock_removed, correction and sale history types. Staff updates no longer include the forbidden lastUpdateId field.
- Purchases read current stock and prices and write product, buyer and history in one transaction. A purchase form keeps its operation ID across retries.
- Admin reports use financial_reports/summary. The trusted backend reconciles creation, edits and deletion of buyer records, with an idempotent processing ledger. Client code does not write report totals.
- Staff and admin registration first verifies the current active admin profile, then creates a login with an isolated secondary Firebase Auth app. It writes the new profile using the original admin Firestore session. A failed profile write deletes only the newly created login. The main admin stays signed in. No Cloud Function or billing upgrade is needed for registration.
- The server creates low-stock notifications when stock crosses from above the threshold to at/below it. Repeated trigger delivery is deduplicated. Notification failures cannot reject staff stock transactions.
- Inventory loading is independent of history loading. History and notification feeds initially load the latest 100 records, with buttons to load older records. Buyer and inventory lists remain complete for search, selection and reports.
- Model readers tolerate optional fields absent from documents that satisfy the supplied rules. This app uses whole-unit quantities.
- Profile read failures remove the protected session, and all Provider listeners are cancelled on disposal. Under the supplied rules inactive users cannot read their own profile, so the app displays account unavailable with a logout action.

## Run and check

Use the installed Flutter SDK compatible with the checked-in pubspec.lock. Use Node 22.12+ within Node 22, or Node 24, for local backend tools; Node 22.11 fails to load current Firebase Admin dependencies. Cloud Functions is configured for Node 22. Java 21+ is required for the Firestore emulator.

~~~powershell
flutter pub get
flutter analyze
flutter test
flutter build web
flutter run -d chrome
npm --prefix functions ci
firebase emulators:exec --config firebase.test.json --only firestore,auth --project demo-stockflow "npm --prefix functions test"
~~~

firebase.test.json uses ports 8280 and 9199 to isolate test services. Tests never use the real Firebase project. The backend suite has 22 tests covering role access, rule-compatible writes, concurrent purchases, report deduplication/reconciliation, notification delivery, and account provisioning in the Auth emulator. Flutter has 15 tests for validation, narrow-screen forms, model parsing, stream cancellation auth session clearing and the Windows callable HTTP transport.

## Live Firebase setup

Registration was checked against the live project using temporary staff/admin accounts, which were deleted after testing. Other live flows have not been fully validated. Enable Email/Password authentication and create the Firestore database. Configure authorized web domains. Functions deployment requires a suitable billing plan. The live project currently has billing disabled, no deployed registration function, and no Auth blocking hooks. The app therefore uses Firebase Auth plus admin-authorized Firestore writes directly. The retained blocking-hook backend is for a future server-provisioning setup: do not enable its before-create hook while using this direct registration flow. Auth signups alone grant no inventory access; an active profile is required by the supplied rules.

~~~powershell
firebase deploy --project stocktracker-f8f91 --only firestore:rules,firestore:indexes
# Optional after enabling billing, for reports and notifications:
firebase deploy --project stocktracker-f8f91 --only functions:aggregatePurchase,functions:reconcilePurchase,functions:notifyLowStock
~~~

Registration works without deployed functions. The optional reconcilePurchase/aggregatePurchase functions are still needed for report aggregation and notifyLowStock for server notifications. Wait for Firestore indexes to finish building. Existing purchases are not automatically replayed by a new trigger. After deploying, a trusted operator can backfill the new report collection with Application Default Credentials:

~~~powershell
gcloud auth application-default login
gcloud auth application-default set-quota-project stocktracker-f8f91
node functions/backfill-reports.js stocktracker-f8f91
~~~

The backfill uses the same per-purchase ledger and is safe to rerun. Do not manually copy old report totals into the new collection before backfilling, because that would count those sales twice. Leave historical reports in the old reports collection for reference through trusted tooling.

Create the first administrator through Firebase Console (Authentication user plus matching users/{uid} document), or the existing functions/bootstrap-admin.js script with trusted credentials. Required profile fields: uid, name, email, role: admin, isActive: true, createdAt: Firestore timestamp. Optional phone and branch default to empty strings. No client can create the first admin.

Live registration verification passed for both roles, including duplicate-email rejection and unchanged admin sessions. Before using live inventory, also check stock purchases, report updates, notifications and deactivation on your target devices.

## Limits of the supplied rules

These rules allow any active user to list notifications, although individual get requests are recipient-restricted. The app queries only the current user's notifications, but rules do not enforce list privacy. They also do not enforce atomic purchase/audit linkage, price matching or added-minus-sold equality; those checks are in the normal client transaction. Admins may edit/delete purchases and write report documents. The app does not expose those report writes. Staff can read prices and buyer totals, so aggregate financial secrecy is not guaranteed. These are properties of the supplied policy, preserved here rather than silently changing your rules.

## Platforms

Android package: com.example.stock_tracker. Release builds currently use the original debug signing configuration; configure your own signing before store distribution. Windows registration uses the Firebase Auth SDK in a separate Firebase app, the same flow as Android/web. Windows needs Visual Studio's Desktop development with C++ workload. iOS/macOS/Linux Firebase options are not configured.

Backend callable implementation follows [Firebase callable functions](https://firebase.google.com/docs/functions/callable).

## Verification from this repair

The local backend emulator suite passed all 22 tests. Web release and Android debug builds succeeded. The registration flow was additionally verified against the live project with the Firebase client SDK; temporary accounts were removed. Real-device interaction and native Windows compilation were not verified. Build tools emit upstream Firebase/Kotlin and web font warnings; these did not prevent successful builds.

### Registration verification

The old forms failed because createAccount returned HTTP 404 while Cloud Functions was disabled. The fixed flow does not call that endpoint. To repeat the reversible live check, set STOCKFLOW_ADMIN_EMAIL and STOCKFLOW_ADMIN_PASSWORD only in the process environment, then run tool/verify-registration.cjs with a compatible Node runtime. It creates uniquely named temporary accounts, validates both roles and session isolation, rejects duplicate email registration, and deletes only its test accounts. Passwords are not written to source or test logs.
