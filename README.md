# Olive Stock Tracker

The main app now uses the original Firebase-backed login, inventory, buyer, staff and reporting flows with the white/light-blue design migrated from the former Olive demo. The separate demo screens, sample repository and demo session have been removed.

## Run

```sh
flutter pub get
flutter run
```

Sign in with an existing Firebase account. Access is based on the active `users/{uid}` profile, not a demo role. Android, web, Windows and Apple options are defined in `lib/firebase_options.dart`.

## Code organization

- `lib/constants/app_theme.dart`: shared Material 3 light/dark themes and bundled typography.
- `lib/widgets/shared_widgets.dart`: shared cards, avatars, badges and detail rows.
- `lib/widgets/sales_week_chart.dart`: sales chart using actual purchase records.
- `lib/utils/formatters.dart`: NPR formatting and date/name helpers.
- `lib/screens/`: Firebase-connected dashboard, inventory, buyers, staff, reports and profile screens.
- `lib/providers/`, `lib/repositories/`, `lib/services/`: application state, Firestore transactions, authentication and image uploads.

The production app code stays in `lib` under descriptive names. Temporary Dart verification files were removed after validation, as requested.

## Product photos

Add stock uses the gallery/camera picker and Cloudinary unsigned uploads. The secure URL and image metadata are saved on the Firestore product. The configured cloud is `dglxnraim`, preset `flutter_coffee_test`; both support `CLOUDINARY_CLOUD_NAME` and `CLOUDINARY_UPLOAD_PRESET` build overrides. Uploaded images appear in inventory cards and product details. No URL field is required.

## Buyer deletion

Only active admins see Delete buyer. A confirmation describes the action. The repository also checks the role, and the existing Firestore rules allow buyer deletion only for active admins. A transaction removes the purchase, restores remaining stock, reduces sold stock and writes an immutable correction log. Retrying an already-deleted purchase does not restore stock twice. Missing products or inconsistent stock totals block deletion with an error.

The existing `reconcilePurchase` Cloud Function updates sales/income summaries after deletion; it must be deployed for server-generated reports to refresh. This change does not deploy or loosen Firestore rules. See `README.firebase.md` for backend configuration details.

## Validation

Flutter analysis, mobile UI/role checks and Android debug build were run during implementation. Backend permission verification uses the local `demo-stockflow` emulator, not live data. Bundled fonts and OFL licenses are in `assets/fonts/`.

Buyer purchases support Paid/Credit status, saved as paymentStatus in Firestore. Older purchases without this field appear as Paid. Use the All/Paid/Credit buttons on Buyers together with search and warranty filters. Administrators can edit a purchase to mark credit as paid. Credit profiles show Amount due; paid profiles show Total paid. Overview and report cards separate collected paid income from outstanding credit income using the live buyer records. The overview displays Total products, Total sales (units), Total paid income, and Credit income in two columns. Password-reset email controls are removed from login and profile. The overview no longer shows the remaining-stock graph or Total stock summary.



Active admins can delete inventory products from Product details using the delete icon and confirmation dialog. Deletion retains buyer/payment/warranty records and logs the removed stock in one transaction. Deleting a retained purchase later updates sales totals without restoring stock for a deleted product. Existing Firestore product-delete rules require an active admin.

