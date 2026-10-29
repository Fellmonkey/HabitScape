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

## 📝 Changelog

`CHANGELOG.md` is the single source of truth for release notes. The same file
is bundled into the app and shown under **Settings → About → What's new**, so
Git history and the in-app copy never diverge. Entries are written in Russian
because they are user-facing copy.

Add every user-visible change under `## [Unreleased]` using the
[Keep a Changelog](https://keepachangelog.com/) sections (`Добавлено`,
`Изменено`, `Исправлено`, …). The in-app history hides `[Unreleased]`, so only
shipped versions are shown. When releasing:

1. Rename `## [Unreleased]` to `## [x.y.z] - YYYY-MM-DD`. Don't add an empty
   `[Unreleased]` back — start a fresh one when the next change lands.
2. Bump `version` in `pubspec.yaml`.
3. Update `AppConstants.appVersion` in `lib/core/config/app_constants.dart`.
4. Run `flutter test test/core/config/version_sync_test.dart` (or the full
   suite). It fails if the pubspec, the constant and the newest changelog entry
   drift apart.

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
