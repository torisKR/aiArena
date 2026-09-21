#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHROME_BIN=${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}
FFMPEG_BIN=${FFMPEG_BIN:-ffmpeg}
SOURCE_DIR="$ROOT/store-assets/source"
OUTPUT_DIR="$ROOT/store-assets/android"

if [ ! -x "$CHROME_BIN" ]; then
  echo "Chrome executable not found: $CHROME_BIN" >&2
  exit 1
fi

if ! command -v "$FFMPEG_BIN" >/dev/null 2>&1; then
  echo "ffmpeg executable not found: $FFMPEG_BIN" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

"$CHROME_BIN" --headless=new --disable-gpu --hide-scrollbars \
  --default-background-color=00000000 \
  --force-device-scale-factor=1 --window-size=512,512 \
  --screenshot="$OUTPUT_DIR/icon-512.png" \
  "file://$SOURCE_DIR/icon-render.html"

"$FFMPEG_BIN" -y -loglevel error -i "$OUTPUT_DIR/icon-512.png" \
  -vf format=rgba -frames:v 1 "$OUTPUT_DIR/icon-512-rgba.png"
mv "$OUTPUT_DIR/icon-512-rgba.png" "$OUTPUT_DIR/icon-512.png"

sips -z 192 192 "$OUTPUT_DIR/icon-512.png" \
  --out "$OUTPUT_DIR/icon-192.png" >/dev/null

MASKABLE_512="$OUTPUT_DIR/icon-maskable-512.png"
"$CHROME_BIN" --headless=new --disable-gpu --hide-scrollbars \
  --default-background-color=070b16ff \
  --force-device-scale-factor=1 --window-size=512,512 \
  --screenshot="$MASKABLE_512" \
  "file://$SOURCE_DIR/icon-render.html"
sips -z 192 192 "$MASKABLE_512" \
  --out "$OUTPUT_DIR/icon-maskable-192.png" >/dev/null
sips -z 32 32 "$OUTPUT_DIR/icon-512.png" \
  --out "$OUTPUT_DIR/favicon-32.png" >/dev/null

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

# The current Android icon derives from the user-supplied logo, not the
# historical SVG rendered above. Always restore the approved icon last.
python3 "$ROOT/tooling/generate_android_icons.py"

file "$OUTPUT_DIR/icon-512.png" "$OUTPUT_DIR/feature-graphic-1024x500.jpg"
