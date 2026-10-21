# CapWords 2.0.11 词库交互静态证据

分析日期：2026-10-19。范围见 [scope.md](scope.md)。报告使用普通逆向模板，`flavor = null`。

本次确认了最新版身份和截图中的中文空态文案，并保留了 `sticker_empty.pag` 动画候选。主程序仍有 FairPlay 加密，不能从该 IPA 可靠恢复今天为空时的翻页阈值、触觉强度或日期数字转场实现。UI 行为应由用户提供的截图与视频验证，调节出的参数应标记为复现选择。没有运行、安装或修改目标 App。

## 目标与证据

| 项目 | 值 |
|---|---|
| IPA | `CapWords_2.0.11.ipa` |
| IPA SHA256 | `61bb75c9a1f6329c9500d00f57bde2e3e09e0e6e6d604fccbad844a8b6ca52fc` |
| 版本 | 2.0.11，build 23 |
| Bundle ID | `com.HappyPlanTech.SnapWords` |
| 架构 / 最低版本 | arm64 / iOS 17.0 |
| 主程序 SHA256 | `01983ce0aa4eadea9aa20db9d726a404efb5e31c8f813abf006a26a525e6ffff` |

完整 REA 记录见 [rea-native-bundle.json](rea-native-bundle.json)。离线原始字节复核见 [offline-resource-evidence.json](offline-resource-evidence.json)。以下 E-id 是报告索引，REA 的不可变 ID 列在来源中。

| E-id | source_ref | 内容与 content_hash | repro_command |
|---|---|---|---|
| E-identity | `ev_0b2f1ca0a8d69e1f2682847e27f07925080b6c24c03fe24007a542608de6078c`，bundle `Info.plist` | 版本 2.0.11 / 23；载体 hash 为上表 IPA SHA256 | REA `inspect_plist`，path 为解包后的 `Payload/SnapWords.app/Info.plist` |
| E-macho | `ev_bf530b9cf224981cb503ed4ead618e93f1daaa416bfbbe7083d4744070a8c39d` | 主程序加密范围、段布局、依赖；载体 hash 为上表主程序 SHA256 | REA `open_binary` 指定主程序，再 `inspect_macho({"detail":"summary"})` |
| E-imports | 同 E-macho | 100 条依赖；导入规范化结果为 0 条且 `exhaustive=false`，不可解释为“没有导入” | 同 E-macho；详细记录保留在 bundle 中 |
| E-copy | `ev_c60afb915b30890558a3eae2862d086044f8252a91393614834ee561f7227d0e`，`zh-Hans.lproj/Localizable.strings` | `4b710d5b586f30be873da50f6ca568977ec72532d95c82b8afd17f941217e790` | REA `inspect_plist` 指定该资源；或下方复核命令 |
| E-resource | `offline-resource-evidence.json`、`sticker_empty.pag` | 1,027 字节，SHA256 `78ed26a27bf24b431631b35de6975af2a1cc435692ba65de03694b9fcac6e00d` | 下方复核命令 |
| E-bytecheck | `offline-resource-evidence.json` | 直接按 Mach-O load command 解析加密标记，并保留首段 64 字节；载体 hash 为主程序 SHA256 | 下方复核命令 |

从仓库根目录重复运行即可核验版本、摘要和加密范围，同时更新上述小型资源附件：

```bash
python3 CapWordsSwift/docs/library-2.0.11-evidence/inspect_resources.py CapWords_2.0.11.ipa
```

## 发现及实现含义

| F-id | 发现 | severity | evidence_ids | confidence / status | location |
|---|---|---|---|---|---|
| F-identity | 所选 IPA 确为 2.0.11 / 23 | n/a_re | E-identity、E-bytecheck | high / validated | `Info.plist` |
| F-encrypted | 加密标记 `cryptid=1`，从文件偏移 16,384 开始，长度 33,832,960 字节；覆盖 `__text`、Swift 类型与字段名、ObjC 类名和方法名区 | n/a_re | E-macho、E-bytecheck | high / validated | `LC_ENCRYPTION_INFO_64`，命令偏移 5,536 |
| F-copy | 空态文案与截图相符：`还没有拍摄任何单词呢～\n快看看身边有什么好玩的东西？` | n/a_re | E-copy、E-resource（脚本独立复核） | high / validated | 中文 Localizable.strings |
| F-eyes | 包含 PAG 格式的 `sticker_empty.pag`，名称与空态相关；尚未证明它被当前词库页面调用 | n/a_re | E-resource | medium / candidate | bundle 根目录 |
| F-libraries | 包含 UIKit、SwiftUI、CoreHaptics、libpag、RiveRuntime 和 Lottie 依赖；依赖存在不证明某个页面使用哪套动画或触觉 API | n/a_re | E-imports | high（依赖存在） / candidate（页面绑定） | Mach-O load commands |

F-identity、F-encrypted、F-copy 的两种解析均来自同一个载体，只是工具实现相互复核，并非独立运行时证据。它们描述静态字节事实；没有将其提升为已观测的执行行为。

## 原始实现覆盖情况

| 问题 | 状态 | 依据与剩余缺口 |
|---|---|---|
| 今天无拍摄时占满一页 | 未从 IPA 回收 | 以用户截图和视频作为行为证据；加密区域阻止恢复布局逻辑 |
| 越过空态页时的小震动 | 部分线索 | 包内存在 CoreHaptics 依赖；无法据此确定调用点、阈值和强度，触觉本身无法由普通录屏证实 |
| 今天有拍摄时正常连续滚动 | 未从 IPA 回收 | 以视频验证；未解出滚动策略 |
| 顶部日期固定及数字变换 | 未从 IPA 回收 | 以视频中的位置、过渡时刻和方向验证；没有将旧版类型或地址冒充本版实现 |
| 眼睛动画 | 部分线索 | 已保留 PAG 候选；本轮未渲染，缺少资源绑定、尺寸和播放时间轴的证据 |
| 中文空态文案 | 已回答 | REA 与本地 plist 解析一致 |

## 分析路径与限制

P-static：`path_type=solve`。从用户指定 IPA 开始，目标是给词库交互实现建立可追踪证据。步骤为：E-identity 确认版本 → E-macho / E-bytecheck 确认静态代码边界（F-encrypted）→ E-copy 确认文案（F-copy）→ E-resource 保存动画候选（F-eyes）→ 将未解出的行为交由截图与视频观测。该路径描述调查流程，不是已恢复的 App 调用链。

REA 的 native provider 检查显示：Ghidra 未配置，Hopper 启动器不可用，IDA 未配置。本轮未安装工具；即使安装反编译器，仍不能把这份加密代码当作明文处理。REA 原生工具提供了合法可用的 Mach-O 与 plist 静态读取。

`Assets.car` 大小为 120,698,504 字节。REA `inspect_asset_catalog` 在其 67,108,864 字节上限处明确拒绝，因而没有取得此目录的资产清单；这不能证明任何图片不存在。PAG 文件保留原字节，未执行其中动画。没有真机动态轨迹，不声称完成原版代码级复刻。

本轮时间线（同日，按顺序）：确认版本及主程序 hash；REA 读取 Mach-O 并识别加密；REA 与本地脚本核对中文资源；保留动画候选并记录资产目录限制；导出证据并关闭原生会话。
