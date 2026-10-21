# 复习语音输入实施方案

日期：2026-10-21。状态：规划，尚未接入录音或识别。当前工程最低 iOS 18；`SpeechService` 仅负责朗读。以下超时、匹配和确认规则是本项目的产品选择，不是对原版行为的断言。

## 目标和依据

让用户在闪卡页读出目标词，看到系统识别的文字，并决定是否按“记住了”推进。第一阶段不提供百分制发音分数，不用文字匹配冒充音素/声学评价。

原 IPA 已找到 `DictationTranscriber`、`shortForm`、`frequentFinalization`、`volatileResults`、音频输入 tap 和 AssetInventory 调用，尚未恢复转写之后的匹配和自动推进条件。详见 [REA 证据](../../capwords-analysis/review-page-20261020/speech-followup/REPORT.md)。

Apple 的 SpeechAnalyzer 为 iOS 26 新语音分析框架，DictationTranscriber 可承接不同设备及语言条件下的听写场景。结合原版证据，计划在 iOS 26+ 优先评估 SpeechAnalyzer + DictationTranscriber 短词路径；iOS 18–25 保留 SFSpeechRecognizer 适配器。运行时查询语言及资源状态，不仅依赖系统版本。[Apple WWDC25](https://developer.apple.com/videos/play/wwdc2025/277/)

## 用户流程

1. 首次点击虚线麦克风，按所选识别后端申请麦克风及其所需的语音识别权限；拒绝时解释原因并提供系统设置入口，仍允许滑动复习。
2. 检查当前单词的 languageCode、支持语言及模型。需要准备模型时显示“正在准备语音”，可取消；准备好以前不显示正在录音。
3. 实际开始采集后，按钮变浅桃色胶囊、白色麦克风，提示“请慢慢读这个单词”。再次点击停止；可以显示简洁音量反馈。
4. 中间转写只用于显示。收到最终结果后停止采集，将转写与目标词比较：匹配则显示“识别到：…”，提供“记住了，下一张”；不匹配则显示“识别到：…”，提供“再读一次”和“听发音”。不匹配不自动记为遗忘。
5. 无输入、超时、系统中断、切后台、退出页面、切卡或点击朗读，都结束当前录音、移除 tap、取消任务并释放音频会话。点击朗读后不偷偷恢复录音。

建议初始上限：等待开口 5 秒、单轮采集 12 秒；作为可调策略，需真机测试后确定。超时不修改复习记录。

## 状态和职责

`idle → requestingPermission → preparing → recording → finalizing → result`；任意阶段可进入 `unavailable` 或 `failed`，取消后回到 idle。

- `ReviewSpeechSession`（主线程可观察模型）：面向视图提供状态、实时文字、最终结果、start/stop/cancel；持有本轮 UUID 和 wordID，忽略上一张卡的迟到回调。
- `SpeechRecognitionBackend`：统一语言能力、资源准备、音频输入和异步转写事件；分别适配 Analyzer 和旧识别器，隔离系统版本差异。
- `ReviewSpeechMatcher`：纯函数，输入目标词、允许的别名、最终转写，输出 matched / unmatched / empty。第一阶段只做大小写、Unicode、外围标点和连续空格归一化后的完整匹配；不采用子串命中，不随意删除词中连字符，不使用未知相似度阈值。
- `ReviewView`：展示状态；只有用户确认匹配结果后才调用现有 `grade(remembered: true)`。继续使用现有队列、调度和日报保存路径。
- 音频协调：`SpeechService` 与录音服务互斥；开始录音前停止 TTS，开始朗读前取消识别。退出时恢复音频会话并通知其他音频恢复。

## 权限与数据

在实际实施时补充 `NSMicrophoneUsageDescription` 和旧识别后端所需的 `NSSpeechRecognitionUsageDescription`。首次使用时申请，启动 app 时不预先弹权限。Apple 提供独立的语音识别授权接口。[Apple 授权文档](https://developer.apple.com/documentation/speech/sfspeechrecognizer/requestauthorization(_:))

模型准备使用 AssetInventory，区分不支持、未安装、下载中和可用；允许用户取消，并处理断网及下载失败。[Apple AssetInventory](https://developer.apple.com/documentation/speech/assetinventory)

优先设备端识别；后端不能满足设备端条件时显示不可用，不静默切换网络识别。若以后支持网络识别，应在启用前说明。音频不落盘、不上传到本项目服务；转写默认仅保留到离开当前卡片，不写进 Word 或 ReviewRecord。

## 实施顺序与验收

1. 建立状态模型与 mock 后端，验证取消、迟到事件、权限拒绝、模型下载失败及重复点击。补齐麦克风按钮的真实状态，不修改复习调度。
2. 接入 iOS 26+ 短词识别和 iOS 18–25 适配器，完成音频互斥及生命周期清理；支持语言以运行时结果为准。
3. 接入完整词匹配、确认推进及重试 UI。单测覆盖空转写、多词短语、标点、连字符、非拉丁文字和相似但不同的词。
4. 真机验证权限首次/拒绝/设置恢复、静音、耳机切换、后台/来电中断、连续切卡、离开后麦克风关闭、朗读不被自身识别、每次确认只记一次。至少覆盖一台 iOS 18–25 和一台 iOS 26+ 设备。

模拟器截图或构建成功不能代替麦克风真机验收。原版自动推进阈值、专业发音评分留作后续研究，不阻塞这一版可确认的语音输入。
