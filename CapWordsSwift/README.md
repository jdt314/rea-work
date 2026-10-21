# Wordrove

应用名称：**Wordrove**；Bundle ID：`cn.a2px.wordrove.dev.f89luflt5b.c9e48b12`。

基于仓库中的 CapWords 研究、`1.mp4` 与 IPA 证据，用原生 SwiftUI 实现拍摄、贴纸词库和基础学习流程。使用 **Xcode 27 beta / Swift 6.4** 编译，Swift 6 语言模式和严格并发检查，最低支持 iOS 18，无第三方运行依赖。主页使用系统 `TabView`，iOS 26／27 由系统提供 Liquid Glass；旧系统使用其原生 tabbar 外观。

启动分支、首页默认内容与原生底栏已实现。核心测试 19 项通过，应用及测试产物编译成功；iOS 27 已实际显示引导、展开词库、每日复习与首页。iOS 26.4／27 的 XCTest runner 仍因服务连接错误未执行，不能视为 UI 自动化通过。截图与验证边界见 [启动实现验收记录](docs/startup-implementation-evidence/README.md)，研究依据见 [启动与首页报告](docs/2026-10-18_逆向-CapWords-启动与首页-report.md)。

2026-10-19：已修复系统启动页到动画之间的内容闪现。系统静态页、主窗口兜底遮罩和应用动画共用黄色条带 PNG；本轮 iOS 26.4／27 录屏逐帧检查未再出现提前露出词库。见 [最新启动衔接验收](docs/startup-yellow-evidence/README.md)。

2026-10-19：词库已补齐空白今天的整屏眼睛动画、上滑弹入历史与即时轻触觉、从历史整页弹回空白、历史连续滚动、固定日期数字过渡。空白页向下滑不触发。今天保存首词后移除空白页并回到当天。核心测试现为 27 项通过，应用和 UI 测试产物编译通过；手势自动化仍受本机 XCTest 服务连接失败影响。见 [词库交互验收](docs/library-interaction-validation/README.md)、[视频逐帧依据](docs/video-2-evidence/notes.md) 和 [2.0.11 IPA 分析](docs/library-2.0.11-evidence/2026-10-19_逆向-CapWords词库-report.md)。

2026-10-19：按 `4.mp4` 优化拍照到识别：抠图先展示，AI 请求独立继续，主体确认后白页展开并悬浮等待；结果分阶段揭示，失败保留贴纸，可重试或手动填写。核心测试 39 项通过，应用编译成功，见 [研究与验证报告](docs/2026-10-19_逆向-CapWords拍照识别流程-report.md)。

2026-10-19：按 `4.mp4` 修正识别结果的中英文排版、字形白边、确认按钮尺寸和位置；相机关闭与相册采用 iOS 26+ 原生透明玻璃。39 项核心测试通过，5 个结果场景通过按钮几何和中文 OCR 检查。见[对照图与验收记录](docs/result-alignment-validation/README.md)。

## 运行

用 Xcode 打开 [CapWordsSwift.xcodeproj](CapWordsSwift.xcodeproj)，选择 `CapWordsSwift` Scheme 和 iPhone 模拟器，点击运行。真机运行需要在 Signing & Capabilities 中选择自己的开发团队。

```bash
cd CapWordsSwift
bash scripts/verify.sh
```

启动先创建拍摄主页，再覆盖应用开屏；开屏退场后按本地状态进入对应页面：

- 新用户：简化引导覆盖空词库，选择学习语言并点击「开始收集」后留在词库。
- 已引导用户：自动展开按日期分组的词库；返回后看到四标签首页，不会在本次会话反复自动展开。
- 已引导、有到期词、今天尚未展示复习且未关闭提醒：开屏退场后展示每日复习。提醒可在个人设置关闭。

系统 LaunchScreen 只能静态显示，不能直接执行应用动画。当前用相同首帧衔接：`LaunchScreen.storyboard` 显示条带与居中 C，主窗口遮罩保留至独立动画窗口开始退场，再揭开已准备好的内容。模拟器构建使用 ad-hoc 签名，不能关闭资源签名，否则系统可能拒绝生成启动快照。

四个系统标签为「拍摄 / 对话 / 复习 / 个人」；首页默认日期模式，右上菜单可切换分类，点击快照进入对应词库分组。列表底部只保留彩色快门；点击主页大快门也可进入拍摄。正常运行不自动插入示例，不显示「试试示例词库」入口。模拟器取景明确标注为示例，相册可导入真实图片；真机使用 AVFoundation 后置摄像头。

## 已实现

| 流程 | 行为 |
| --- | --- |
| 启动 | 独立开屏覆盖窗口、黄色条带退场、引导／词库／每日复习路由、减少动态效果适配 |
| 词库 | 日期分组、空白今日整页切换、固定日期数字动画、顶部下拉相机、双列贴纸、分类浏览、搜索、详情、修改、确认删除 |
| 拍摄 | 真机相机、相册选择、方向归一化、长边限制、缩放与拖动裁剪 |
| 图像处理 | Vision 前景实例分割、透明主体裁切、失败时保留完整场景 |
| 命名 | DeepSeek 官方图片识别，生成双语词条、读音和例句；不确定时手动命名 |
| 语言 | 英语、日语、韩语、西班牙语、法语；切换作用于新词卡 |
| 结果 | 细密纹理粒子消散、主体确认、白页展开、彩色点阵悬浮、黄色呼吸光晕、确认保存 |
| 主页与标签 | 系统原生 Liquid Glass tabbar、日期／分类快照、今天空卡、分时问候、词卡例句朗读、个人设置 |
| 学习 | 系统语音朗读、英语词条预置情境例句、翻卡复习、递增间隔与遗忘重学 |
| 存储与导出 | SwiftData 本地持久化、贴纸外部文件存储、剪贴板、PNG 保存至相册 |

