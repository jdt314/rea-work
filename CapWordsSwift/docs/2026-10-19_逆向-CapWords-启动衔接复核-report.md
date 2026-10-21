# CapWords 启动衔接复核报告

日期：2026-10-19。方法：复用 REA 包资源证据、视频对照、本地 Swift 实现和模拟器录屏。报告类型为普通行为逆向补充，`flavor = null`。

## 结论与范围

原版确有 `NeutralLaunchScreen` 系统静态页，它包含全屏不透明黄色条带图片与居中 C；旧实现把底层 `LaunchCanvas` 灰白色当成可见背景，判断不完整。系统页本身不能播放应用动画，应当以同一首帧衔接应用层动画。本地窗口交接曾提前露出词库，现已通过首帧遮罩、同步挂载和退场时才揭开内容修复。在本轮 iOS 26.4／27 捕获并检查的帧中未再发现该闪现。

修改授权与边界见 [本轮 scope](startup-yellow-evidence/scope.md)，旧纯研究 scope 不被追溯扩张。未执行原版 IPA、未访问后端、未清除正常词库。原样本身份和二进制依赖沿用 [原研究报告](2026-10-18_逆向-CapWords-启动与首页-report.md)；本轮没有重新开展主程序反编译。

## 静态复核与实现

IPA 的 `UILaunchStoryboardName=NeutralLaunchScreen`、`UILaunchScreen=false`。NIB 的 root 为对象 6，背景 UIImageView 8 指向图片占位对象 10（`launch_band_background`），约束 21–24 将其铺满 root；Logo UIImageView 12 指向占位对象 16（`onboarding_launch_logo`），宽高各 86，中心对齐 root。Assets.car 中背景为不透明图片，393×852 @1x、786×1704 @2x、1179×2556 @3x，同时保留矢量表示；灰白 `LaunchCanvas` 在图片之下。视频首帧与上述结构相符。暗色资源存在，但本轮只处理当前浅色界面。

本地图片是独立几何重建，不是导出的原版素材。系统 storyboard 直接读取 bundle 内 PNG；SwiftUI 与 Canvas 显式通过 `UIImage(named: "launch-bands.png")` 读取同一资源。背景 aspect-fill，Logo 86×86 全屏居中。

`HomeView` 在第一帧叠加同样的静态遮罩；`WindowProbe.didMoveToWindow` 同步建立独立窗口并预布局。不能把 SwiftUI 的 `.task/onAppear` 当作窗口已上屏的保证，因此遮罩保持至 `beginContentReveal()`，在条带退场开始时才撤掉，退场结束释放动画窗口。底层导航与数据准备仍在遮罩下进行，没有改成播完动画才创建首页。

## Evidence

本节 `observed_at=2026-10-19`，`linked_workitem=本轮启动衔接复核`。文件型证据的 `artifact_path` 同 `source_ref`；未注明替代关系时 `supersedes=none`。哈希均为 SHA-256，原文件不改写。

| ID | source_type / source_ref | content_hash | raw_excerpt / repro_command |
| --- | --- | --- | --- |
| E-101 | file：[REA plist／IB 记录](startup-implementation-evidence/launch-background-rea.json) | `34d0e21ae6eff9d0006eda7c815cf4b726aeeadb52c97e9e316473224f80524c` | `NeutralLaunchScreen`、背景对象与约束；从项目根执行 `jq '.interfaceBuilder.normalized_result' docs/startup-implementation-evidence/launch-background-rea.json` |
| E-102 | file：[IPA 资源元数据](startup-yellow-evidence/ipa-launch-assets.json) | `c328b2af696a929af8ac7070b3356c8e0ef3eb52c8622d56818d749da8c5b8a3` | `Opaque=true`；`jq '.[] | select(.Name == "launch_band_background")' docs/startup-yellow-evidence/ipa-launch-assets.json` |
| E-103 | log：[系统图集加载失败](startup-yellow-evidence/system-image-load-failure.log) | `d1fa597accaba0140a69213274f0bf8b87708d995c697717a11104ca819599b0` | `Could not load the "launch-bands" image referenced from a nib`；`rg 'Could not load' docs/startup-yellow-evidence/system-image-load-failure.log` |
| E-104 | file：[iOS 26.4 最终录屏](startup-yellow-evidence/handoff-ios26/launch.mov) | `96b0c8f176e3adc87254d354edf9e2fde1d734af3281602b01a5bb708c6d0168` | 199 个实际样本，交接前不露词库；复现见下节 |
| E-105 | file：[iOS 27 最终录屏](startup-yellow-evidence/handoff-ios27/launch.mov) | `f6fe6252b5196ec11e4ace2935bdf370ed72843806ed8ae4bb3342dfb11c128d` | 182 个实际样本，条带移开才露词库；复现见下节 |
| E-106 | file：[实现](../App/Views/LaunchView.swift) | `e4c589d92045a3dca36ebd5bc9a029c4d3b67e40787c765095b47407de653174` | `needsFirstFrameCover = isVisible && !isRevealingContent`；`rg -n 'needsFirstFrameCover|beginContentReveal|UIImage\(named' App/Views/LaunchView.swift` |
| E-107 | log：[构建](startup-yellow-evidence/signed-build-for-testing.log) | `444852b8be2d5494f33918d27bd1d9676a2623dd50c9cac9f264d174b3b3e812` | `TEST BUILD SUCCEEDED`；`bash scripts/verify.sh build-for-testing` |
| E-108 | log：[核心测试](startup-yellow-evidence/core-tests.log) | `a96e4a144127a1c2255479bafa5f0b789ccc0955fde482f3753e11aaa41aea57` | `19 tests in 2 suites passed`；`swift test --scratch-path /tmp/capwords-startup-core` |

