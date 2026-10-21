# CapWords：从开屏到首页的逻辑与默认内容

分析日期：2026-10-18。对象：用户提供的 `cap.ipa`（2.0.9 / 445）与 `1.mp4`。本轮仅研究，没有修改 App 源码。

## 1. 结论

启动不是“播放完开屏，再创建首页”：程序先建立主窗口和首页，再用一个独立窗口覆盖开屏。默认根页面是「拍摄」，首页构造默认使用日期模式，但首页首次布局会自动打开词库；新用户还会在词库上叠加 Onboarding C，符合条件的老用户则转入每日复习。普通词库路径还会在开屏完成后检查是否展示订阅页。因此，“默认 tab”“默认首页布局”和“开屏后第一张可见页面”是三件不同的事。

首页内容来自本地 Core Data 词库快照，不应将视频中的 17 个词当作安装预置数据。零词库时会创建当月/今天的空容器，显示拍摄提示；问候语按本地时间生成。视频中开屏直接露出展开词库，随后返回四项底栏首页，与上述自动展开路径相符，但视频不能证明当时的会员、引导或复习标志值。

限制：REA 完成包、plist、Interface Builder 和 Mach-O 证据读取；函数逻辑由 Swift/ObjC 元数据及 LLVM ARM64 指令补足，不是声称 REA 已恢复原始 Swift 源码。没有运行这份 IPA 的清洁安装/老用户真机测试矩阵。样本含解密/重打包迹象，结论限定于本样本，不保证适用于所有官方发行包。

## 2. 范围与证据身份

授权和工作项见 [scope.md](../../capwords-analysis/evidence/ipa/startup/scope.md)，研究过程见 [timeline.md](../../capwords-analysis/evidence/ipa/startup/timeline.md)。本轮离线，不访问生产接口，不改变引导、购买或用户数据。

| 对象 | 身份 |
| --- | --- |
| IPA | SHA-256 `c6cc5aba8194c044fea2f7df1c92c290fb58502a90fdb5afd3df9522c9f61fe8` |
| `SnapWords` arm64 | SHA-256 `6954430ff4342d6f2b9a096245caf1921f3e3503212f438904378548e87b0265` |
| `1.mp4` | SHA-256 `a680eace97f1283ef0777957272d78049830e2fbb2812c124b2c732c6d25a3ef`；592 × 1280，约 32.97 秒 |
| 包配置 | 最低 iOS 17.0，SDK `iphoneos27.0`，版本 2.0.9（445） |

导入/依赖证据包含 UIKit、SwiftUI、Metal、MetalKit、QuartzCore、Vision。依赖只证明链接关系，具体启动行为以下述调用和状态存储为依据。REA 依赖记录为 `ev_16a535e4ddf05b579d5e5512e44ab1a208e6bde3e8d2154ea083db971e60c481`，完整 Mach-O 记录为 `ev_10c4b00ad98e1823f7432c7043450a7d9722071fd4e95061fef967261e1237ba`。

## 3. 开屏与主页面的先后关系

### 3.1 系统启动画面不是应用动画

2026-10-19 复核更正：`LaunchCanvas` 是底层灰白颜色，不是完整可见启动画面。补读 NIB 对象引用和四边约束、核对 Assets.car 后，确认全屏不透明 `launch_band_background` 覆盖其上，另有居中 86×86 的 logo。因此原版仍有系统静态页，但它应与黄色条带应用动画首帧视觉连续；旧灰白 C 页复刻不正确。详见 [启动衔接复核](2026-10-19_逆向-CapWords-启动衔接复核-report.md)。原始证据保留，不将布局复核冒充原版运行结果。

`Info.plist` 指定 `UILaunchStoryboardName = NeutralLaunchScreen`，Scene delegate 为 `SnapWords.SceneDelegate`，不支持多个 Scene。

REA 识别的两个编译后 nib 共 26 个节点中，有背景图 `launch_band_background`、中央图 `onboarding_launch_logo` 和 `LaunchCanvas` 颜色。logo 的宽、高约束值各为 86，背景颜色分量约为 `244/255`。这只能还原已识别的静态资源与字段；IB 图的 `hierarchy_complete=false`，不能据此宣称完整布局或运行时像素已恢复，也不能说系统 LaunchScreen 自己播放标题/麦穗动画。

### 3.2 主窗口先建立，动画窗口覆盖在上面

