#!/usr/bin/env bash
# Takes a full-window screenshot of the app with a sample file open.
# Usage: tool/screenshot.sh [output.png] [extra flutter test args]
#   e.g. tool/screenshot.sh build/fold.png --dart-define=SCREENSHOT_FOLD_LINE=5
# Needs Screen Recording permission for the terminal app.
set -euo pipefail
cd "$(dirname "$0")/.."

out="${1:-build/screenshot.png}"
shift || true
mkdir -p "$(dirname "$out")"
if [[ -n "${FLUTTER:-}" ]]; then flutter_cmd="$FLUTTER"
elif command -v flutter >/dev/null 2>&1; then flutter_cmd=flutter
else flutter_cmd="$HOME/Documents/flutter/bin/flutter"; fi

log="$(mktemp)"
"$flutter_cmd" test integration_test/screenshot_test.dart -d macos "$@" >"$log" 2>&1 &
pid=$!
for _ in $(seq 1 120); do
  grep -q SCREENSHOT "$log" && break
  sleep 1
done
sleep 1
sleep 2
wid=$(swift -e 'import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for w in list where (w["kCGWindowOwnerName"] as? String) == "JSON Better Editor" && (w["kCGWindowLayer"] as? Int) == 0 {
  print(w["kCGWindowNumber"]!); break
}' 2>/dev/null)
flutter_png=$(sed -n 's/^SCREENSHOT //p' "$log" | head -1)
if [[ -n "$wid" ]] && screencapture -x -o -l "$wid" "$out" 2>/dev/null; then
  echo "Saved full window to $out"
elif [[ -n "$flutter_png" && -f "$flutter_png" ]]; then
  # No window capture (no Screen Recording permission, screen locked, or
  # window off screen): fall back to the Flutter-rendered content.
  cp "$flutter_png" "$out"
  echo "Saved Flutter content only (no window controls) to $out"
else
  echo "Screenshot failed" >&2; cat "$log" >&2; exit 1
fi
wait "$pid" || true
