#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${DEVELOPER_DIR:=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer}"
export DEVELOPER_DIR
CAPWORDS_DEVICE="${CAPWORDS_SIMULATOR_ID:-59D5891F-5C9D-4425-9F0E-0415C74963D4}"
CAPWORDS_APP="${CAPWORDS_APP_PATH:-.build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app}"
CAPWORDS_OUTPUT="${CAPWORDS_SCREENSHOT_DIR:-docs/screenshots}"
mkdir -p "$CAPWORDS_OUTPUT"
xcrun simctl install "$CAPWORDS_DEVICE" "$CAPWORDS_APP"
xcrun simctl status_bar "$CAPWORDS_DEVICE" override --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
for page in home home-category library camera dust floating result detail review; do
  xcrun simctl terminate "$CAPWORDS_DEVICE" cn.a2px.wordrove.dev.f89luflt5b.c9e48b12 2>/dev/null || true
  xcrun simctl launch "$CAPWORDS_DEVICE" cn.a2px.wordrove.dev.f89luflt5b.c9e48b12 --uitesting --seed-library "--preview-$page"
  sleep 3
  xcrun simctl io "$CAPWORDS_DEVICE" screenshot "$CAPWORDS_OUTPUT/$page.png"
done
xcrun simctl status_bar "$CAPWORDS_DEVICE" clear
