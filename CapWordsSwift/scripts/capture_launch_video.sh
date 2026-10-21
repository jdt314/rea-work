#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${CAPWORDS_SIMULATOR_ID:?请指定已启动的测试模拟器}"
: "${DEVELOPER_DIR:?请指定 Xcode Developer 路径}"
capwords_output="${CAPWORDS_SCREENSHOT_DIR:-docs/startup-yellow-evidence}"
mkdir -p "$capwords_output"
if [[ -e "$capwords_output/launch.mov" ]]; then
  echo '请用 CAPWORDS_SCREENSHOT_DIR 指定新的目录，保留已有录像。' >&2
  exit 1
fi
xcrun simctl install "$CAPWORDS_SIMULATOR_ID" .build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app
capwords_record_pid=''
stop_recording() {
  if [[ -n "$capwords_record_pid" ]]; then
    kill -INT "$capwords_record_pid" 2>/dev/null || true
    wait "$capwords_record_pid" || true
    capwords_record_pid=''
  fi
}
trap stop_recording EXIT
xcrun simctl io "$CAPWORDS_SIMULATOR_ID" recordVideo --codec=h264 "$capwords_output/launch.mov" > "$capwords_output/recording.log" 2>&1 &
capwords_record_pid=$!
capwords_record_ready=false
for ((capwords_attempt=0; capwords_attempt<10; capwords_attempt++)); do
  if grep -q 'Recording started' "$capwords_output/recording.log"; then
    capwords_record_ready=true
    break
  fi
  sleep 1
done
if [[ "$capwords_record_ready" != true ]]; then
  echo '录屏未就绪，请检查 recording.log。' >&2
  exit 1
fi
echo '录屏已就绪，启动隔离测试场景。'
xcrun simctl launch --terminate-running-process "$CAPWORDS_SIMULATOR_ID" cn.a2px.wordrove.dev.f89luflt5b.c9e48b12 \
  --uitesting --exercise-startup --seed-library --onboarding-complete --disable-daily-review
sleep 20
stop_recording
xcrun simctl io "$CAPWORDS_SIMULATOR_ID" screenshot "$capwords_output/library.png"
echo "录屏完成：${capwords_output}/launch.mov（仍需人工核对帧序列）"
