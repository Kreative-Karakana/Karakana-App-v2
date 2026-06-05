# Active

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
- Fursa page manual verification pending. Platform: Android and iOS. Priority: High.
  Notes:
  - V2 Fursa placeholder has been replaced with a content-driven page.
  - Backend now exposes admin-managed Fursa items through communications.
  - Seed records currently use the provided Instagram links with placeholder editorial copy because source captions/media could not be fetched automatically from this environment.
