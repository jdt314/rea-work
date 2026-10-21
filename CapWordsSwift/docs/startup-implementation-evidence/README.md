# 启动与首页实现验收记录

日期：2026-10-18。对象是本地重建的 `dev.reawork.CapWordsSwift`，不是原版 IPA。

2026-10-19 更正：本目录保留旧版验收证据。灰白 C 系统页不是正确的原版视觉复现；旧录屏的稀疏抽帧也不足以排除窗口交接的短暂闪现。黄色条带系统页、首帧遮罩和更密的交接复核以 [新验收记录](../startup-yellow-evidence/README.md) 为准。

应用及测试产物编译成功，Swift Testing 核心测试 19 项通过。iOS 27 已实际显示引导、展开词库、每日复习、空首页和有词首页；iOS 26.4 已确认有词首页与系统原生玻璃底栏。XCTest 服务连接失败，交互用例尚未执行，不能将截图等同于 UI 自动化通过。

## 已实现

- 主页面先构建，独立窗口覆盖应用开屏；黄色斜带退场后露出底层内容，减少动态效果时短淡出。
- 首次启动按引导状态、到期词、当天复习展示记录和提醒设置分流；正常启动不插入示例。
- 首页默认拍摄标签和日期模式，保留今天的空卡、分时问候以及零词分类。
- 今天无词但历史有词时，展开词库也保留今天的空分组；点击首页快照定位对应分组。
- 复习会话固定队列，避免评分后父级到期过滤变化导致漏词；到期时点改为启动数据读取完成时。
- `TabView` 继续使用系统原生外观，不叠加仿玻璃背景或自绘选中胶囊。

## 实际画面

以下场景均为 Debug 构建，用 `--uitesting` 隔离偏好并使用内存词库。示例 9 词是显式开发数据，不是默认安装内容。

| 文件 | 启动条件 | 已观察到的结果 |
| --- | --- | --- |
| [onboarding.png](onboarding.png) | `--exercise-startup --force-onboarding` | 本地引导、语言选择与「开始收集」按钮 |
| [library.png](library.png) | `--exercise-startup --seed-library --onboarding-complete --disable-daily-review` | 展开词库，今天 4 词，后续日期组；无四项底栏 |
| [review.png](review.png) | `--exercise-startup --seed-library --onboarding-complete` | 开屏后每日复习，首张为 `1 / 9` |
| [empty-home.png](empty-home.png) | `--preview-home` | 晚间问候、鼓励文案、今天 0 词卡、四项原生底栏 |
| [populated-home.png](populated-home.png) | `--seed-library --preview-home` | 9 词总数、今天 4 词快照、拍摄选中，iOS 27 原生底栏 |
| [native-home-ios26.png](native-home-ios26.png) | iOS 26.4，`--seed-library --preview-home` | 同一首页，系统提供的 Liquid Glass 外观 |
| [system-launch.png](system-launch.png) | 早期冷启动截图 | 旧实现的灰白 C 系统页；已确认与原版黄色条带背景不符 |

首批采样仅在 `simctl launch` 后等待 1–4 秒，误截到静态系统页。当前脚本默认等待 20 秒并要求人工核对画面。这个等待值只属于采样工具，不是 App 固定启动延时。

## 开屏录像

[完整本地采样录屏](startup-session-ios27.mov) 包含脚本依次启动各场景；[首段联系表](launch-filmstrip/contact-000.jpg) 展示最初 0–11.5 秒的抽帧。录像 SHA-256：`d2c5ea7cbf979eb48175ad90c05a977b03255eb68bddb744d178bccacaeea2da`。

根据 [抽帧元数据](launch-filmstrip/metadata.json) 的 `actualSeconds`：

| 录像时间 | 可见状态 |
| --- | --- |
| 约 1.990–5.577 秒的采样帧 | 系统静态启动画面 |
| 7.500 秒 | 黄色应用开屏、中央图案 |
| 7.992–8.853 秒 | 标题、装饰与图案展示 |
| 9.485 秒 | 黄色条带退场，词库已在底层可见 |
| 9.748 秒 | 完整展开词库；此采样不能排除更早交接时的单帧闪现 |

