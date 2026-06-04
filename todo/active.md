# Active

- Welcome screens redesign/update using new reference images. Platform: Android and iOS. Priority: High.
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