已接入 DeepSeek 官方云端图片识别。请在「个人 → AI 图片识别」配置 API Key，默认官方接口和 `deepseek-flash` 模型（当前对应 V4.1-Flash-1017）。密钥保存在本机钥匙串；尚未使用真实密钥验收线上效果，详见 [AI 接入说明](docs/AI-RECOGNITION.md)。不调用 CapWords 后端。当前前景选择保留所有检测实例；中心主体筛选、跨帧分割、动态贴纸、AI 聊天、订阅、云同步和系统扩展属于后续阶段。

## 界面对照

词库、相机与结果页以 [VIDEO-VALIDATION.md](../capwords-analysis/VIDEO-VALIDATION.md) 的截图和流程为准：近白纸面、18 pt 点阵、衬线日期、两列独立贴纸、圆体粗黑白底标签、底部五色快门、结果页柔光与三枚圆按钮。

今日顶部下拉进入相机已按视频 3 实现，支持空白今日和已有词卡的今日。满宽纸面跟手下移、圆角展开、日期变白、快门原地放大，关闭时整页回弹。对照录像、最新版 IPA 的 REA 证据和验证边界见[下拉相机记录](docs/camera-pull-validation/README.md)。

相机静态界面按 10 月 19 日补充的原版截图对齐：白色状态栏、四角框、18pt 中文提示、约 100pt 彩色快门与 50pt 透明辅助按钮。实际模拟器截图、IPA 加密检查和 REA 能力边界见[相机对照记录](docs/camera-alignment-validation/README.md)。

已有录像仅覆盖部分页面，且混用不同语言和日期。引导、设置、编辑、详情和复习页采用同一视觉体系补齐；不能据此声称与原版逐像素一致。开屏图案为独立几何重建，不复制原版获奖标识；未接入商品服务，不展示虚假购买页。粒子使用独立编写的 Metal 纹理碎片渲染，根据 IPA 验证的释放／寿命语义重建；无 Metal 时回退到 Canvas。随机生成器、解析积分、主体悬浮及保存飞行属于复现实现。对话标签提供本地词卡例句练习，尚无在线对话能力。完整差异与研究引用见 [实现对应表](docs/IMPLEMENTATION.md)。

示例贴纸从仓库已提供的视频帧裁剪而来，相机示例背景取自用户截图中不含控件的桌面区域，仅用于本地开发对照，没有复制 IPA 中的原应用代码、图集或私有接口。应用图标由脚本绘制。重新生成示例素材需要 Python 3 与 Pillow：

```bash
python3 scripts/prepare_reference_assets.py
```

黄色启动背景为独立重建，使用 `swift scripts/generate_launch_bands.swift` 生成 `App/Resources/LaunchArtwork/` 中的 1x／2x／3x PNG。直接打包图片，不通过系统启动页上曾加载失败的图集路径；动画显式使用同一 UIKit 图片。

## 测试

以下命令从 `CapWordsSwift/` 执行。核心测试不依赖模拟器：

```bash
export DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer
swift test --scratch-path /tmp/capwords-startup-core
```

模拟器 XCTest／UI 测试（当前机器 runner 服务连接失败，须恢复服务后执行）：

```bash
export DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer
xcrun simctl list devices available
CAPWORDS_SIMULATOR_ID=CE0B9DF8-87CD-4D20-9AEB-0AE7163F777C bash scripts/verify.sh test
```

核心测试覆盖启动路由、引导状态兼容、自然日复习抑制、小时／时区／跨年／夏令时边界、今天空分组与计数，以及原有复习调度、词库写入删除、种子幂等、分类和图像几何。iOS 测试还包含裁剪边界与坏图检查。

UI 用例包含原生四标签、空词库、搜索、模拟拍摄、编辑保存删除，以及新用户引导、老用户自动词库、前后台不重播、每日复习和连续评分不跳词。目前用例仅通过编译，未实际执行。`--uitesting` 使用内存数据库和独立偏好 suite，不影响正常词库。

用已启动的开发模拟器采样启动页面：

```bash
export CAPWORDS_SIMULATOR_ID=CE0B9DF8-87CD-4D20-9AEB-0AE7163F777C
bash scripts/capture_startup.sh
```

采样脚本默认每次启动后等待 20 秒，并不是应用开屏时长；可用 `CAPWORDS_CAPTURE_WAIT_SECONDS` 调整为 5–60 秒。截图必须人工确认页面，不能当作自动化断言。仅 Debug 构建响应 `--seed-library`、`--force-onboarding`、`--onboarding-complete`、`--reviewed-today`、`--disable-daily-review`、`--preview-home` 等开发参数；`--exercise-startup` 用于测试时保留真实应用开屏。

真实相机、相册权限拒绝、复杂图像的系统分割质量、系统声音与照片导出仍需在 iPhone 上验收。

## 继续开发

源码按 `Models / Services / Views` 划分。`RecognitionService` 是本地分割与云端识别入口，`CaptureFlow` 管理可取消的处理与展示阶段，`Word` 是本地存储模型。新增文件后可使用已安装的 XcodeGen 重建工程：

```bash
xcodegen generate
```

下一阶段优先恢复 XCTest 服务并执行交互回归，再结合真机录屏校准玻璃底栏、启动与粒子动画。线上识别验收、中心主体选择、完整引导和真实订阅仍需单独实现。
