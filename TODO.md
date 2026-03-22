# Karakana App — TODO & Bug Tracker

## 🐛 Known Bugs

### BUG-001: Category filtering not working on Explore screen
- **Status:** Open
- **Screen:** Explore (`lib/features/courses/screens/explore_screen.dart`)
- **Description:** When a category chip is tapped, the API call is made correctly (verified via logs — returns 200 with filtered results) but the UI still shows all 19 courses instead of filtered ones.
- **Suspected cause:** The explore screen may not be rebuilding when `_courses` updates in the provider, or it's reading from a different list.
- **Files to check:**
  - `lib/features/courses/screens/explore_screen.dart`
  - `lib/features/courses/providers/course_provider.dart`

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