| 阶段 | 指令与状态 | 作用 |
| --- | --- | --- |
| App 启动 | AppDelegate IMP `0x1000192bc` → `0x100019620` | 应用初始化；与具体窗口建立分开 |
| Scene 连接 | IMP `0x10001b114` → `0x10001c9c8` | 读取连接参数、URL/user activity，建立主 UIWindow |
| 主页面构造 | `0x10001c6e4` | 设置外观；先置开屏协调器可见、清完成队列；创建 MainPage，设置 root、`makeKeyAndVisible`，标记 `didShowMainPage` |
| 开屏覆盖 | `0x10001b194` | 创建 AppLaunchAnimationWindow，透明背景、`StatusBar + 2` 层级、禁用交互；root 为 AppLaunchAnimationViewController |
| 动画结束 | `0x10001b348` | 隐藏并释放开屏窗口/root，让主窗口重新成为 key |
| 完成通知 | `0x1000064f4` | 将可见标志写 false，取出并清空 finishHandlers，逐个执行，再发 didFinishNotification |

主页面不以“等网络返回成功”作为这条窗口构造路径的前置条件。这不等于整个 App 启动没有其他网络初始化。

MainPage `viewDidLoad` 的实现 `0x1001a9d60` 建立页面顺序为 homeNav、chatNav、flashCardNav、profileNav，明确选择 `pages[0]`，无动画，`currentIndex=0`。homeNav 根控制器 accessor `0x100a2eaa0` 绑定 `HomeCollectionViewController`。视频底栏对应「拍摄／对话／复习／个人」，默认拍摄选中。

### 3.3 动画参数及完成时机

下表来自 AppLaunchAnimationView 字段、初始化 `0x1000130c4` 与实际动画调用，不是按录像目测估算。

| 项目 | 参数 | 解释 |
| --- | --- | --- |
| logo / 标题 | logo 86；titleOffset 20 | 参考布局尺寸 393 × 852 |
| logo 上移 | 延迟 0.2 秒；spring response 0.62、damping 0.84 | 位移 `-clamp(height × 0.027, 12, 32)` |
| 标题显现 | 延迟 0.4 秒；easeOut 0.42 秒 | opacity 到 1，titleLift 到 20 |
| 麦穗生长 | 延迟 0.4 秒；spring response 0.78、damping 0.72 | wheatGrowProgress 到 1 |
| 退场开始 | exitStartDelay 2.0 秒 | 调度应用层退场，不是整个进程启动耗时 |
| 图案淡出 | easeOut 0.16 秒 | launchArtworkOpacity 到 0 |
| 条带退场进度 | spring response 1.0、damping 1.0 | exitProgress 到 1；字段虽叫 duration，调用点用作 spring response |
| 正常完成 | 进度达到 0.76 | 是进度阈值，不是 0.76 秒 |
| 兜底回调 | 2.0 + 1.0 + 0.2 = 3.2 秒的调度 | 不是每次强制等到 3.2 秒才进入内容页 |

因此复刻时不能把整个启动写成固定等待三秒，再替换成首页；需要底层页面已就绪、覆盖层退场及完成队列这三个环节配合。

## 4. 开屏结束后究竟看到哪一页

### 4.1 首页首次布局负责自动导航

触发点为 `HomeCollectionViewController.viewDidLayoutSubviews`：ObjC IMP `0x100a3131c` → `0x100a2eab4`。先检查实例 `isFirstLoad`；非首次直接跳过。下面是该首次分支的静态行为，不把视频当成所有状态的实测。

| 条件 | 页面行为 | 证据位置 |
| --- | --- | --- |
| 未展示引导，或标志缺失 | 以 `(section:0,row:0)` 无动画打开 StickerCollectionViewController；若已经有 presented controller，再在其上无动画展示 OnboardingCViewController，并写实验分组 `C` | `0x100a2ef18`–`0x100a2f008` |
| 已展示引导，且每日复习条件全部成立 | 预热复习媒体，等待开屏完成及 view 已进入 window，再无动画打开 FlashCardViewController | `0x100a2f2bc`、`0x100a32eec`、`0x100a30f58`、`0x100a325c0` |
| 已展示引导，复习条件不成立或复习数组为空 | 同样以首日期项无动画打开 StickerCollectionViewController | `0x100a2f398`、`0x100a2f568` |
| 该 Home 实例已完成首轮导航 | 不再从此首次分支重复自动展开 | `0x100a2ef04`；词库路径 `0x100a30640` 清标志 |