录屏在启动命令之前已经开始；以上是录像时间，不是进程启动耗时。采样录屏为可变帧率，部分请求时间返回同一实际帧；只说明已观察到的顺序，不能据此精确校准弹簧曲线或宣称真机帧率。元数据中的 `/tmp/capwords-startup-final27.mov` 是抽帧时的原始位置，目录内已保存同字节副本。

## 编译与测试

| 检查 | 结果与证据 |
| --- | --- |
| 应用／单测／UI 测试产物 | [build-for-testing.log](build-for-testing.log)：`TEST BUILD SUCCEEDED`；仅有未链接 AppIntents 的元数据提取提示 |
| 核心测试 | [core-tests.log](core-tests.log)：19 tests / 2 suites passed；覆盖路由、日期与原有核心模型 |
| iOS 26.4 XCTest 执行 | [runner-ios26.log](runner-ios26.log)：`DTServiceHubClient failed to bless service hub`，未开始测试，已停止等待 |
| iOS 27 XCTest 执行 | [runner-ios27.log](runner-ios27.log)：同类 `com.apple.instruments.deviceservice.lockdown` 错误，未开始测试，已停止等待 |

XCTest 执行日志来自本轮稍早的尝试；最新增加的时间基准修复和断言仅编译验证，并由最终复习截图确认首张 `1 / 9`。没有清空用户词库、重置模拟器或重启全局模拟器服务。

已编写但尚待执行的交互回归：完成引导进入词库、返回首页、前后台不重播、连续复习到 `2 / 9` 和 `3 / 9`、关闭复习回首页、今日已展示时不再提醒，以及原有拍摄保存删除流程。真正相机、减少动态效果、玻璃按压／拖动反馈、保存飞行和粒子流畅度仍需真机验收。

## 证据到实现

| Evidence | Finding | Path |
| --- | --- | --- |
| [REA 启动与首页报告](../2026-10-18_逆向-CapWords-启动与首页-report.md) E-001～E-004 | 主窗口先建、开屏覆盖、首轮条件导航 | `App/Views/LaunchView.swift` → `HomeView.prepareStartup()` → `StartupPolicy.route()` |
| 同报告 E-004／F-004～F-005 | 本地快照、自然日空卡、小时问候和首日期计数条件 | `HomePresentation` → `HomeView`／`LibraryView` |
| 本地 `review.png` 与代码检查 | 启动前固定的旧时间排除了准备期间新增词条，修复后首张 1/9 | `HomeView.prepareStartup()` 读取词库后刷新 `now` |
| 本地录屏和两版系统首页截图 | 开屏露出词库，26.4／27 的原生底栏正常渲染 | `LaunchCoordinator.finish()`；系统 `TabView` |

边界：Onboarding C 后续页面没有完整恢复，当前使用简化本地引导；不实现虚假订阅页。动画图案为独立重建，不使用原版获奖宣称；完整复习选词算法未知，当前沿用本地到期规则。旧 `hasLaunched`／已有词库的引导兼容是本地设计选择。研究证据、实现选择和本地运行验证不互相替代。

## 复现

从 `CapWordsSwift/` 执行，需安装 Xcode、提前启动对应模拟器：

```bash
export DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer
swift test --scratch-path /tmp/capwords-startup-core
bash scripts/verify.sh build-for-testing
export CAPWORDS_SIMULATOR_ID=CE0B9DF8-87CD-4D20-9AEB-0AE7163F777C
bash scripts/capture_startup.sh
```

用保留的录像重新抽帧（输出到新的临时目录，不覆盖本记录）：

```bash
capwords_frames=$(mktemp -d /tmp/capwords-launch-frames.XXXXXX)
swift -module-cache-path /tmp/capwords-video-module-cache scripts/extract_video_evidence.swift \
  docs/startup-implementation-evidence/startup-session-ios27.mov "$capwords_frames" 0.5 0 20
```

验收清单：实现与测试产物已编译、19 项核心测试已执行、目标画面已核对、录屏与日志已保存、差异与未验证项已列明。交互自动化及真机动态验收未完成。
