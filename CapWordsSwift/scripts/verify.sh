#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${DEVELOPER_DIR:-}" ]]; then
  for candidate in /Applications/Xcode.app/Contents/Developer /Applications/Xcode-beta.app/Contents/Developer /Volumes/homex/Applications/Xcode-beta.app/Contents/Developer; do
    if [[ -x "$candidate/usr/bin/xcodebuild" ]]; then
      export DEVELOPER_DIR="$candidate"
      break
    fi
  done
fi

# Launch storyboard 的 SplashBoard 校验需要有效的资源封签。
# 模拟器使用本地 ad-hoc 签名，不需要 Apple 开发者证书或开发团队。
if [[ "${1:-build}" == "test" ]]; then
  : "${CAPWORDS_SIMULATOR_ID:?请设置 CAPWORDS_SIMULATOR_ID，可通过 xcrun simctl list devices available 查询}"
  xcodebuild -project CapWordsSwift.xcodeproj -scheme CapWordsSwift \
    -destination "platform=iOS Simulator,id=$CAPWORDS_SIMULATOR_ID" \
    -derivedDataPath .build -parallel-testing-enabled NO \
    CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- test
else
  xcodebuild -project CapWordsSwift.xcodeproj -scheme CapWordsSwift \
    -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath .build CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- "${1:-build}"
fi