E-101 的 REA 视图 ID 为 `ev_785fa12e679d8dcd97a3c6444bb9ab9602cf9a7f7a1acd4ee4522e73f87d0281`，父记录为 `ev_39c64991937257d9b404c50507a3b58a89d971c64b2865680c1c2389df2f34dd`。REA 图仍不声称完整私有 IB 层级；这里仅引用已识别的对象、图片与约束。`inspect_asset_catalog` 超过 64 MB 限额后使用本机 Apple assetutil 保存 E-102，没有把失败当成资源不存在。

原视频的独立视觉佐证为 [首帧](video-1-evidence/overview/t0000000.jpg)；原视频哈希与抽帧命令在旧 scope 和研究报告中。静态包证据与本地模拟器录像不等于原版动态验证。

## Findings

| ID / title | severity / category / status | evidence_ids / confidence | location |
| --- | --- | --- | --- |
| F-101 系统静态页有全屏条带，不是灰白 C 页 | n/a_re / design / validated | E-101、E-102，并有原视频首帧佐证 / high | IPA NeutralLaunchScreen、launch_band_background |
| F-102 主窗口首帧遮罩应保持至退场，不以出现回调撤除 | n/a_re / design / validated | E-104、E-105、E-106 / high | HomeView.overlay、LaunchCoordinator、LaunchAnimationView.animate |
| F-103 本机系统页曾无法加载图集背景，直接 PNG 加显式 UIKit 加载可工作 | n/a_re / other / validated | E-103、E-104、E-105、E-106 / high | LaunchScreen.storyboard、LaunchArtwork.bands |

F-101 的影响是系统页到动画跳色；修正为同一静态首帧。F-102 的影响是底层词库提前可见；修正为首帧覆盖、同步挂载和退场门控。F-103 定位到资源加载失败点，**没有**证明系统内部图集失败的更深原因；改 PNG、改文件查找路径是本地兼容实现，不能泛化为 iOS 不支持矢量启动图。各发现的 `repro_steps` 为检查对应 E 文件并执行下节复现；`optional_attack=n/a`，本任务没有攻击行为。

## Path 与时间线

P-101，`path_type=callflow`。起点为用户打开应用，目标是系统页连续衔接到应用动画并只在退场时显示内容：

1. 系统从静态 storyboard 生成黄色条带＋C 快照。证据 E-101、E-102、E-104、E-105；发现 F-101、F-103。
2. 主窗口首帧遮罩覆盖已构建的内容，同步建立独立动画窗口。证据 E-106、E-104、E-105；发现 F-102。
3. 内容就绪后播放 Logo／标题／装饰；条带开始退出时撤去底层静态遮罩，结束时释放动画窗口。证据 E-106、E-104、E-105；发现 F-102。

`residual_risks`：只检查了本机两版模拟器所捕获的帧；真机、减少动态效果、全套交互自动化未验证。

时间线（均为 2026-10-19）：复核 IPA 背景引用，纠正灰白底色推断；从未签名日志确认系统资源校验失败，改为模拟器 ad-hoc 签名；加入保持至退场的首帧遮罩；改 storyboard 标识后日志确认新快照仍缺图，排除仅是旧快照；用静态预览与系统日志定位图集加载差异；改直接 PNG 并统一应用侧 UIImage 加载；完成两版系统逐帧检查、编译和核心测试，记录 XCTest 服务失败。

## 复现与验收边界

运行与重新录制命令见 [验收记录](startup-yellow-evidence/README.md#复现)。对已有两段录像逐帧复查，从 `CapWordsSwift/` 执行：

```bash
export DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer
capwords_frames=$(mktemp -d /tmp/capwords-handoff-review.XXXXXX)
swift -suppress-warnings -module-cache-path /tmp/capwords-video-module-cache \
  scripts/extract_video_evidence.swift docs/startup-yellow-evidence/handoff-ios26/launch.mov \
  "$capwords_frames/ios26" 0 1 6
swift -suppress-warnings -module-cache-path /tmp/capwords-video-module-cache \
  scripts/extract_video_evidence.swift docs/startup-yellow-evidence/handoff-ios27/launch.mov \
  "$capwords_frames/ios27" 0 1 16
```

`STEP=0` 使用轨道中每个样本的真实 PTS，不是每 250 ms 抽一帧；两段元数据均无请求／实际时间偏差。人工检查了全部联系表中的对应帧。该结论限定于录像覆盖，不推断真实设备性能。

验收清单：原版系统页结构已纠正；本地资源加载和中间闪现已修复并录像核对；应用及测试目标编译通过、19 项核心测试通过；新 UIKit/遮罩单测仅编译，[XCTest 服务仍失败](startup-yellow-evidence/runner-ios26.log)；真机和减少动态效果的运行验证待完成。原生玻璃 TabView 未改动，普通词库未清除。
