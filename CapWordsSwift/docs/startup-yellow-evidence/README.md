# 黄色启动页与动画衔接验收

2026-10-19，验证对象为本地 `dev.reawork.CapWordsSwift`，不是原版 IPA。范围见 [scope](scope.md)，证据链与原版资源纠正见 [复核报告](../2026-10-19_逆向-CapWords-启动衔接复核-report.md)。

系统 LaunchScreen 不执行动画。当前实现以相同的静态首帧接上应用动画，并在主窗口保留遮罩至条带开始退场。

## 最终运行验证

| 系统 | 本轮有效证据 | 核对结果 |
| --- | --- | --- |
| iOS 26.4 | [录像](handoff-ios26/launch.mov)、[交接帧](handoff-ios26/frames/contact-003.jpg)、[退场帧](handoff-ios26/frames/contact-007.jpg)、[元数据](handoff-ios26/frames/metadata.json) | 对录像 1–6 秒的 199 个实际样本逐帧检查；条带始终遮住内容，约 4.843 秒起退场、5.098 秒完整显示词库 |
| iOS 27 | [录像](handoff-ios27/launch.mov)、[交接帧](handoff-ios27/frames/contact-002.jpg)、[退场帧](handoff-ios27/frames/contact-006.jpg)、[元数据](handoff-ios27/frames/metadata.json) | 对录像 1–16 秒的 182 个实际样本逐帧检查；约 12.758 秒起退场、12.980 秒完整显示词库 |

两段录像均观察到：系统图标放大阶段已经显示黄色条带和 C；随后 Logo／标题／装饰动画在同一背景上播放；最后斜带移开，直接露出已准备的词库。未发现提前露出首页／词库、背景突然消失或退场后回跳静态页。

抽取改为读取视频每个样本的真实 PTS，再以零时间容差解码；两段范围内 `requestedSeconds == actualSeconds`，无重复实际时间。仍只证明录像捕获到的帧，不证明真机帧率或屏幕合成器未录下的时刻。iOS 27 模拟器系统阶段明显更长，未定位该耗时原因；不是 App 硬编码等待 13 秒。录屏脚本的 20 秒等待仅用于采样。

录像使用 `--uitesting --exercise-startup --seed-library --onboarding-complete --disable-daily-review`，偏好与词库隔离。9 词属于开发示例，正常启动不会植入。

## 代码与构建

- `LaunchScreen.storyboard`：背景直接引用 bundle PNG，全屏 aspect-fill，C 为 86×86 居中。
- `LaunchArtwork.bands`：系统页、SwiftUI 遮罩与 Canvas 动画使用同一图片；缺资源时显式失败，不静默变透明。
- `HomeView` 从首帧覆盖 `LaunchFirstFrame`；`LaunchWindowBridge` 同步挂载动画窗口；`beginContentReveal()` 才移除首帧遮罩。
- [build-for-testing 日志](signed-build-for-testing.log)：`TEST BUILD SUCCEEDED`，仅 AppIntents 未链接的元数据提取提示。`codesign --verify --deep --strict` 通过；模拟器使用 `CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=-`。
- [核心测试](core-tests.log)：19 项通过。新加 storyboard 尺寸／图片加载／遮罩状态测试编译成功，但 [iOS XCTest 重试](runner-ios26.log) 仍报 `DTServiceHubClient failed to bless service hub`，未执行，已停止该测试进程。

## 中间失败证据，不作为成功验收

| 目录／文件 | 当时的问题 |
| --- | --- |
| `launch.mov`、`ios26/` | 未签名构建；系统资源校验失败，黑屏，之后有内容闪现 |
| `signed-ios26/`、`signed-ios27/` | 已签名、同步挂载；系统背景纯黄，27 仍曾透出词库 |
| `final-ios26/`、`final-ios27/` | 加入保留至退场的遮罩；图集背景仍未在系统页加载。目录名不代表验收通过 |
| `verified-ios26/`、`verified-ios27/` | 改 storyboard 名和 build number 无效；日志确认快照已重新生成，排除仅是旧快照未刷新。目录名不代表验收通过 |
| `bundle-png-ios26/`、`bundle-png-ios27/` | 系统背景已正常，但 SwiftUI 按旧图集名加载失败，应用背景透明；之后统一为显式 UIKit 加载 |
| [静态预览](storyboard-preview.png) | 用 Debug `--preview-launch-screen` 在应用内直接预览 storyboard；用于区分系统资源加载与布局问题 |
| [系统图片加载失败](system-image-load-failure.log) | `Could not load the "launch-bands" image referenced from a nib` |
| [快照重新生成日志](snapshot-regeneration.log) | 新 storyboard 已通过签名校验并生成快照；改资源名本身未解决图集加载失败 |

所有中间录像保留。最终有效版本是 `handoff-ios26/` 和 `handoff-ios27/`。

## 复现

在 `CapWordsSwift/` 执行，模拟器须已启动；重录使用新的临时输出目录，不覆盖历史证据：

```bash
export DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer
bash scripts/verify.sh build-for-testing
export CAPWORDS_SIMULATOR_ID=59D5891F-5C9D-4425-9F0E-0415C74963D4
export CAPWORDS_SCREENSHOT_DIR=$(mktemp -d /tmp/capwords-handoff.XXXXXX)
bash scripts/capture_launch_video.sh
swift -suppress-warnings -module-cache-path /tmp/capwords-video-module-cache \
  scripts/extract_video_evidence.swift "$CAPWORDS_SCREENSHOT_DIR/launch.mov" \
  "$CAPWORDS_SCREENSHOT_DIR/frames" 0 1 16
```

iOS 27 的模拟器 ID 为 `CE0B9DF8-87CD-4D20-9AEB-0AE7163F777C`。可用 `swift scripts/generate_launch_bands.swift` 重建三档 PNG。

未验证：真机冷／热启动矩阵、减少动态效果实际运行、全套 XCTest 交互回归。保留原生 iOS 26／27 TabView，没有因这次修复修改正常用户数据或重置模拟器。

## 用户侧模拟器反馈

用户随后反馈 `CoreUI: CUIThemeStore: No theme registered with id=0` 与 `IOSurfaceClientSetSurfaceNotify failed e00002c7`，并明确确认模拟器没有黑屏或闪屏。SDK 的 `IOKit/IOReturn.h` 将 `0xe00002c7` 定义为 `kIOReturnUnsupported`（unsupported function）。这两条目前仅作为系统图形层诊断记录，不据此改变应用启动逻辑或隐藏日志；若同时出现缺图、黑屏、持续掉帧或崩溃，再收集相同时间段的完整日志定位。此项为用户反馈，不冒充本机重新复现的日志证据。
