#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${CAPWORDS_SIMULATOR_ID:?请指定已启动的测试模拟器}"
: "${DEVELOPER_DIR:?请指定Xcode Developer路径}"
capwords_output="${CAPWORDS_SCREENSHOT_DIR:-docs/startup-implementation-evidence}"
# simctl launch 返回 PID 不代表 SwiftUI 已完成首帧；冷启动曾超过 4 秒。
# 这只是视觉采样，不是 UI 断言。生成的截图仍需核对对应页面。
capwords_settle="${CAPWORDS_CAPTURE_WAIT_SECONDS:-20}"
if ! [[ "$capwords_settle" =~ ^[0-9]+$ ]] || (( capwords_settle < 5 || capwords_settle > 60 )); then
  echo 'CAPWORDS_CAPTURE_WAIT_SECONDS 必须为 5–60 秒' >&2
  exit 1
fi
mkdir -p "$capwords_output"
xcrun simctl install "$CAPWORDS_SIMULATOR_ID" .build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app

# 所有场景使用隔离的偏好及内存词库，不清除或修改正常运行数据。
capture_scene() {
  local capwords_name="$1"
  shift
  echo "采样场景：${capwords_name}（等待 ${capwords_settle}s）"
  xcrun simctl launch --terminate-running-process "$CAPWORDS_SIMULATOR_ID" cn.a2px.wordrove.dev.f89luflt5b.c9e48b12 --uitesting "$@"
  sleep "$capwords_settle"
  xcrun simctl io "$CAPWORDS_SIMULATOR_ID" screenshot "$capwords_output/$capwords_name.png"
}

capture_scene library --exercise-startup --seed-library --onboarding-complete --disable-daily-review
capture_scene onboarding --exercise-startup --force-onboarding
capture_scene review --exercise-startup --seed-library --onboarding-complete
capture_scene empty-home --preview-home
capture_scene populated-home --seed-library --preview-home
