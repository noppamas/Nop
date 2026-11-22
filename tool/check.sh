#!/usr/bin/env bash
# Runs every local check for JSON Better Editor, in order:
#   1. flutter analyze        (static analysis + lints)
#   2. flutter test           (unit and widget tests)
#   3. flutter build macos    (debug build of the .app)
#   4. integration smoke test (launches the app on macOS)
# Usage: tool/check.sh
# Uses `flutter` from PATH, or $FLUTTER if set, or ~/Documents/flutter/bin/flutter.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -n "${FLUTTER:-}" ]]; then
  flutter_cmd="$FLUTTER"
elif command -v flutter >/dev/null 2>&1; then
  flutter_cmd="flutter"
elif [[ -x "$HOME/Documents/flutter/bin/flutter" ]]; then
  flutter_cmd="$HOME/Documents/flutter/bin/flutter"
else
  echo "flutter not found: add it to PATH or set FLUTTER=/path/to/flutter" >&2
  exit 1
fi

step() { printf '\n==> %s\n' "$1"; }

step "pub get"
"$flutter_cmd" pub get

step "analyze"
"$flutter_cmd" analyze

step "unit and widget tests"
"$flutter_cmd" test

step "build macOS (debug)"
"$flutter_cmd" build macos --debug

step "integration tests on macOS (launch smoke test and real-disk tests)"
# screenshot_test.dart only produces images (tool/screenshot.sh); skip it.
integration_tests=()
for f in integration_test/*_test.dart; do
  [[ "$(basename "$f")" == "screenshot_test.dart" ]] || integration_tests+=("$f")
done
"$flutter_cmd" test "${integration_tests[@]}" -d macos

printf '\nAll checks passed.\n'
