# Karakana App — TODO & Bug Tracker

## 🐛 Known Bugs

### BUG-001: Category filtering not working on Explore screen
- **Status:** Partially resolved (client-side workaround applied)
- **Root Cause:** BACKEND BUG — The backend API ignores the `categories__name` query parameter and always returns all 19 courses regardless of the filter value. Confirmed via debug logs showing correct params sent but full results always returned.
- **Frontend fix:** Client-side filtering applied as temporary workaround
- **Backend fix needed:** Django backend needs to correctly implement `categories__name` filter on the `/api/v1/courses/` endpoint
- **Backend file to fix:** Likely in `courses/views.py` or `courses/filters.py` in the Kreative-Karakana-backend repo
- **Files affected:**
  - `lib/features/courses/providers/course_provider.dart`
  - `lib/features/courses/screens/explore_screen.dart`

### BUG-002: Course description shows raw Quill JSON
- **Status:** Open
- **Screen:** Course Detail (`lib/features/courses/screens/course_detail_screen.dart`)
- **Description:** The course description field contains Quill rich text editor JSON format like `{"ops":[{"insert":"..."}]}` instead of plain text.
- **Fix needed:** Parse the Quill delta JSON and extract plain text from all `"insert"` string values, concatenate them to form readable description.
- **Example fix:**
  ```dart
  String _parseQuillJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      final ops = decoded['ops'] as List;
      return ops.map((op) => op['insert'] ?? '').join('').trim();
    } catch (e) {
      return raw;
    }
  }
  ```

---

## 🚧 Pending Features

### FEAT-001: Course Detail Screen
- **Status:** In Progress
- **Priority:** High (needed for March 7th demo)
- **Description:** Full course detail screen with description, curriculum, reviews, and enrollment

### FEAT-002: Classroom Screen
- **Status:** Not Started
- **Priority:** High (Phase 3)
- **Description:** Sections and lessons list for enrolled courses

### FEAT-003: Mux Video Player
- **Status:** Not Started
- **Priority:** High (Phase 3)
- **Description:** Video playback for lessons using Mux signed URLs

### FEAT-004: Lesson Progress Tracking
- **Status:** Not Started
- **Priority:** High (Phase 3)
- **Description:** Mark lessons as complete, track course progress percentage

### FEAT-005: AzamPay Payment Screen
- **Status:** Not Started
- **Priority:** High (Phase 4)
- **Description:** MNO checkout screen for paid course enrollment

### FEAT-006: Payment Success/Failure Screen
- **Status:** Not Started
- **Priority:** High (Phase 4)
- **Description:** Post-payment confirmation screen

### FEAT-007: Payment History Screen
- **Status:** Not Started
- **Priority:** Medium (Phase 4)
- **Description:** List of all past payments

### FEAT-008: Profile View Screen
- **Status:** Not Started
- **Priority:** High (Phase 5)
- **Description:** View logged-in user profile

### FEAT-009: Profile Edit Screen
- **Status:** Not Started
- **Priority:** High (Phase 5)
- **Description:** Edit name, bio, avatar, social links

### FEAT-010: Trainer Application Form
- **Status:** Not Started
- **Priority:** Medium (Phase 5)
- **Description:** Form to apply as a trainer

### FEAT-011: Notifications Screen
- **Status:** Not Started
- **Priority:** Medium (Phase 5)
- **Description:** List of user notifications

### FEAT-012: Support Tickets Screen
- **Status:** Not Started
- **Priority:** Low (Phase 5)
- **Description:** Create and view support tickets

### FEAT-013: Wishlist Screen
- **Status:** Not Started
- **Priority:** Low
- **Description:** List of wishlisted courses

---

## ✅ Completed

- Project setup and architecture
- App theme (colors, fonts)
- Splash screen
- Onboarding screen
- Login screen
- Signup screen
- Email verification screen
- Forgot password screen
- Home screen with real data (banners, courses)
- Explore screen (search working, category UI working)
- Course card widget
- Bottom navigation bar
- Auth flow (login, signup, verify, logout)
- Course models
- Course service
- Course provider
