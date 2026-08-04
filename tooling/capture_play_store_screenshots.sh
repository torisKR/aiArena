#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
device="${ANDROID_SERIAL:-emulator-5554}"
capture_dir="$(mktemp -d "${TMPDIR:-/tmp}/tokenfront-play-store.XXXXXX")"
assets_dir="$project_root/store-assets/android"

restore_device() {
  adb -s "$device" shell wm size reset >/dev/null 2>&1 || true
  rm -rf "$capture_dir"
}

if ! adb -s "$device" get-state >/dev/null 2>&1; then
  echo "Android device $device is not available." >&2
  exit 1
fi

trap restore_device EXIT

adb -s "$device" shell wm size 1080x1920

cd "$project_root"
PLAY_STORE_CAPTURE_DIR="$capture_dir" flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/store_screenshot_capture_test.dart \
  -d "$device"

for name in \
  phone-01-command-deck-1920x1080 \
  phone-02-live-directive-1920x1080 \
  phone-03-command-handoff-1920x1080 \
  phone-04-chronicle-debrief-1920x1080 \
  phone-05-archive-1920x1080; do
  sips -s format jpeg -s formatOptions 95 -z 1080 1920 \
    "$capture_dir/$name.png" --out "$assets_dir/$name.jpg" >/dev/null
done

flutter test test/play_store_assets_test.dart