词库控制器以首个 DailyStickerInfo 为入口，不代表页面只能显示一天。视频里同屏有 10 月 18 日和 10 月 17 日，准确名称是“按日期分组的展开词库”。

首轮布局另排队约 0.1 秒后的显示操作，恢复首页导航、collection 与 MainPage.tabbar 的 view 可见性。tabbar getter `0x1001a980c` 与 ObjC ivar `0x101f64a30` 对应；这不是开屏总时长。

### 4.2 每日复习不是无条件默认页

该分支要求同时满足：已展示引导、持久化词条数至少 1、`flashcardPreviewDate` 缺失或不是今天、未关闭每日复习提醒、构建出的复习数组非空。

资格函数 `0x100027af4` 使用本地日历的同日判断；Home 在 `0x100a2f2bc` 后组合其余条件，并写 `shownFlashCardTryDemo=true`。媒体预热最多取 5 项，这不意味着复习页只容纳 5 个词。完整复习选词/去重规则未在本轮展开。

### 4.3 普通词库之后还有订阅门控

普通词库路径先检查 AppLaunchAnimationCoordinator：开屏仍可见时把回调放入 finishHandlers，否则立即继续。回调经过 `0x100a44274` → `0x100a3122c` → `0x100a345e8`。

后者读取 `purchaseHasActived`（tag 4）：值为 true 时直接回调；否则创建 `PurchaseBViewController`（accessor `0x10038cbac`），从已有 presented controller 或 Home 以动画方式展示。该实现还比较 `ui_main_paywall_b` 配置标识。

这是“订阅页可能在开屏退场后出现”的静态依据，不是本轮实际购买测试，也不证明视频用户未显示订阅页的唯一原因。后续回调 `0x100a349cc` 仍存在额外条件逻辑，本轮没有穷尽所有后续提示弹层。

### 4.4 不应混用的状态字段

| key | 本轮确认的用途 |
| --- | --- |
| `hasShownOnboarding` | Home 首轮导航使用的引导门控 |
| `completeOnboarding` | 另一个完成状态；不能替代前者解释本次 Home 分支 |
| `appOnboardingExperimentVariant` | 新用户路径写 `C` |
| `flashcardPreviewDate` | 判断今天是否已预览复习 |
| `isCloseFlashCardDailyReviewAlert` | 用户是否关闭每日复习提醒 |
| `purchaseHasActived` | 普通词库后订阅页面门控 |

底层 `0x100068f74` 返回 Optional<Bool>，缺失/解析失败为 nil 编码 2；调用点检查 bit 0，因此在这些分支中 nil 与 false 同路，并非读取器直接返回 false。AppDelegate 还存在 `hasShownOnboarding` 向 `completeOnboarding=true` 的兼容写入路径，但其上游条件没有被简化为“每次必执行”。测试专用 `UITEST_FORCE_ONBOARDING_COMPLETE` 也不属于普通默认行为。

## 5. 首页默认展示什么

### 5.1 数据和布局

| 内容 | 确认结果 | 边界 |
| --- | --- | --- |
| 默认 tab | 拍摄，index 0 | 首轮弹层可覆盖它 |
| 默认布局 | 日期模式；`currentLayoutStyle=0`，分类分支明确比较 1 | 本次构造没有恢复上次分类模式；未审计全 App 的其他恢复入口 |
| 词库数据 | `viewContext` → StickerLibrarySnapshotStore → 应用快照 | Home 初始化本身没有生成固定演示词条；不排除别处迁移/导入 |
| 排序来源 | 快照构建对 StickerItem 发起 `createDate` 降序 fetch | 不是仅从视频位置猜排序；跨时区/分组边缘未全面验证 |
| 空词库 | 构造当前月份与当天 DailyStickerInfo，其 stickers 数组为空 | 空日期卡不等于伪造一条已识别词 |
| 分类模式 | 用户可在菜单切换；视频中零词分类也显示 | 视频可见六类不是完整类目清单 |

默认字段写入在 `0x100a2ac40`，快照读取在 `0x100a2adb4`，快照 fetch/sort 在 `0x1000590f8`、`0x100059174`。零词库容器构造在 `0x100a2b468`–`0x100a2b704`。快照还有缓存、dirty 标志和版本校验，不是每次 UI 刷新都无条件重新 fetch。

### 5.2 欢迎区、计数与空卡

