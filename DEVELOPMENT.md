# HydraTrack — Development Reference

This document covers architecture decisions, feature status, known issues, and engineering notes for contributors and reviewers.

**Current version:** 1.2.0

---

## Architecture Overview

```
lib/
├── main.dart                            # App entry point, first-launch detection
├── config/
│   └── secrets.dart                     # API keys (gitignored)
├── presentation/
│   ├── screens/                         # One file per screen
│   └── widgets/                         # Shared widgets (AppBottomNav, OfflineBanner, AppCard)
├── application/
│   └── providers/                       # State management (Provider pattern)
│       ├── hydration_provider.dart      # Core tracking state + offline queue
│       ├── profile_provider.dart        # User profile + SharedPreferences cache
│       ├── auth_provider.dart           # Supabase auth wrapper
│       └── favorite_drinks_provider.dart
├── business/
│   ├── calculators/                     # Pure logic, no UI dependencies
│   │   ├── hydration_calculator.dart
│   │   ├── caffeine_tracker.dart
│   │   ├── weekly_stats_calculator.dart
│   │   └── monthly_stats_calculator.dart
│   ├── services/
│   │   ├── ai_analysis_service.dart     # Groq API integration
│   │   └── connectivity_service.dart   # Network state (ChangeNotifier)
│   └── managers/
│       └── notification_manager.dart   # flutter_local_notifications (Android + iOS)
└── data/
    ├── dao/                             # All Supabase/SQLite queries
    │   ├── beverages_dao.dart
    │   ├── drink_logs_dao.dart
    │   └── user_settings_dao.dart
    └── models/                          # Data classes
        ├── beverage.dart                # includes isAlcoholic, abv, standardDrinks()
        └── favorite_drink.dart         # includes effectiveName getter
```

---

## Core Business Logic

### Hydration Factor

Each beverage has a `hydrationFactor` (0.0–1.0) that reflects its actual contribution to hydration after accounting for caffeine's diuretic effect.

```dart
actualHydrationOz = volumeOz * hydrationFactor
```

Factors are assigned at seeding time based on caffeine-per-oz ranges, derived from Maughan et al. (2016).

### Caffeine Limit

Daily limit defaults to 400 mg (FDA guideline for healthy adults). Adjustable in user settings. Color indicator turns red when the user is within 10% of the limit.

### Alcohol Standard Drinks

```dart
standardDrinks = (volumeOz * (abv / 100)) / 0.6
```

`0.6 oz` is the NIAAA definition of one standard drink of pure alcohol.

---

## Feature Status

### Completed

| Feature | Notes |
|---------|-------|
| Auth (sign up / login) | Supabase Auth; first-install auto-redirects to Sign Up via `has_launched_before` SharedPreferences key |
| Profile setup | Age input, height/weight with unit conversion, auto-calculates hydration goal |
| Home screen | Quick Add grid, AI Insight card (above progress bars), hydration + caffeine progress |
| Drink library | 630+ beverages, favorites, tab-based (All / Favorites), A–Z sidebar for quick navigation, fuzzy search |
| Hydration logging | Logs to Supabase; offline queue syncs on reconnect |
| Log screen | Scrollable log list with delete; unit-aware display |
| Weekly stats | Calendar view (Mon–Sun row), goal achievement highlighted |
| Monthly stats | Calendar grid with weekday offset, goal achievement highlighted |
| Goals & badges | Streak tracking, milestone achievements |
| Alcohol tracking | Standard drink calculation, lifetime total, per-session tracking |
| Medication reminders | Scheduled local notifications, iOS (Darwin) + Android |
| Notification permissions | Requested at toggle-on time, not at app launch |
| Settings | Unit preference, goal overrides, notification toggles, version display |
| Dark mode | Full theme support |
| Offline support | OfflineBanner widget; pending logs queued in local JSON, synced on reconnect |
| Unit toggle | oz ↔ mL throughout all screens |

### Known Issues / Backlog

**Critical — data integrity**

