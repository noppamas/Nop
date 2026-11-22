# JSON Better Editor

A JSON editor for macOS, built with Flutter desktop. One document is shown as
**Text** (code editor) and **Node** (visual tree editor).

Plans and requirements live in [`docs/plans/`](docs/plans/). Agent instructions
are in [`AGENTS.md`](AGENTS.md).

## Requirements

- macOS with Xcode installed (`xcode-select -p` points at Xcode.app).
- Flutter SDK (stable). If `flutter` is not on your `PATH`, the check script
  also looks for `~/Documents/flutter/bin/flutter`, or set `FLUTTER=/path/to/flutter`.

Only the macOS platform is enabled in this project.

## Run every check with one command

```bash
tool/check.sh
```

This runs, in order:

1. `flutter analyze` (lint rules in `analysis_options.yaml`)
2. `flutter test` (unit and widget tests in `test/`)
3. `flutter build macos --debug`
4. `flutter test integration_test -d macos` (launch smoke test: starts the app on macOS)

It stops at the first failure. There is no GitHub Actions workflow; checks run
locally on the Mac.

## Screenshot

```bash
tool/screenshot.sh build/screenshot.png
```

Opens the app with a sample file and captures the window (needs Screen
Recording permission for the terminal; otherwise it saves the Flutter content
without the window controls).

## Run the app

```bash
flutter run -d macos
```

## Project layout

```
lib/
  main.dart            entry point
  app/                 MaterialApp, theme
  editor/              editor window and its widgets
  l10n/                string tables (app_en.arb); generated code in l10n/generated/
  platform/            small bridges to macOS (window title)
test/                  unit and widget tests
integration_test/      launch smoke test (runs on macOS)
tool/check.sh          one-command local check
```

## Strings (i18n)

Every user-visible string lives in `lib/l10n/app_en.arb`. English is the only
and default language for now. After editing the `.arb` file, `flutter pub get`
(or any `flutter` build/test command) regenerates `lib/l10n/generated/`.
