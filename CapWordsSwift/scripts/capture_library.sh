#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer}"
CAPWORDS_DEVICE="${CAPWORDS_SIMULATOR_ID:?请指定已启动的开发模拟器}"
CAPWORDS_OUTPUT="${CAPWORDS_LIBRARY_OUTPUT:-docs/library-interaction-validation}"
mkdir -p "$CAPWORDS_OUTPUT"
xcrun simctl install "$CAPWORDS_DEVICE" .build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app
for scene in empty-today populated-today first-history completely-empty; do
    xcrun simctl terminate "$CAPWORDS_DEVICE" cn.a2px.wordrove.dev.f89luflt5b.c9e48b12 2>/dev/null || true
    args=(--uitesting --preview-library)
    case "$scene" in
        empty-today) args+=(--seed-library-history) ;;
        populated-today) args+=(--seed-library --single-today) ;;
        first-history) args+=(--seed-library-history --preview-first-history) ;;
        completely-empty) ;;
    esac
    xcrun simctl launch "$CAPWORDS_DEVICE" cn.a2px.wordrove.dev.f89luflt5b.c9e48b12 "${args[@]}"
    sleep 3
    xcrun simctl io "$CAPWORDS_DEVICE" screenshot "$CAPWORDS_OUTPUT/$scene.png"
done
# Programmatic scrolling validates rendering/heading transitions; it is not a gesture test.
xcrun simctl terminate "$CAPWORDS_DEVICE" cn.a2px.wordrove.dev.f89luflt5b.c9e48b12 2>/dev/null || true
xcrun simctl io "$CAPWORDS_DEVICE" recordVideo --codec=h264 --force "$CAPWORDS_OUTPUT/programmatic-scroll.mov" &
CAPWORDS_RECORD_PID=$!
trap 'kill -INT "$CAPWORDS_RECORD_PID" 2>/dev/null || true' EXIT
sleep 1
xcrun simctl launch "$CAPWORDS_DEVICE" cn.a2px.wordrove.dev.f89luflt5b.c9e48b12 --uitesting --preview-library --seed-library-history --preview-timeline-motion
sleep 10
kill -INT "$CAPWORDS_RECORD_PID"
wait "$CAPWORDS_RECORD_PID" || true
trap - EXIT
