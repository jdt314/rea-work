# CapWords：原生 Tabbar 与粒子细节

本轮根据 `1.mp4` 和 REA 的 IPA 检查更新现有工程。主页采用系统 `TabView`，由 iOS 26／27 提供原生 Liquid Glass，四项为拍摄、对话、复习、个人；日期与分类移到右上菜单，词卡列表仅保留中央快门。背景消散改为独立编写的 Metal 纹理碎片，随后由用户确认主体，展开白页并显示彩色点阵与结果柔光。构建通过且已检查 iOS 26 截图；iOS 27 白屏和自动化测试服务问题仍未解决，不能宣称双系统完整验收通过。

日期：2026-10-18，Asia/Shanghai。报告使用普通逆向模板，flavor=null。

## 范围与材料

授权及边界见 [scope.md](video-1-evidence/scope.md)。用户补充明确 tabbar 是 iOS 26／27 原生流体玻璃，因此没有使用自绘胶囊、material 背景或自绘选中层。没有运行原版 IPA，没有请求原应用后端，没有改变系统 Xcode 选择或用户词库。

| 材料 | 身份 |
| --- | --- |
| `1.mp4` | SHA-256 `a680eace97f1283ef0777957272d78049830e2fbb2812c124b2c732c6d25a3ef`；592×1280，32.966667 秒 |
| `cap.ipa` | SHA-256 `c6cc5aba8194c044fea2f7df1c92c290fb58502a90fdb5afd3df9522c9f61fe8` |
| `Payload/SnapWords.app/SnapWords` | arm64 Mach-O；SHA-256 `6954430ff4342d6f2b9a096245caf1921f3e3503212f438904378548e87b0265` |
| `DustEffectShaders.metal` | IPA 内打包源码；SHA-256 `fdc9cec7221d6f9a61611e593d9c9922705a1da93e91696d9f5642a03b209883`，与既有研究副本一致 |

## Evidence

| ID | source_ref | repro_command / 限制 | content_hash |
| --- | --- | --- | --- |
| E-001 | [视频观察及关键帧](video-1-evidence/OBSERVATIONS.md) | 该文档包含三条 AVFoundation 抽帧命令；metadata.json 保存 actualSeconds，文件名仅是请求时间 | 视频哈希见上表 |
| E-002 | [REA 证据包](video-1-evidence/rea-evidence.json)，`ev_6c658e68d2ac4a7de478ae226e963069f7d98602912d38ef58d08feedbe8e2ec` | REA `open_binary` 打开项目根绝对路径 `cap.ipa`，随后 `inspect_artifact({detail:"summary"})` | IPA 哈希见上表 |
| E-003 | REA 提取 `ev_d0d94f457deb2f5c391f951f3af8f67da7f203dc0cc686a639f9c581a22a21e8`；[既有 shader 副本](../../capwords-analysis/evidence/ipa/capture-flow/DustEffectShaders.metal) | 活动 IPA 上调用 `extract_artifact({})`；提取清单保留每个成员 SHA-256；可对副本运行 `shasum -a 256` | shader 哈希见上表 |
| E-004 | Mach-O 父记录 `ev_10c4b00ad98e1823f7432c7043450a7d9722071fd4e95061fef967261e1237ba`；依赖页 `ev_16a535e4ddf05b579d5e5512e44ab1a208e6bde3e8d2154ea083db971e60c481` | REA 打开提取的 `.app`，`inspect_macho({detail:"summary"})`；`inspect_analysis_view` 读取 dependencies | Mach-O 哈希见上表 |
| E-005 | [iOS 26 主页](video-1-evidence/ios26/home.png)、[消散](video-1-evidence/ios26/dust.png)、[等待](video-1-evidence/ios26/floating.png)、[结果](video-1-evidence/ios26/result.png) | 构建后运行本文末尾 capture_screenshots.sh 命令；示例素材，内存词库 | n/a，生成截图 |
| E-006 | [验证日志摘录](video-1-evidence/verification.txt)；`.build/Logs/Test/` 两次 xcresult | `scripts/verify.sh test`；iOS 26.4／27.0 runner 均未建立连接，实际测试断言未执行 | n/a，运行日志 |

REA 清单观察到 388 个文件、140 个目录，无完整性冲突。原生依赖页包含 SwiftUI、UIKit、Metal、MetalKit、QuartzCore 和 Vision；依赖存在不证明某条具体运行路径。当前没有可用深度反编译 provider，因此复用了身份一致的既有 CPU 调度分析；本轮没有声称新增函数反编译。主 Assets.car 为 119,352,312 字节，超出 REA 64 MiB 读取限额；记录该限制，不通过未读取的图集推导图标尺寸。

## Findings

