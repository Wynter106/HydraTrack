# HydraTrack

A science-backed hydration and wellness tracking app built with Flutter for CS 4500 Senior Design Capstone at the University of Utah.

Most hydration apps treat every drink the same. HydraTrack applies a **Beverage Hydration Index** to each drink — meaning a cup of coffee contributes less toward your daily goal than a glass of water, and an energy drink contributes even less. This gives users a more accurate picture of actual hydration rather than just fluid volume consumed.

---

## Features

- **Hydration tracking** with per-drink hydration factor (based on caffeine diuretic effect)
- **Caffeine tracking** with FDA-based daily limit and real-time progress
- **Alcohol tracking** with standard drink calculation
- **AI-powered daily insight** — personalized hydration tip generated from your day's data
- **Drink library** — 630+ beverages with search, favorites, and Quick Add
- **Weekly and monthly stats** — calendar heat-map view of goal achievement
- **Goals and badges** — streak tracking, milestone achievements
- **Medication reminders** — scheduled notifications (iOS + Android)
- **Offline support** — logs queued locally and synced when back online
- **Dark mode** support
- **Unit toggle** — oz / mL

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Auth + Cloud DB | Supabase |
| Local DB | SQLite (beverage seed data) |
| State Management | Provider |
| Offline Cache | SharedPreferences + local JSON queue |
| AI Analysis | Groq API (`llama-3.3-70b-versatile`) |
| Notifications | flutter_local_notifications (Android + iOS) |

---

## Team

| Name | Responsibilities |
|------|-----------------|
| Wynter | Team lead, database design, Supabase architecture, core tracking logic |
| Douglas | Log screen UI, analytics screens |
| JungBin (Moon) | UI/UX, theming, medication reminder feature |
| Wilker | Settings, goals, alcohol tracking feature, dark mode |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart 3.x
- A Supabase project (for auth and cloud sync)
- A Groq API key (for AI insight feature)

### Setup

1. Clone the repository
2. Create `lib/config/secrets.dart` with your API keys (see `secrets.dart.example` if provided)
3. Run `flutter pub get`
4. Run `flutter run`

> **Note:** `lib/config/secrets.dart` and `key.properties` are gitignored and must be created locally.

### Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# iOS (requires Mac + Xcode)
flutter build ios
```

### Tests

```bash
flutter test
flutter analyze
```

---

## Architecture

The project follows a 4-layer architecture:

```
Presentation    →  lib/presentation/screens/  lib/presentation/widgets/
Application     →  lib/application/providers/
Business Logic  →  lib/business/calculators/  lib/business/services/
Data            →  lib/data/dao/  lib/data/models/
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed architecture notes, feature status, and known issues.

---

## Purpose & Disclaimer

HydraTrack is designed as a **wellness and habit-building tool** — not a medical or clinical application. The hydration factors assigned to each beverage are simplified approximations intended to encourage healthier drink choices, not precise physiological measurements.

The app is not a substitute for medical advice. Users with specific health conditions should consult a healthcare professional regarding their hydration needs.

| Drink type | Hydration factor (approximate) |
|------------|--------------------------------|
| Water | 1.00 |
| Tea / Light coffee | 0.90–0.95 |
| Regular coffee | 0.80–0.85 |
| Strong coffee | 0.75 |
| Energy drink | 0.60–0.70 |
