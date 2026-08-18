# Contributing to HabitScape

Thanks for your interest in HabitScape! This guide covers everything you need
to build, test and contribute to the project. Product overview and features
live in the [README](https://github.com/Fellmonkey/HabitScape) ([Russian
version](README.ru.md)).

## 🛠 Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart) — Android + Web (PWA)
* **State Management:** [Riverpod](https://riverpod.dev/) (Notifier / StreamProvider)
* **Database:** [Drift](https://drift.simonbinder.eu/) — reactive SQLite wrapper,
  Wasm-compatible for the Web
* **Routing:** [go_router](https://pub.dev/packages/go_router)
* **Rendering:** `CustomPaint` for the heatmap and progress visuals

## 🚀 Getting Started

Prerequisites: Flutter SDK (Dart ^3.11).

```bash
flutter pub get                       # install dependencies
dart run build_runner build --delete-conflicting-outputs   # generate drift *.g.dart
flutter run -d chrome                 # Web (PWA) — fast dev loop
flutter run -d <device>               # Android
```

After changing drift tables/DAOs, regenerate the codegen and commit the
generated `*.g.dart` files.

## 🧪 Testing

```bash
dart format .                         # formatting
flutter analyze                       # static analysis
flutter test                          # unit & widget tests
flutter test integration_test         # end-to-end (needs a device/emulator)
```

Run `dart format .`, `flutter analyze` and `flutter test` before opening a PR.

## 🗂 Project Layout

```
lib/
  core/         # database (drift), router, theme, settings, debug tools
  features/     # habits (greenhouse, month spread, moment of the day),
                # stats, settings, onboarding
  shared/       # reusable widgets (GlassCard, SheetHandle)
test/           # unit & widget tests next to features
integration_test/ # end-to-end scenarios
```

Feature code follows Clean Architecture: `data` (DAOs) → `domain` (pure logic) →
`providers` (Riverpod) → `presentation` (screens & widgets).

## 📐 Conventions

* **Language:** UI strings are in **Russian** and hardcoded in widgets; code and
  commit messages in **English**. Comments — concise English only.
* **Test keys:** every interactive widget carries a `Key` from
  `lib/core/keys.dart` (class `K`) — keep tests and tours in sync.
* **Domain logic** is pure Dart, without Flutter imports, and unit-tested
  (`test/features/...`).
* **State:** one source of truth (drift streams), no duplication. Mutations go
  through `Notifier`.
* **Dates:** stored as unix-seconds (UTC midnight via `toMidnight`); check-off
  time as `loggedHour`.

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
