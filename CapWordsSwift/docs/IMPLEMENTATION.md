# 基础版研究对应表

更新日期：2026-10-18。本轮依据 `1.mp4` 和已保存的 REA 证据修改现有 Swift iOS 工程，没有运行原版 CapWords。研究依据见 [启动与首页报告](2026-10-18_逆向-CapWords-启动与首页-report.md) 和 [Tabbar 与粒子报告](2026-10-18_逆向-CapWords-Tabbar与粒子-report.md)；本地实现的实际验证另见 [启动验收记录](startup-implementation-evidence/README.md)，不把本地运行结果当作原版动态证据。

2026-10-19 启动衔接已补充修复，以下启动流程以 [复核报告](2026-10-19_逆向-CapWords-启动衔接复核-report.md) 和 [最新验收](startup-yellow-evidence/README.md) 为准。

## 研究到实现

| 研究证据 | 设计结论 | 实现路径 |
| --- | --- | --- |
| 启动报告 E-001～E-003、F-001 | 主窗口先创建，再覆盖独立启动窗口；内容就绪后播放并释放覆盖层 | `Views/LaunchView.swift`、`Views/HomeView.swift`、`Info.plist` |
| 启动报告 E-003、E-004、F-003 | 首轮只触发一次引导／词库／每日复习分支；复习等待开屏退场 | `Models/StartupPolicy.swift`、`Views/HomeView.swift` |
| 启动报告 E-004、F-004～F-005 | 默认日期、今天空卡、本地小时问候、首日期非空时显示总词数 | `Models/StartupPolicy.swift`、`Views/HomeView.swift`、`Views/LibraryView.swift` |
| [视频 23 秒](../../capwords-analysis/evidence/video/m2/t0023000.jpg) | 浅色点阵、日期分组、双列照片贴纸、粗圆体白底词签 | `Views/DesignSystem.swift`、`Views/LibraryView.swift` |
| [新视频观察](video-1-evidence/OBSERVATIONS.md) | 四项原生玻璃 tabbar；日期／分类菜单；词卡列表单快门；全屏相机无纸面托盘 | `Views/HomeView.swift`、`Views/LibraryView.swift`、`Views/CaptureView.swift` |
| [视频 6 秒](../../capwords-analysis/evidence/video/m2/detail-donut/t0006000.jpg) | 主体、词签、译名、发音、黄光与三圆按钮 | `Views/CaptureView.swift` 的 composition / resultControls |
| [CAPTURE-FLOW.md](../../capwords-analysis/CAPTURE-FLOW.md) | 前景提取与语义识别分开，存在取消、重试和场景回退 | `Services/RecognitionService.swift`、`CaptureFlow` |
| [VIDEO-VALIDATION.md](../../capwords-analysis/VIDEO-VALIDATION.md) | 背景消散、主体独立缩放、结果出现、保存归位 | `Views/PhotoDustView.swift`、`CaptureFlow.Phase` |
| [FEATURES.md](../../capwords-analysis/FEATURES.md) F016–F023 | 双语词、读音、例句、发音、改词 | `Models/Word.swift`、`Services/SpeechService.swift`、`Views/WordEditor.swift` |
| 同上 F030–F037 | 词库分组、详情、删除、复制与保存图片 | `Views/LibraryView.swift`、`Views/WordDetailView.swift`、`Services/StickerExport.swift` |
| 同上 F040–F043 | 待复习队列、翻面、复习阶段和下次日期 | `Models/Word.swift` 的 ReviewSchedule、`Views/ReviewView.swift` |

## 当前流程与边界

启动不等待网络。`HomeView` 单次读取词库并计算路由，`LaunchCoordinator` 在同一 scene 创建不抢 key 的透明覆盖窗口。底层页就绪后播放 logo／标题／条带动画，进度达到 0.76 或兜底调度触发即释放窗口；减少动态效果时使用短淡出。静态 LaunchScreen 与应用动画是两个不同阶段。

两个阶段视觉上使用同一条带首帧：系统 storyboard 直接引用 `launch-bands.png`，动画和 `LaunchFirstFrame` 使用 `LaunchArtwork.bands`。主窗口从第一帧就有遮罩，`didMoveToWindow` 同步挂载独立窗口，遮罩直到 `beginContentReveal()` 才撤掉。不能用 `.task/onAppear` 当作独立窗口已提交到屏幕的保证。正常词库和原生 `TabView` 不改动。

