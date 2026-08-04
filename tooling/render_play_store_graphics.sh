#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHROME_BIN=${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}
SOURCE_DIR="$ROOT/store-assets/source"
OUTPUT_DIR="$ROOT/store-assets/android"

if [ ! -x "$CHROME_BIN" ]; then
  echo "Chrome executable not found: $CHROME_BIN" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

"$CHROME_BIN" --headless=new --disable-gpu --hide-scrollbars \
  --default-background-color=00000000 \
  --force-device-scale-factor=1 --window-size=512,512 \
  --screenshot="$OUTPUT_DIR/icon-512.png" \
  "file://$SOURCE_DIR/icon-render.html"

sips -z 192 192 "$OUTPUT_DIR/icon-512.png" \
  --out "$ROOT/web/icons/Icon-192.png" >/dev/null
cp "$OUTPUT_DIR/icon-512.png" "$ROOT/web/icons/Icon-512.png"

MASKABLE_512="$ROOT/web/icons/Icon-maskable-512.png"
"$CHROME_BIN" --headless=new --disable-gpu --hide-scrollbars \
  --default-background-color=070b16ff \
  --force-device-scale-factor=1 --window-size=512,512 \
  --screenshot="$MASKABLE_512" \
  "file://$SOURCE_DIR/icon-render.html"
sips -z 192 192 "$MASKABLE_512" \
  --out "$ROOT/web/icons/Icon-maskable-192.png" >/dev/null
sips -z 32 32 "$OUTPUT_DIR/icon-512.png" \
  --out "$ROOT/web/favicon.png" >/dev/null

for spec in \
  "48 mipmap-mdpi" \
  "72 mipmap-hdpi" \
  "96 mipmap-xhdpi" \
  "144 mipmap-xxhdpi" \
  "192 mipmap-xxxhdpi"
do
  set -- $spec
  size=$1
  directory=$2
  sips -z "$size" "$size" "$OUTPUT_DIR/icon-512.png" \
    --out "$ROOT/android/app/src/main/res/$directory/ic_launcher.png" >/dev/null
done

FEATURE_PNG="$OUTPUT_DIR/feature-graphic-1024x500.png"
"$CHROME_BIN" --headless=new --disable-gpu --hide-scrollbars \
  --force-device-scale-factor=1 --window-size=1024,500 \
  --screenshot="$FEATURE_PNG" \
  "file://$SOURCE_DIR/feature-render.html"

sips -s format jpeg -s formatOptions best "$FEATURE_PNG" \
  --out "$OUTPUT_DIR/feature-graphic-1024x500.jpg" >/dev/null
rm "$FEATURE_PNG"

file "$OUTPUT_DIR/icon-512.png" "$OUTPUT_DIR/feature-graphic-1024x500.jpg"