| ID | 结论 | evidence_ids | severity | confidence | location | status |
| --- | --- | --- | --- | --- | --- | --- |
| F-001 | 视频主页有四项玻璃底栏，日期／分类属于右上菜单；词卡列表底部是独立快门 | E-001 | n/a_re | high | 25–31 秒主页、2.7–24 秒列表 | candidate，基于录屏观察；原生实现选择由用户明确 |
| F-002 | IPA shader 使用横向渐进激活、42–84 随机速度、0.7–1.5 初始寿命和最后 0.3 寿命淡出 | E-003 | n/a_re | high | initialize / update / vertex / fragment | candidate，静态源码语义 |
| F-003 | 灰褐大主体阶段与白页点阵等待是不同阶段；可见确认／重做／裁剪，不能把整段录屏耗时写成固定 sleep | E-001 | n/a_re | medium | 7.8–17.5 秒 | candidate，无触摸标记，确认门控属于实现解释 |
| F-004 | 新实现已在 iOS 26 截图中显示系统玻璃 tabbar、背景碎片和规则彩色点阵 | E-005 | n/a_re | high | 本地模拟器截图 | candidate，非真机逐帧测量 |
| F-005 | 两系统 XCTest runner 连接失败；iOS 27 直接启动截图为白屏，原因仍未知 | E-006 | n/a_re | high | 本机模拟器／测试服务 | candidate，未归因为某个应用函数 |

## 实现路径

P-001，path_type=callflow：E-001 → F-001 → `HomeView` 的系统 `TabView` → 日期／分类快照 → `LibraryView` → 独立彩色快门。系统管理玻璃材质、选中态和触摸交互。视频未展示后三个标签的内部页面，当前复用本地例句朗读、既有复习与设置；没有声称恢复原版在线对话。

P-002，path_type=callflow：E-003 → F-002 → `DustSampler` 将背景与主体 alpha 放到同一采样网格 → 最长边 720 的 RGBA 纹理 → Metal 实例化纹理小片 → 左到右激活 → 寿命末段渐隐 → GPU 资源清理。phase 速度 2.2、容器期限约 1.818 秒来自[身份一致的既有 CPU 分析](../../capwords-analysis/CAPTURE-FLOW.md)。`simulationAge` 对 `2 × activation × dt` 做解析积分，随机值采用独立散列；它不是原版 Loki 随机序列和离散 compute 更新的逐指令复制。渲染坐标转换将 shader 的正 Y 映射为屏幕向上；这是静态坐标推导，视频无法可靠追踪单粒子速度。

P-003，path_type=callflow：E-001 → F-003 → `CaptureFlow.cutout` 等待确认 → 用户点勾 → 白页从下展开、主体缩小 → 彩色点阵呼吸与主体悬浮 → 黄色柔光、星芒和词签 → 保存飞向实际词库坐标。没有复制录像约六秒的等待；本地识别已完成时只保留 1.1 秒过渡。减少动态效果时跳过粒子与周期位移。

RGBA 栅格接口统一为左上角坐标，但 CGContext 的绘制 rect 仍需要 `height - rect.maxY` 转换。独立非对称 alpha 实验验证了该转换；旧版本的 `1 - maxY` 本身不是已确认缺陷。新增 `ParticleTests` 覆盖非对称 mask、释放时序、淡出、纹理和随机独立性，但本机 XCTest 未执行成功。

## 构建与验收

- 最终通用模拟器构建通过，Swift 6 严格并发检查通过。内嵌 Metal 程序已在 Apple M4 实际编译成功；iOS 26 截图可见碎片渲染。
- iOS 26 截图覆盖主页、分类、列表、相机、消散、等待、结果、详情和复习。截图脚本通过 DEBUG 入口直接进入阶段，不等价于触摸自动化通过。
- iOS 26.4／27.0 的 XCTest 均报告 `The test runner hung before establishing connection` 与 `DTServiceHubClient failed to bless service hub`。没有将编译成功写成测试通过。
- iOS 27 直接启动返回进程，但截图为白屏。一次线程采样显示主线程在 UIApplication 事件循环，未观察到粒子计算死循环；这一采样不能确定白屏原因。
- 真机相机、分割质量、逐帧性能、不同设备玻璃样式，以及保存/重拍全流程仍需真机或恢复后的 XCTest 验证。

在项目根执行：

```bash
bash CapWordsSwift/scripts/verify.sh
CAPWORDS_SIMULATOR_ID=59D5891F-5C9D-4425-9F0E-0415C74963D4 \
  CAPWORDS_SCREENSHOT_DIR=docs/video-1-evidence/ios26 \
  bash CapWordsSwift/scripts/capture_screenshots.sh
CAPWORDS_SIMULATOR_ID=59D5891F-5C9D-4425-9F0E-0415C74963D4 \
  bash CapWordsSwift/scripts/verify.sh test
```

设备 ID 是本机示例，其他主机需替换为 `xcrun simctl list devices available` 返回的 ID。脚本会设置正确的 `DEVELOPER_DIR`，未修改系统 `xcode-select`。

## 时间线与检查

2026-10-18：复用既有证据 → REA 验证 IPA／提取 shader／读取原生依赖 → 新视频概览与细帧 → 按用户澄清采用原生 TabView → 实施纹理碎片、确认阶段、点阵与全屏布局 → 构建、GPU 程序编译与 iOS 26 截图 → 记录 XCTest 连接失败与 iOS 27 白屏。

已核对：原生 tabbar 与粒子修改已落地；证据、实现选择和未知项分别注明；没有借用旧视频时间轴解释新视频；没有将录屏等待时长视为网络常量。端到端自动化与 iOS 27 显示仍未通过验收。