欢迎区由日期、随时间变化的问候、状态文案和大彩色快门构成。简体中文来自包内 `zh-Hans.lproj/Localizable.strings`，已[独立解析并与保存的整表对照](../../capwords-analysis/evidence/ipa/home-defaults/localization-proof.json)。资源与实际调用绑定如下：

| 状态 | 文案/规则 |
| --- | --- |
| 04:00–11:59 | `早上好 :)` |
| 12:00–17:59 | `下午好 :-)` |
| 18:00–03:59 | `晚上好 (^▽^)` |
| Header 初始 wordsCount=0 | `用一个新单词，开启美好的一天` |
| 非零状态 | 对 `Snap %d Words captured` 本地化并格式化；视频显示“真棒！已经收集了17个单词” |
| 空卡第一条 | `还没有拍摄任何单词呢～`，换行 `快看看身边有什么好玩的东西？` |

问候函数 `0x100060ba4` 实际读取 `Calendar.current` 的 hour；navbar 初始化、viewWillAppear 和 Header 渲染均有调用，不是仅在字符串表中找到文案。

计数有一个值得保留的条件：`0x100a36c28` 后的刷新实现先检查扁平化日期数组及首日期项的 stickers。没有日期项或首项为空时，写入 Header 的数量为 0；首项非空才调用 `0x100058920`，累加缓存中 sticker URI 数量，或回退 Core Data 总数。因此不能将该 Header 在所有状态下都实现为“全库总数”。尚未由真机验证“今天为空、历史有词”时最终所有 UI 更新的组合效果。

空卡文案索引初始为 0，数组还有三条后续提示：“用一个新单词开启今天吧，随手拍下身边的物品”“今天还没结束呢，来记录下第一个单词吧：）”“今天想挑战 5 个单词吗？”。已找到索引加一并循环归零的函数，但没有证明固定轮播周期，不应自行加定时轮播。

## 6. 与视频逐段对齐

| 实际解码时间 | 可见事实 | 对逻辑的意义 |
| --- | --- | --- |
| 2.133–2.400 秒 | 黄色对角条带直接揭开词库 | 没有观察到先闪出四 tab 首页再点击进去 |
| 2.433 秒 | 展开词库完整出现 | 同屏有 10/18 的 4 词和 10/17 的 9 词 |
| 拍摄保存后 | 扩展坞成为首项，10/18 从 4 增为 5 | 本次新增改变本地词库展示 |
| 24.200–24.633 秒 | 贴纸缩回日期卡，欢迎区、大快门、四 tab 逐渐出现 | 连续返回上层首页，不是凭跳切猜测页面关系 |
| 25.000 秒 | 10月18、下午好、17词、拍摄选中 | 这是该会话的数据和时间，不是安装默认常量 |
| 29.000 秒 | 菜单“按日期展示”勾选 | 与静态默认日期路径相符，但视频本身不证明初装默认 |
| 30.000 秒 | 切换分类后回到顶部 | 欢迎区和底栏仍保留 |

视频后段可见日期计数为：10/18 五词、10/17 九词、10/16 一词、1/11 一词、1/10 一词，共 17。结合本次新增一词，不能将这 17 词写死为首装样例。

详细截图、时间元数据和补抽命令见 [视频观察](video-1-evidence/STARTUP-OBSERVATIONS.md)。关键帧：[开屏后词库](video-1-evidence/launch-navigation/t0002450.jpg)、[返回后首页](video-1-evidence/overview/t0025000.jpg)。文件名为请求时间，以 metadata 中的 actualSeconds 为准。

## 7. Evidence → Finding → Path

### 7.1 Evidence

下列证据 observed_at 均为 2026-10-18，source_type 为 file/command（E-005 另含 screenshot），supersedes 为 none。SHA-256 针对所链接的 artifact_path；完整原始材料位于同目录。复现命令见下一节；E-001 可离线读取保存的 REA 记录，不要求再次解包。

