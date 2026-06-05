# Active

- Welcome screens manual emulator/iOS verification pending after V1-style layout port. Platform: Android and iOS. Priority: High.
- Trainer eBook analytics UI and backend support. Platform: Android and iOS. Priority: Medium.
  Notes:
  - Backend purchase records already exist through `EbookPurchase`.
  - No trainer API currently exposes eBook buyers count, purchases count, or revenue.
  - No V2 trainer UI currently shows eBook sales/performance numbers.
  - Minimum recommended scope:
    - backend fields or endpoint for `buyers_count`, `successful_purchases_count`, and `total_revenue`
    - V2 trainer eBook list/detail UI to display those numbers
- Trainer eBook PDF picker/upload manual verification pending. Platform: Android and iOS. Priority: High.
  Notes:
  - PDF picker now opens through native file selection and shows the selected file name.
  - App upload now sends the selected file as multipart field `epub_file`.
  - Current backend model still validates `epub_file` as EPUB-only, so PDF upload will remain blocked until backend validation is updated.
- Firebase initialization and FCM startup manual iOS verification pending. Platform: Android and iOS. Priority: High.
- Firebase cleanup: remove the legacy Android app entry/package typo from the Firebase project.
  Current incorrect package:
  com.kreativekarkana.karakana

  Correct package:
  com.kreativekarakana.karakana

  Notes:
  - Verify no active Android clients depend on the typo package.
  - Remove the typo Android app entry from Firebase Console.
  - Regenerate and download a clean `google-services.json`.
  - Verify the regenerated file contains only:
    `com.kreativekarakana.karakana`
  - Re-test Android Google Sign-In after Firebase cleanup.
- Android release build after final verified fixes.
- Fursa page manual verification pending. Platform: Android and iOS. Priority: High.
  Notes:
  - V2 Fursa placeholder has been replaced with a content-driven page.
  - Backend now exposes admin-managed Fursa items through communications.
  - Seed records currently use the provided Instagram links with placeholder editorial copy because source captions/media could not be fetched automatically from this environment.