新用户的本地简化引导覆盖词库，完成后持久化引导标志。已引导用户通常直接展开多日词库；满足本地到期词、当日尚未展示复习且提醒开启的条件时，改在开屏后显示每日复习。复习真正显示时记录日期；会话固定词条数组，避免评分改变到期时间后过滤结果缩短、跳过下一词。用于判定到期的时间取快照读取完成时，不使用 View 初始化时的旧时间。

首页默认拍摄标签和日期模式。正常启动不植入视频中的 17 词或开发示例；今天无词仍保留今天的空分组（包括历史有词时）。问候按本地自然小时变化；首日期为空时显示鼓励文案。分类保留视频已见的六类，包括零词类，额外已有分类继续展示；点击首页快照只定位对应组，不永久过滤词库。

相册或真机拍摄输入交给识别 actor；先规范方向和分辨率，再并行请求 DeepSeek 图片词条与本地前景蒙版。分割成功后按 alpha 包围盒裁出主体；系统未返回主体或分割出错时保留整图并在结果中提示完整场景。结果页允许重新裁剪或主动识别整图。

背景消散后停在主体确认页，用户点击橙色勾才展开白页、缩小主体并显示点阵。图片识别和动画独立推进：图片规范化即发请求，抠图先展示，确认后白页展开；结果门控等待用户确认、展开完成和词条就绪。慢请求持续悬浮，结果以黄光、文字按钮分阶段出现。见 [视频 4 研究与验证](2026-10-19_逆向-CapWords拍照识别流程-report.md)。取消／重拍会取消旧任务，减少动态效果设置会跳过粒子和悬浮。

命名由 DeepSeek 官方 `deepseek-flash` 生成，返回目标语言词条、中文释义、读音、例句和译文。不确定时要求手工填写；未配置、网络失败或响应无效时明确报错，可重试原图。现有模拟演示仍使用固定词典。配置与验证边界见 [AI 接入说明](AI-RECOGNITION.md)。手动改词会清除旧例句，避免语义不一致。

保存成功才播放归位过渡；写入失败回滚，不显示成功。删除和复习同样显式保存并处理错误。识别任务有取消和代次标识，避免旧结果写回新页面。后台停止相机，关闭页面停止相机和朗读。

## 与研究界面仍有差异

- Onboarding C 后续完整页面尚未恢复，当前是带语言选择的本地可用引导。原版订阅门控已研究，但当前没有真实商品服务，未构造购买弹窗。旧版 `hasLaunched`／已有词库向新引导状态的兼容属于本地迁移策略。
- 开屏 C 图案、斜带路径和底部装饰是独立重建，采用已恢复的动画参数，不宣称原版资源或逐像素复刻，也不把复刻应用标为原版获奖产品。
- 每日复习选词沿用本地 `nextReviewAt`，不是恢复了原版完整选词／去重算法。首页空日组合、原版引导与订阅状态矩阵尚缺原版真机动态验证。
- Metal 使用最长边 720 的背景 RGBA 纹理，按主体 alpha 排除前景，实例化绘制小片；Canvas 是降级路径。运动重建为左到右释放、独立随机速度／寿命、寿命末尾淡出，随机序列及积分器不是原版逐指令复制。点阵与黄色柔光按新视频重建，未保留旧实现的椭圆波纹。
- 保存过渡已改为跨页面读取实际 artwork 的全局 frame；保存后清除搜索并切回日期模式，滚动至新词，再启动飞行。目标布局超时则直接返回列表。尚待真机逐帧核验。
- 原版悬浮完整曲线、最终白边参数和全部动效耗时没有研究定论；当前弹簧与呼吸周期是实现值，不能理解为识别耗时。
- 研究样本的视频界面与 IPA 2.0.9 功能未必同版。仅已有可见页可以直接视觉对照，其他基础页面采用一致的设计语言。
- 系统分类加 18 词词典不能替代原版在线语义模型；当前不宣称支持任意物体、多对象消歧或自动生成例句。
- 最低版本 iOS 18；Vision 分割与图像分类需要设备／运行环境提供系统模型。模拟器示例路径有固定素材，不能证明真机模型质量。

## 资源来源

`scripts/prepare_reference_assets.py` 保存了每个贴纸的来源帧与裁剪框，可重现 9 张示例贴纸和示例取景。浅色背景用边界泛洪去除，保留物体内部白色。图标使用独立几何绘制。正式发布前应替换为自己的拍摄素材与产品名称。