| E-id | source_ref / artifact_path | content_hash | raw_excerpt / 工作项 |
| --- | --- | --- | --- |
| E-001 | [REA 11 条完整记录](../../capwords-analysis/evidence/ipa/startup/rea-evidence.json) | `de77c743b21f78d3a89143901f8e7b5ff072e0f18d4b90fc165e5db7a971c7a3` | NeutralLaunchScreen、SceneDelegate、静态 IB 与依赖；WI-001 |
| E-002 | [启动 ObjC 元数据](../../capwords-analysis/evidence/ipa/startup/objc-classes.json)；配套 [Swift 字段](../../capwords-analysis/evidence/ipa/startup/swift-types.json) | 主链接 `d76de8a71d0b5e0711ee91cec0ab6c77aa6c94584e3ed8773e1eb4a68fee8538` | Scene/MainPage IMP、pages/currentIndex/tabbar；WI-002、003 |
| E-003 | [12 段新鲜 LLVM 校验清单](../../capwords-analysis/evidence/ipa/startup/verification.json) | `b7e2d5271935f3f9e81ae3451674b77a9bc54a988a80c4a33214456bd4c971d4` | 窗口、默认页、动画、key 映射、复习及订阅分支；WI-002、003、004 |
| E-004 | [首页发现与精确地址](../../capwords-analysis/evidence/ipa/home-defaults/findings.json)；配套 [指令摘录](../../capwords-analysis/evidence/ipa/home-defaults/key-excerpts.txt) | 主链接 `59ae899df88a68585ae35ac4ae9aa3606fb59e1fbd93f987dd4eff034e440b7c` | 默认日期、Core Data、空卡、问候、首次导航；WI-004、005 |
| E-005 | [视频观察与帧引用](video-1-evidence/STARTUP-OBSERVATIONS.md) | `a0ba3b07efe7092d00890c4135b28af0de971196c1a32e41cfd9023ba8ef12e9` | 2.433 秒词库、25 秒首页、连续返回；WI-006 |
| E-006 | [订阅门控指令](../../capwords-analysis/evidence/ipa/startup/code-100a345e8-100a44274-100a44c04-100a442a8.txt)；配套 [类型元数据](../../capwords-analysis/evidence/ipa/startup/paywall-swift-types.json) | 主链接 `4affac13b287941998f27d4bfed31d44868ffb0fced84a500abe1180ddc0b65b` | purchaseHasActived → PurchaseBViewController；WI-004 |

E-001 中本轮关键 REA Evidence ID：

- plist：`ev_ab2ab1214ac8d352333b1f94fab556240144b9943a31418af81d76d44c3b0944`。
- IB 完整解析：`ev_39c64991937257d9b404c50507a3b58a89d971c64b2865680c1c2389df2f34dd`。
- IB 摘要/节点页：`ev_23b8135ae99eb14dc71aeff5d371c6417f112e5094e2cd1bfb851b4d7f81c8a6`、`ev_bc1f9d6720445ae1b97c9f2574d2c868e82b8615f1f591fd7c4d3845e5ff8f34`。

### 7.2 Findings

severity 均为 `n/a_re`，category 为 `reverse_algo`，remediation 为 n/a（纯研究）。静态控制流已落实到指令，但因缺少原版状态矩阵动态验证，保留 `candidate`，不把静态可达性包装成实际执行；confidence 指本样本静态解释的置信度。

| F-id | 结论 | evidence_ids | location | status / confidence |
| --- | --- | --- | --- | --- |
| F-001 | 主页面先建，独立开屏窗口覆盖并释放 | E-001、E-002、E-003 | `0x10001c6e4`、`0x10001b194` | candidate / high |
| F-002 | 默认拍摄 tab、日期布局不等于首张可见页面 | E-002、E-003、E-004、E-005 | `0x1001a9d60`、`0x100a2ac40` | candidate / high |
| F-003 | 首轮有词库、Onboarding C、每日复习和订阅条件路径 | E-003、E-004、E-006 | `0x100a2eab4`、`0x100a345e8` | candidate / high |
| F-004 | 默认数据来自本地快照；零词有真实空容器和文案 | E-004 | `0x100a2aad4`、`0x100a2b468` | candidate / high |
| F-005 | 问候按小时生成；Header 计数有首日期项检查 | E-004、E-005 | `0x100060ba4`、`0x100a36c28` | candidate / high |

这些结论的影响是复刻应使用真实状态分支，不能固定“开屏 → 四 tab 首页”、固定 17 词或固定“下午好”。复现步骤为下一节对应命令及本节 location 对照；缺少动态复测是共同 residual risk，不改变已记录的指令事实。

### 7.3 P-001：普通已引导用户的调用路径

- path_type: callflow
- start: Scene 连接。
- goal: 解释普通已引导用户从开屏进入展开词库以及条件订阅页。
- steps:
  1. Scene 创建 MainPage，选择 homeNav — evidence: E-002、E-003 — finding: F-001、F-002。
  2. Home 获取本地快照，以日期方式构建首页 — evidence: E-004 — finding: F-004。
  3. 首轮布局且复习例外不成立，打开首日期入口的词库 — evidence: E-003、E-004 — finding: F-003。
  4. 开屏覆盖层完成并释放，执行 finishHandlers — evidence: E-003 — finding: F-001。
  5. 读取购买激活标志，决定是否展示 PurchaseB — evidence: E-003、E-006 — finding: F-003。