| ID | Description |
|----|-------------|
| #20 | Settings: re-entering screen after editing weight shows incorrect value |
| #21 | Settings: pressing Save without changes doubles displayed values |
| #22 | Settings: auto-calculator toggle reverts to enabled state after save + re-entry |
| #25 | Weekly/Monthly: date boundaries not always using local device time |
| #26 | Re-login causes weekly drink values to appear doubled |
| #14 | Deleting a drink log does not recalculate achievement badges |

**Functional bugs**

| ID | Description |
|----|-------------|
| #5 | Custom drinks calculate caffeine in oz only; hydration factor not applied |
| #6 | Editing a custom drink name throws an error |
| #16 | Duplicate custom drink name silently fails with no user feedback |
| #19 | Custom drink deletion not implemented |

**UI / UX**

| ID | Description |
|----|-------------|
| #7 | Settings screen missing scroll on smaller devices |
| #11 | Caffeine warning color threshold not clearly communicated to user |
| #12 | No push notification on daily goal achievement |
| #18 | Log screen: no multi-select for bulk deletion |

**Enhancements**

| ID | Description |
|----|-------------|
| #QA-3 | Drink library: allow volume editing from library (not just favorites) |
| #QA-4 | Drink library: pin favorited drinks to top of All Drinks list |
| #QA-5 | Custom drink creation: option to immediately add to favorites / Quick Add |

---

## Key Engineering Decisions

### `signUp()` does not call `notifyListeners()`

After a successful sign-up, `AuthProvider.signUp()` intentionally skips `notifyListeners()`. Calling it would trigger a `Consumer<AuthProvider>` rebuild that navigates to `HomeScreen` before `LoginScreen` can push `ProfileSetupScreen`. The login screen handles navigation manually after `signUp()` returns.

### Dialog async safety

Any `showDialog` that performs async work after the user taps Save must call `Navigator.pop(dialogContext)` **before** the `await`. If `notifyListeners()` fires while a dialog's `BuildContext` is still mounted, Flutter throws a `_dependents.isEmpty` assertion. The edit dialog in `drink_library_screen.dart` captures all values into local variables first, then pops, then performs the async update.

### Offline queue

`HydrationProvider` maintains a local JSON list of pending drink logs. On each app start and each time `ConnectivityService` transitions to online, `syncPendingLogs()` drains the queue to Supabase. This keeps the UI responsive with no blocking on network calls.

### Date boundary — local time

`loadTodayLogs()` uses `DateTime.now()` (device local time) for the day boundary. Using UTC here would cause logs made after midnight UTC but before local midnight to fall on the wrong day for users outside UTC.

### A–Z sidebar scroll estimation

The drink library sidebar uses proportional scroll offset:
```dart
final offset = (index / totalCount) * maxScrollExtent;
```
This avoids hardcoding item heights and stays accurate regardless of device density or font scaling.

### Fuzzy search

Search splits the query on whitespace and requires every token to appear somewhere in the beverage name (case-insensitive). This means `"green tea"` matches `"Tea, Green"` and `"cof bla"` matches `"Black Coffee"` without needing an external package.

---

## Data Layer Notes

- Supabase caffeine columns are `float` — sending an `int` will be silently truncated in some query paths.
- `beverages_dao.dart` exposes both `getAllBeverages()` (SQLite seed data) and `getAllAlcoholicBeverages()` / `searchAlcoholicBeverages()` (Supabase).
- `MonthlyStatsCalculator` date range is inclusive on both ends — be careful when constructing the `end` boundary.
- `FavoriteDrinksProvider.updateFavorite()` patches the in-memory list directly rather than calling `loadFavorites()` afterward. Reloading from Supabase inside a still-open dialog caused the `_dependents.isEmpty` crash; local mutation avoids it.

---

## Running the Project

```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Static analysis
flutter analyze --no-pub

# Unit tests
flutter test

# Release build
flutter build apk --release
```

**Required local files (not in repo):**

- `lib/config/secrets.dart` — Groq API key
- `android/key.properties` — Android signing config

Both are listed in `.gitignore`.

---

## Commit History Notes

Team members committed from multiple machines with slightly different Git author configurations. SLoC-per-author counts from `git log` may not accurately reflect individual contributions.
