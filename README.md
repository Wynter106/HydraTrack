# HydraTrack

**Smarter hydration tracking — not just fluid volume.**

> Website & Tutorial: **[wynter106.github.io/HydraTrack](https://wynter106.github.io/HydraTrack/)**
> Download APK: **[Google Drive](https://drive.google.com/uc?export=download&id=1wfZt2eirbZEF-Ru0Nwcwn8dekk1CB4uR)**

---

Most hydration apps count every drink the same. HydraTrack applies a **Beverage Hydration Index** to each drink — coffee contributes less toward your daily goal than water, and an energy drink even less. The result is an accurate picture of your actual hydration, not just the total fluid you consumed.

Built as a CS 4500 Senior Design Capstone project at the University of Utah.

---

## Screenshots

| Home | Today's Log | Goals & Badges | Monthly Stats |
|------|-------------|----------------|---------------|
| ![Home](docs/images/hydratrack_home.jpg) | ![Log](docs/images/hydratrack_log.jpg) | ![Goals](docs/images/hydratrack_goal.jpg) | ![Monthly](docs/images/hydratrack_monthly.jpg) |

---

## Features

- **Hydration Factor** — each drink weighted by real hydration contribution (caffeine diuretic effect)
- **Caffeine Tracking** — daily limit with real-time progress and warning
- **Alcohol Tracking** — standard drink calculation with 100+ beverages
- **AI Daily Insight** — personalized hydration tip from your actual data (Groq / LLaMA 3)
- **Drink Library** — 630+ beverages, fully searchable, with favorites and Quick Add
- **Weekly & Monthly Stats** — calendar heat-map showing days you hit your goal
- **Goals & Badges** — streak tracking and milestone achievements
- **Medication Reminders** — scheduled push notifications
- **Offline Support** — logs queued locally and synced on reconnect
- **Dark Mode** and **oz / mL toggle**

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
| Notifications | flutter_local_notifications |

---

## Team

| Name | Responsibilities |
|------|-----------------|
| Wynter | Team lead, database design, Supabase architecture, core tracking logic |
| Douglas | Log screen UI, analytics screens, alcohol tracking |
| JungBin (Moon) | UI, monthly/weekly view, medication reminder feature |
| Wilker | Settings, goals, alcohol tracking, dark mode |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- A Supabase project (auth + cloud sync)
- A Groq API key (AI insight feature)

### Setup

1. Clone the repository
2. Create `lib/config/secrets.dart` with your API keys
3. Run `flutter pub get`
4. Run `flutter run`

> `lib/config/secrets.dart` and `key.properties` are gitignored and must be created locally.

### Build

```bash
flutter build apk --debug    # Debug APK
flutter build apk --release  # Release APK
```

### Tests

```bash
flutter test
flutter analyze
```

---

## Architecture

4-layer architecture:

```
Presentation    →  lib/presentation/screens/  lib/presentation/widgets/
Application     →  lib/application/providers/
Business Logic  →  lib/business/calculators/  lib/business/services/
Data            →  lib/data/dao/  lib/data/models/
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed notes, feature status, and known issues.

---

## Disclaimer

HydraTrack is a **wellness and habit-building tool**, not a medical application. Hydration factors are simplified approximations intended to encourage healthier choices, not precise physiological measurements.

| Drink type | Hydration factor |
|------------|-----------------|
| Water | 1.00 |
| Tea / Light coffee | 0.90–0.95 |
| Regular coffee | 0.80–0.85 |
| Strong coffee | 0.75 |
| Energy drink | 0.60–0.70 |