- residual_risks: 这是已恢复的静态路径。视频只佐证列表露出/返回关系，不能确定视频用户究竟命中了哪个复习或订阅条件。

## 8. 如何复查

工具：已连接 REA（内置资源解析，无可用的 IDA/Hopper/Ghidra 深度引擎）、Python 离线解析、Apple LLVM 17.0.0、AVFoundation 抽帧。源码映射仅为恢复结果，ARM64 地址是文件虚拟地址，不含运行时 ASLR slide。

在工作区根目录执行以下命令。这些命令不会执行 IPA，也不会修改 App 源码；解析脚本只重建本轮证据文件。

```sh
# E-001：检查保存的 REA 记录及样本身份。
shasum -a 256 cap.ipa capwords-analysis/evidence/ipa/SnapWords 1.mp4
jq '.records[] | {evidence_id, operation, limitations}' capwords-analysis/evidence/ipa/startup/rea-evidence.json

# E-002、E-003：重建默认范围元数据与12段新鲜反汇编。
python3 capwords-analysis/analyze_startup.py
python3 capwords-analysis/analyze_startup.py --verify

# E-003、E-006：核对key跳表及订阅类型/分支。
python3 capwords-analysis/analyze_startup.py --preference-tags 4 9 10 12 0x17 0x1a 0x20
python3 capwords-analysis/analyze_startup.py --pattern 'Purchase|Paywall|Subscription' --metadata-prefix paywall-
python3 capwords-analysis/analyze_startup.py --functions 100a345e8 100a44274 100a44c04 100a442a8

# E-004：定位首页发现对应指令，避免把字符串存在误当成执行。
python3 capwords-analysis/analyze_home_defaults.py localization
python3 capwords-analysis/analyze_home_defaults.py excerpts
jq '.findings[] | {id, claim, evidence, qualification}' capwords-analysis/evidence/ipa/home-defaults/findings.json
sed -n '1,180p' capwords-analysis/evidence/ipa/home-defaults/key-excerpts.txt

# E-005：补抽开屏短区间，实际时间见生成的metadata.json。
swift -suppress-warnings -module-cache-path /tmp/capwords-video-module-cache CapWordsSwift/scripts/extract_video_evidence.swift 1.mp4 CapWordsSwift/docs/video-1-evidence/launch-navigation 0.05 1.8 2.8

# 校验保存的证据哈希、源码语法及报告链接。
python3 capwords-analysis/verify_startup_evidence.py
```

`analyze_startup.py` 校验主程序 SHA-256；默认 metadata 操作只输出本次相关类型，不是全量类型覆盖。`--verify` 清单保留每条 LLVM 命令和输出哈希。`SCALAR` 注释是机器数值候选，只有与实际浮点参数调用绑定的值才能解释为动画参数。

## 9. 覆盖情况与后续验证

| 工作项 | 状态 | 剩余边界 |
| --- | --- | --- |
| WI-001 启动画面与应用层边界 | 已答 | IB 私有字段/完整像素布局未恢复 |
| WI-002 根页面与默认 tab | 已答 | 特殊 URL、恢复及后续弹层不能由默认页一概替代 |
| WI-003 开屏参数与回调 | 已答 | 没有原版真机的精确函数起点/耗时测量 |
| WI-004 首轮导航条件 | 部分已答 | 核心分支已恢复；Onboarding C 后续全过程及所有提示弹层未穷尽 |
| WI-005 默认数据和空状态 | 已答（限定初始化路径） | 未排除其他迁移/导入写入，历史数据跨月/时区及最终计数组合需实测 |
| WI-006 视频页面关系 | 已答 | 视频未记录安装、清数据、会员/复习标志，不等于清洁冷启动实验 |

下一轮若转为实现，应先建立四组可复现数据：全新零词用户、已引导且跳过复习的有词用户、符合每日复习条件的用户、今天为空但历史有词的用户，再分别验证页面覆盖、订阅状态和首页计数。保留用户已确认的系统原生 Liquid Glass 底栏要求；本报告不引入新的自绘 tabbar，也不处理上轮 iOS 27 白屏问题。
