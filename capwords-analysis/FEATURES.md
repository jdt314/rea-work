# CapWords 全量静态功能清单

目标：用户提供的 cap.ipa；Info.plist 标注 **2.0.9（445）**；调查日期 2026-10-16。

这是对该样本可见的产品功能、系统扩展及内部能力的完整静态盘点，不是对官方线上全部功能的保证。主程序和扩展未在 iPhone 上运行；远端配置、付费权益、地区、系统版本及入口开关可能改变可见性。样本有重打包／注入痕迹，不能替代官方未修改包。

## 证据等级

- **A：静态交叉证据**。功能文案与应用类型、数据模型、代码／接口或扩展元数据互相支持。未验证实际运行成功；并非每条都已完整恢复调用链。
- **B：能力线索**。可定位相关代码、资源或模型，但默认入口、展示方式或启用条件仍有较大缺口。
- **D：内部／调试**。单独列出，不计为普通用户默认功能。

表中编号对应 [FEATURE-CATALOG.json](FEATURE-CATALOG.json)，其中保存每项的文案 key、原始字符串文件偏移、类型或模型字段。字符串偏移均相对于其所属程序文件；不是运行时地址。没有将第三方 SDK 的通用方法直接当作产品功能。

## REA 与验证范围

复用已完成的 REA IPA inventory 和 Apple application graph，不重复分析相同包。新增 REA `inspect-keyed-archive` 解析 Core Data 编译模型，Evidence：`ev_017ac1ebb5459f8f3354000f1af484cbeffc63cc73092d1e369f184546401b66`。保留完整对象图、引用及限制：归档类没有被实例化，字段存在不等于运行中已写入数据。

- IPA inventory：`ev_3c72b145d1531797eaf063971824a6cf8a350af28ba237bcf11b1aa4e5412617`。
- Apple graph：`ev_59cc2de39511f724dd0cb5e9fea7dc250801973d04fcb2c069375fe0ee499bde`。
- [REA 模型对象图](evidence/ipa/features/rea-coredata-archive.json)、[模型简表](evidence/ipa/features/coredata-model-summary.json)。
- 其余证据由 Python plist／JSON 解码及现有 LLVM 静态结果提供，不冒充 REA 伪代码。
- 已检查主应用与组件简中文案、其他本地化目录清单、主程序类型与 UTF-8 字符串、两个扩展的程序字符串、App Intents 元数据、主程序权限、Core Data 模型、声音资源与 StoreKit 测试配置。
- Windows 环境缺少适用的原生反编译引擎；Assets.car 无可用 assetutil，图集未解码。主要 SwiftUI 页面无可直接恢复完整导航关系的 storyboard。未执行 App、未抓包、未请求应用后端。

## 功能总表

共记录 **153 项**：A 133 项、B 9 项、D 11 项，分布于 15 个模块。

### 采集与识别

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F001 | 拍照识别实物 | 把相机中的物体转成双语单词贴纸 | A | `StickerCameraViewController` @ 0x18577d0；`Snap photo`（主应用文案） |
| F002 | 相册选图识别 | 从已授权照片中选图，确认后提交 AI 识别 | A | `ChatPhotoLibraryPickerViewController` @ 0x1956ec0；`Choose from Photos`（主应用文案） |
| F003 | 按日期回看照片 | 按某一天选择生活照片，作为词卡和对话素材 | A | `Select Date`（主应用文案）；`ChatPhotoDaySuggestion` @ 0x187f4a0 |
| F004 | 自动建议照片 | 自动为所选日期寻找照片，也允许用户自己挑选 | A | `Let %@ auto-find them, or pick yourself.` @ 0x1956b00；`ChatPhotoSuggestionDataSource` @ 0x187f460 |
| F005 | 批量生成贴纸 | 一次最多选择 9 张照片，逐张显示生成状态 | A | `Pick up to 9 photos from this day.` @ 0x1956a90；`ChatBatchStickerGenerationViewModel` @ 0x185ff80 |
| F006 | 裁剪、缩放和移动取景 | 调整要识别的主体范围；不是自由手绘蒙版编辑 | A | `StickerCameraCropToolView` @ 0x1954c80；`Zoom or move the image` @ 0x1954c40 |
| F007 | 相机对焦与变焦 | 包内相机类包含点击对焦、双指缩放及双击切换相机手势成员 | A | `focusTapGestureRecognizer` @ 0x17db8e0；`pinchZoomGestureRecognizer` @ 0x17dbc70；`switchCameraDoubleTapGestureRecognizer` @ 0x17dbed0 |
| F008 | Live Photo 识别 | 有实况照片开关、视频资源提取和动态贴纸存储 | A | `Live Photo is On` @ 0x19554a0；`LivePhotoRecognitionResources` @ 0x1857840；`isVideoGif` @ 0x180b5f9 |
| F009 | 短视频识别 | 长按采集视频，识别动作等内容；有至少 2 秒录制提示 | A | `Long press to recognize video` @ 0x1955610；`A bit short, record at least 2s` @ 0x1954bb0；`VideoVisionPromptView` @ 0x188dc90 |
| F010 | 本地前景抠图 | 使用 Vision 前景实例分割提取物体，已有指令及 selector 证据 | A | `visionSubjectExtraction` @ 0x1956210；`VisionManager` @ 0x185fac0 |
| F011 | 轮廓检测与贴纸外观 | 独立检测边缘并绘制轮廓，带提取和绘制阶段 | A | `visionEdgeExtraction` @ 0x1956230；`StickerCutoutOutlineView` @ 0x1955cc0 |
| F012 | 整图场景识别 | 用户可选择识别完整场景，而非只提取物体 | A | `Tap to recognize the full image` @ 0x1955040；`StickerSceneAlertView` @ 0x185b030 |
| F013 | 抠图失败后场景回退 | 有保存为场景的询问及降级路径 | A | `Want to save it as a scene?` @ 0x1955520；`sticker.scene_fallback_started` @ 0x1955fe0 |
| F014 | 识别重试及重新裁剪 | 单项失败可重试或重新裁剪后继续批量流程 | A | `Recrop or retry` @ 0x19567e0；`ChatBatchStickerEditState` @ 0x185fe40 |
| F015 | 确认或放弃识别结果 | 预览后保存；批量结果可确认并进入聊天 | A | `Tap ✓ to save your first word` @ 0x19553c0；`Confirm & Start Chatting` @ 0x1956820 |

### 词条与语言学习

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F016 | 双语名称和释义 | 同一语义输出母语与目标语言的词条、描述 | A | `StickerInfo` @ 0x19391a0；`semanticIdentity` @ 0x19248a0 |
| F017 | 音标与发音标注 | 支持 IPA、拼音、粤拼及其他语言学习标注 | A | `Pronunciation Annotations` @ 0x194bd70；`LearningAidNotation` @ 0x193d5b0 |
| F018 | 日语假名与罗马字 | 可选择假名或罗马字读音展示 | A | `JapaneseReadingStyle` @ 0x183fd60；`Show Kana readings above Japanese words.` @ 0x194bc60 |
| F019 | 学习辅助显示策略 | 自动、开启或关闭，并根据语言和等级显示辅助 | A | `LearningAidSettings` @ 0x183f9a0；`Auto follows your level and target language.` @ 0x194bde0 |
| F020 | 词条和例句辅助范围 | 可以控制辅助标注出现的位置；朗读使用原文而非辅助注音 | A | `Show On`（主应用文案）；`Speech always uses the clean original text` @ 0x194be90 |
| F021 | 情境例句 | 生成母语和目标语言语义对应的三组生活例句 | A | `ExampleSentenceRequestContext` @ 0x1838e50；`View  examples`（主应用文案） |
| F022 | 单词与例句朗读 | 支持点击播放词条、例句或消息文本；具体页面策略不同 | A | `Select Spoken Content` @ 0x19a23a0；`Speak word`（主应用文案）；`TTSManager` @ 0x1841c32 |
| F023 | 识别结果纠正 | 手动输入正确对象名称和编辑词条 | A | `StickerWrongWordAlertView` @ 0x185bc20；`Enter target object name` @ 0x1955330；`StickerEditViewController` @ 0x199b130 |
| F024 | 点击单词查词 | 在关联文本中点击词语弹出词典卡片 | A | `TapWordDictionaryCardView` @ 0x183e080；`LinkedWordTapTarget` @ 0x183c9c0 |
| F025 | 词典词条详情 | 查询释义、读音、词性和例句，支持朗读 | A | `TapWordDictionaryEntry` @ 0x1834be0；`partOfSpeech` @ 0x1927fa0；`TapWordDictionarySpeechClient` @ 0x194b6c0 |
| F026 | 查词结果加入词汇本 | 保存查询词或加入今天词汇，检查已保存状态 | A | `Saved to Vocabulary!` @ 0x194b950；`Already in your words`（主应用文案）；`VocabularySaveService` @ 0x183e9a0 |
| F027 | 物体、场景和动作词条 | 语义提示词区分 object、scene、action，视频可识别动作 | A | `entryKind` @ 0x192db80；`imageMode=action` @ 0x19377e0 |
| F028 | 语义消歧和词条规范化 | 容器与内容物、品牌、冠词、性数及地区变体规则 | A | `semanticIdentity` @ 0x19248a0；`LearningEntryGrammarAudit` @ 0x1839200；`LearningWordValidation` @ 0x1839eb0 |
| F029 | 本地发音校验与条件 AI 复核 | 词典审计、确定性修复及需要时第二轮复核 | A | `PhoneticValidation` @ 0x183ab40；`RecognitionAuditedAuditSignals` @ 0x1838a30；`wordPhoneticPatch` @ 0x1935cd0 |

### 词库与贴纸管理

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F030 | 个人词库 | 保存拍摄词、场景、动态贴纸及查词加入的词条 | A | `StickerCollectionViewController` @ 0x199ac30；`Your personal word library` @ 0x1951e40 |
| F031 | 日期分组浏览 | 按拍摄日期展示已保存词条 | A | `View by date`（主应用文案）；`StickerLibraryDailySnapshot` @ 0x1830bd0 |
| F032 | 分类分组浏览 | 按语义类别查看词条 | A | `View by category` @ 0x1999f80；`StickerLibraryCategorySnapshot` @ 0x1830bb0 |
| F033 | 自动分类整理 | 生成分类并对已有词库进行分类迁移整理 | A | `Tap to organize your stickers` @ 0x1999ec0；`CategoryMigrationManager` @ 0x1839190 |
| F034 | 词条详情与切换 | 查看大图、小图、例句并切换相邻贴纸 | A | `StickerDetailViewController` @ 0x199b0d0；`StickerDetailSwipeInteractionController` @ 0x199af20 |
| F035 | 删除词条 | 有单项删除与不可恢复确认文案 | A | `Do you want to delete this sticker?` @ 0x194af30；`Once deleted` @ 0x194ad50 |
| F036 | 复制贴纸 | 把贴纸复制到系统剪贴板供其他应用粘贴 | A | `Copied! Paste it anywhere` @ 0x194b970；`StickerExportManager` @ 0x189ec00 |
| F037 | 下载与保存贴纸 | 下载或导出图片到系统相册 | A | `Download sticker` @ 0x199b010；`Sticker saved to Photos!` @ 0x199ad90；`StickerExportManager` @ 0x189ec00 |
| F038 | 动态贴纸导出 | 存在 GIF 帧源和动态媒体导出相关路径；具体导出格式选择未验证 | B | `StickerGIFFrameSource` @ 0x189ef80；`gifData` @ 0x17e53f1；`StickerExportManager` @ 0x189ec00 |
| F039 | 贴纸和场景媒体预览 | 静态物体、场景图、视频或 GIF 使用不同展示组件 | A | `StickerVideoView` @ 0x185ad20；`StickerSceneImageUIView` @ 0x199a740；`CustomVideoPlayer` @ 0x185af10 |

### 闪卡复习

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F040 | 每日待复习队列 | 按 nextReviewDate 等字段筛选待复习内容 | A | `nextReviewDate` @ 0x1923760；`You have %d words to review today` @ 0x199bdf0 |
| F041 | 记忆曲线复习安排 | 记录复习阶段、次数和下次日期；未确认是 SM-2 或 FSRS | A | `reviewStage` @ 0x181a2ae；`reviewCount` @ 0x181a282；`using the memory curve` @ 0x199be20 |
| F042 | 翻面查看答案 | 有闪卡正反面和翻转交互 | A | `FlashCardFrontView` @ 0x1887350；`FlashCardBackView` @ 0x18871f0；`FlashCardStackView` @ 0x1888310 |
| F043 | 左右滑动掌握判断 | 右滑掌握、左滑未掌握，更新学习状态 | A | `Swipe to master`（主应用文案）；`Swipe to review`（主应用文案）；`isMastered` @ 0x1923760 |
| F044 | 复习文字显示模式 | 双语、仅目标语言或隐藏文字 | A | `Show both languages` @ 0x199b6f0；`Show learning language` @ 0x199b710；`Hide all text`（主应用文案） |
| F045 | 闪卡标准发音播放 | 先听词条发音再进行练习 | A | `FlashCardSpeech` @ 0x1887370；`Tap to play pronunciation` @ 0x199b440 |
| F046 | 按住跟读验证 | 麦克风和语音识别核对朗读内容，失败可重试 | A | `Hold & Speak to conquer` @ 0x199b9b0；`FlashCardSpeechError` @ 0x1887370；`Please read the word` @ 0x199ba10 |
| F047 | 跟读相似度反馈 | 存在相似度得分和正确等级线索；不是已验证的专业音素评分 | B | `相似度得分` @ 0x199bf90；`FlashCardCorrectLevel` @ 0x1888f30 |
| F048 | 每日复习数量设置 | 调整每天复习目标数量 | A | `Set Daily New Words Count` @ 0x199c230；`flashcardCount` @ 0x1801030 |
| F049 | 重复复习与剩余数量 | 显示剩余待复习量，允许再次复习 | A | `Review Again`（主应用文案）；`You have %d words left to review` @ 0x199bd60 |
| F050 | 复习结果与正确率 | 统计掌握、遗忘及复习数量；有准确率展示文案 | A | `DailyRecorder` @ 0x1925390；`masteredCount` @ 0x180e7a5；`forgottenCount` @ 0x18013e3 |
| F051 | 复习日历与连续天数 | 按日查看复习活动与连续记录 | A | `CalendarGridView` @ 0x199c030；`FlashCardStatiticsView` @ 0x188b2c0；`Your %d-day streak` @ 0x199c0c0 |
| F052 | 连续答对奖励反馈 | 5、10、20 连续正确的视觉和触觉反馈 | A | `Rhythm Master!` @ 0x199bc10；`Unstoppable Flow!` @ 0x199bbe0；`LEGENDARY STREAK!` @ 0x199bbb0 |

### AI 语伴与对话

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F053 | 按今天的生活开聊 | 使用当天贴纸作为话题和词汇目标 | A | `Speak about today`（主应用文案）；`DailyModeStrategy` @ 0x1866470；`ChatDailyStickerSnapshot` @ 0x186ff10 |
| F054 | 回看某天再开聊 | 日期选择与历史日期素材可用于当天故事式练习 | A | `Back to Today`（主应用文案）；`CalendarDateButton` @ 0x187ff30；`diaryDateString` @ 0x1988200 |
| F055 | 按词汇分类开聊 | 按指定分类建立练习目标及分类进度 | A | `CategoryModeStrategy` @ 0x1866490；`ChatCategoryStickerSnapshot` @ 0x1870290；`categoryChatProgress` @ 0x1924d50 |
| F056 | 示例聊天体验 | 新用户可先用样例体验对话 | A | `Start a sample chat` @ 0x19914d0；`ChatDemoData` @ 0x1872dfa；`TryDemoViewController` @ 0x18467f0 |
| F057 | 实时语音输入 | 麦克风采集、实时 ASR、按住说话和松开发送或取消 | A | `VoiceInputTurnController` @ 0x1992380；`Hold to speak`（主应用文案）；`Release to send`（主应用文案） |
| F058 | AI 生成回复并朗读 | 对话引擎、流式文本与 TTS 回复播放 | A | `VoiceLLMTurnController` @ 0x187cbd0；`VoicePlaybackController` @ 0x187cdb0；`ChatAgentService` @ 0x1869230 |
| F059 | 实时转写文本 | 用户语音和 AI 发言具有转写／字幕展示 | A | `ConversationLiveTranscriptView` @ 0x1877780；`partial_transcript` @ 0x1926060；`final_transcript` @ 0x1926080 |
| F060 | 对话翻译 | 对话文本可翻译，独立控制翻译显示 | A | `ChatTranslationController` @ 0x186d230；`isEnabledChatTranslate` @ 0x1924e30 |
| F061 | 不会说时的提示 | 根据当前对话提供回答提示和鼓励 | A | `HintAgentService` @ 0x1869680；`ConversationHintCardView` @ 0x18776a0；`What to say?`（主应用文案） |
| F062 | 母语输入辅助表达 | 输入母语意图，翻译成目标语言帮助继续对话 | A | `Type in your language`（主应用文案）；`ConversationHintReverseChannelView` @ 0x187b700；`Send hint translation` @ 0x1992210 |
| F063 | 提示自动展开 | 可默认展示完整提示或折叠成小按钮 | A | `Auto-expand hint` @ 0x1991870；`isChatHintAutoExpand` @ 0x1924df0 |
| F064 | 消息朗读和录音回放 | 菜单可读消息或回放自己的录音 | A | `Read message aloud` @ 0x1991d10；`Replay your recording` @ 0x1991d30；`ConversationAudioCache` @ 0x186d3c0 |
| F065 | 撤回已发送消息 | 长按用户消息撤回，并维护对话状态回滚 | A | `Long press to undo a message` @ 0x1991c10；`ChatMessageListUndoPresentationSnapshot` @ 0x1876500 |
| F066 | 练习词覆盖追踪 | 追踪哪些贴纸词已练到，展示剩余与覆盖进度 | A | `ChatStickerCoverageTracker` @ 0x1867fe0；`%d covered`（主应用文案）；`All covered`（主应用文案） |
| F067 | 结束或继续练习 | 练习结束前提示，可继续或结束 | A | `Continue Practicing` @ 0x194abe0；`Your practice is about to end` @ 0x194aca0 |
| F068 | 中断恢复与重试 | 处理网络、后台中断、闲置、回复和播放失败 | A | `ChatRequestRecoveryCoordinator` @ 0x186cca0；`Conversation Interrupted` @ 0x194ae40；`Connection Interrupted` @ 0x194ae60 |
| F069 | 个性化长期记忆 | 提取用户事实并保存引用计数，用于后续对话；未发现独立记忆管理界面 | B | `MemoryExtractionService` @ 0x18697c0；`UserMemoryManager` @ 0x186b030；`UserMemory` @ 0x1830c9a |
| F070 | 生活叙事与对话规划 | 有日记式场景规划与关系导向引擎；不是已确认独立可编辑日记产品 | B | `DiaryGenerationService` @ 0x1869630；`RelationshipDirectorService` @ 0x18699d0；`SessionNarrative` @ 0x1866f30 |

### 语伴与语音设置

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F071 | 选择 AI 伙伴 | 四个角色标识 cappy、capu、capi、capo，带不同性格文案 | A | `BotCharacterID` @ 0x187f31a；`bubble.cappy`（主应用文案）；`bubble.capu`（主应用文案） |
| F072 | 自定义伙伴颜色 | 设置角色颜色并保存 | A | `Pick your buddy's color` @ 0x1958840；`chatCharatorCustomColors` @ 0x1924d70 |
| F073 | 角色动态表情及口型 | 角色动画、眨眼、口型同步和发言动效 | A | `ConversationLipSyncDriver` @ 0x1871940；`LipSyncBlinkController` @ 0x18725b0；`CharacterAvatarSpeechRigView` @ 0x1871390 |
| F074 | 伙伴语音选择与试听 | 选择声音风格并试听，包内有多语言声音配置 | A | `Choose Your Preferred Voice` @ 0x19a25d0；`BackendQwenTTSPreviewPlayer` @ 0x19570e0；`TTSVoiceGroup` @ 0x18424ba |
| F075 | 发音声音设置 | 管理词条朗读声音，包含系统声音和 AI 语音实现 | A | `Pronunciation Voice` @ 0x19a0eb0；`SpeechTTSSheetModel` @ 0x19a2670；`TTSProvider` @ 0x1924fc0 |
| F076 | 高质量系统声音下载引导 | 跳转系统相关设置并指导下载，非应用自行安装系统声音 | A | `View Download Tutorial` @ 0x19a2650；`SpeechQualityTutorialItem` @ 0x18982f0 |
| F077 | 语速设置 | 调整伙伴说话和发音播放速度 | A | `SpeakingPacePageView` @ 0x1864a20；`savedTTSSpeedValue` @ 0x1925080；`Speaking Speed`（主应用文案） |
| F078 | 学习等级设置 | 五级描述，从入门到流利；可降低等级并保留累计 XP | A | `VoiceLevelSelectionPageView` @ 0x1864edf；`Level 5: Fluent`（主应用文案）；`Lower your level?`（主应用文案） |
| F079 | 单次对话难度设置 | 快捷调整对话难度，文案说明不改变学习等级 | A | `Choose chat difficulty` @ 0x19918d0；`Your learning level won’t change` @ 0x19918f0 |
| F080 | 文字大小与快捷设置 | 对话内调整字号、语速、提示等 | A | `QuickSettingsTextSizeSelector` @ 0x1879660；`HomeQuickSettingsSheet` @ 0x1878e80；`Text Size`（主应用文案） |

### 对话历史与成就

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F081 | 聊天历史列表与详情 | 按会话查看过去消息和对话记录 | A | `ChatHistoryView` @ 0x1991160；`ChatHistoryDetailView` @ 0x19910c0；`ChatHistoryManager` @ 0x1872cd0 |
| F082 | 会话统计 | 保存练习时长、轮次、消息数、用到的贴纸数及等级 | A | `ChatSession` @ 0x1867390；`turnCount` @ 0x182844d；`mentionedStickerCount` @ 0x180f310 |
| F083 | XP 与升级 | 完成练习获得经验并展示等级提升 | A | `earnedXP` @ 0x17fec9e；`Level Up!`（主应用文案）；`LevelUpCelebrationContent` @ 0x18741d0 |
| F084 | 口语连续练习记录 | 显示连续天数和每周完成反馈 | A | `My Streak`（主应用文案）；`ChatSessionStatisticsSnapshot` @ 0x1870010；`streakDays` @ 0x1825853 |
| F085 | 本次学到的内容 | 完成流程包含 Today I Learned 汇总及相关数据类型 | A | `Today I Learned`（主应用文案）；`TodayILearnedItem` @ 0x1867370 |
| F086 | 练习成果分享卡 | 生成包含练习表现的分享图并使用系统分享 | A | `ChatHistoryShareCardView` @ 0x18739e0；`Share My Progress` @ 0x1991100；`ShareCardView` @ 0x1999830 |
| F087 | 伙伴分享与合影卡 | 有伙伴介绍、合影及头像分享文案；不是社交好友关系系统 | A | `Taking a photo with` @ 0x19588a0；`Meet my` @ 0x1958c20；`ShareCardFeature` @ 0x1998f50 |
| F088 | 流利度指标 | 会话模型包含 fluencyScore；量表、算法及每次是否展示未确认 | B | `fluencyScore` @ 0x18010b6 |

### 生活上下文

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F089 | 城市和天气个性化 | 请求位置并通过 WeatherKit 获取本地天气用于聊天 | A | `Location & Weather` @ 0x1958480；`weather.fetch_succeeded` @ 0x19a3a20；`voiceChatUserLocation` @ 0x1924f30 |
| F090 | Apple 健康授权 | 独立设置页，可请求选定数据的读取授权 | A | `ProfileAppleHealthView` @ 0x19a11f0；`healthkit.authorization_started` @ 0x19a32a0 |
| F091 | 健康摘要作为话题 | 结合步数、活动能量、运动、睡眠、恢复及 HRV 信息生成简短摘要 | A | `HealthSummary` @ 0x189e0a0；`Heart Rate Variability` @ 0x19a0b60；`Steps & Activity`（主应用文案） |
| F092 | 上下文使用控制与授权说明 | 可选择是否分享健康／位置上下文，界面提供系统授权管理说明 | A | `SpeakContextSetupView` @ 0x1863870；`Share my wellness`（主应用文案）；`Open Health App`（主应用文案） |
| F093 | 照片时间和位置元数据 | 存在提取照片拍摄时间、位置和识别会话绑定实现；实际上传字段未运行验证 | B | `PhotoMetadataExtractor` @ 0x189e190；`RecognitionPhotoMetadata` @ 0x1858580；`has_location_metadata` @ 0x1955ed0 |

### 语言与数据

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F094 | 母语和学习语言选择 | 独立保存 currentLanguage 与 targetLanguage | A | `Choose Your Native Language` @ 0x194e930；`Choose your learning language` @ 0x19a2340；`SupportLanguage` @ 0x1892bfa |
| F095 | 多语言与地区变体 | 包内支持语言类型及资源覆盖 16 个学习语言键，见报告明细 | A | `ChineseCantoneseCodingKeys` @ 0x1892e50；`EnglishBritishCodingKeys` @ 0x1892e90；`BrazilianPortugueseCodingKeys` @ 0x1892fb0 |
| F096 | 切换学习语言与母语 | 保留旧数据并迁移已有词条内容；界面有每周切换限制提示 | A | `ChangeLanguageManager` @ 0x188eca0；`Change your native language` @ 0x199f520；`Note: Can be changed once per week`（主应用文案） |
| F097 | 语言迁移进度与恢复 | 批量翻译、进度、断网重试、后台暂停、恢复和失败回滚 | A | `LanguageChangeBatchRequestPipeline` @ 0x188ec30；`LanguageMigrationCheckpointWriter` @ 0x188ff50；`language_change.rollback_completed` @ 0x199e270 |
| F098 | 语言迁移实时活动 | ActivityKit 展示迁移进度、等待状态及返回应用入口 | A | `LanguageMigrationLiveActivity` @ 0x188e970；`Updated %d of %d items` @ 0x19a1ba0 |
| F099 | 界面语言选择 | 独立于学习语言；有 9 套本地化目录 | A | `Interface Language` @ 0x19a0ed0；`System Language`（主应用文案） |
| F100 | 本地词库与历史持久化 | Core Data 保存贴纸、消息、会话、用户及每日记录 | A | `StickerDatabase` @ 0x183094a；`ChatMessage` @ 0x1924cf0；`DailyRecorder` @ 0x1925390 |
| F101 | iCloud 同步及恢复实现 | CloudKit 镜像、远端变更应用、账户监控与媒体下载 | A | `icloud.remote_changes_applied` @ 0x1923ff0；`icloud.account_monitor_configured` @ 0x19244b0；`Downloading from iCloud` @ 0x199a910 |
| F102 | 音频缓存清理 | 清理已缓存 AI 语音文件，保留功能使用能力 | A | `Clear Audio Cache` @ 0x194af10；`Don’t worry — the feature will still work` @ 0x194ace0 |
| F103 | 图片与 GIF 媒体缓存 | 包含磁盘缓存、加载调度及滚动时资源管理；属于底层能力 | B | `StickerMediaPayloadDiskCache` @ 0x189eea0；`StickerPayloadLoadCoordinator` @ 0x189ee70 |

### 桌面与系统入口

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F104 | 贴纸日历组件 | 按日期显示收集过的单词 | A | `CalendarHomeWidget` @ 0xb93c0；`Sticker calendar` @ 0xdf0e0 |
| F105 | 拍摄组件 | 展示拍摄入口及当天词汇素材 | A | `CaptureHomeWidget` @ 0xb9ae0；`Capture a moment` @ 0x1999120 |
| F106 | 复习卡组件 | 桌面查看待复习单词，可点击扬声器听发音 | A | `ReviewHomeWidget` @ 0xbb350；`Review card`（组件文案） |
| F107 | 词汇集组件 | 桌面展示个人收集的词汇贴纸 | A | `VocabularyHomeWidget` @ 0xbb370；`Word collection`（组件文案） |
| F108 | 连续打卡组件 | 展示连续练习与伙伴提示 | A | `StreakHomeWidget` @ 0xbb3b0；`Daily streak`（组件文案） |
| F109 | 贴纸环绕组件 | 另一种以贴纸环绕为视觉的打卡展示 | A | `StreakRingHomeWidget` @ 0xbb390；`Sticker ring`（组件文案） |
| F110 | 小组件发音交互 | 通过 PlayWidgetWordIntent 播放指定词条发音，无需声明打开主应用 | A | `PlayWidgetWordIntent` @ 0x1891620；`Play pronunciation` @ 0x199f0f0 |
| F111 | 组件尺寸和外观样式 | 不同尺寸及打卡样式配置；逐类尺寸支持矩阵未恢复 | A | `Choose the large widget's appearance`（组件文案）；`Streak style`（组件文案）；`WidgetDesignMetrics` @ 0xba5a0 |
| F112 | 快捷指令打开相机 | App Intent 与自动快捷短语可打开 CapWords 相机 | A | `CameraLauncherShortcutIntent` @ 0x199f3c0；`source=appShortcut` @ 0x199f440 |
| F113 | 控制组件打开相机 | ControlWidget 对应独立相机启动入口 | A | `CameraLauncherControlWidget` @ 0xbd2a0；`source=controlWidget` @ 0x199f4e0 |
| F114 | 锁屏小组件入口 | CameraLauncherScreenWidget 通过 URL 跳转相机 | A | `CameraLauncherScreenWidget` @ 0xbd5f0；`source=lockScreenWidget` @ 0xdf700 |
| F115 | 安全锁屏拍摄扩展 | IPA 声明 securecapture 并链接 LockedCameraCapture；未证明锁定状态下完整拍摄识别流程可用 | B | `SnapWordsCaptureExtension`（IPA文件目录） |
| F116 | 组件安装教程与画中画 | 引导视频可尝试画中画，以便边看边添加桌面组件 | A | `WidgetGuidePlayback` @ 0x189b270；`widget.whatsnew.pipStarting`（主应用文案） |

### 提醒与外观

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F117 | 每日学习提醒 | 设置提醒时间并调度本地通知 | A | `Daily Reminder`（主应用文案）；`SetupReminderView` @ 0x1897050；`daily_reminder_notification` @ 0x19a1fb0 |
| F118 | 复习提醒入口 | 提供复习提醒相关设置／说明；与每日通知如何合并未完全恢复 | A | `Review Reminder`（主应用文案）；`Review_entry_source` @ 0x1840960 |
| F119 | 免费试用到期提醒 | 试用结束前一天通知，需通知权限 | A | `free_trial_end_notification` @ 0x1952d80；`Remind me before the free trial ends` @ 0x19a1cd0 |
| F120 | 迁移暂停通知 | 语言迁移暂停时提示返回应用继续 | A | `language_change.continuation_notification_scheduled` @ 0x199d6a0；`Language migration paused` @ 0x199d610 |
| F121 | 浅色、深色、跟随系统 | 全局外观选择 | A | `Appearance.Dark`（主应用文案）；`Appearance.Light` @ 0x19a30a0；`AppAppearancePreference` @ 0x189d810 |
| F122 | 昵称和头像编辑 | 本地资料可修改，部分分享卡可能展示 | A | `Edit Profile`（主应用文案）；`ProfileInfoAlertView` @ 0x1896660；`avatarData` @ 0x17f4e42 |
| F123 | 触觉、音效与过渡动画 | 闪卡、拍摄和贴纸使用音效、触觉及粒子／消散动画 | A | `SoundEffectManager` @ 0x194dbd0；`StickerDustImageView` @ 0x194e600；`Inflate`（IPA文件目录） |

### 新用户引导

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F124 | 学习目标与困难问卷 | 收集动机、当前水平、开口障碍与坚持难点 | A | `What's your main motivation` @ 0x1950040；`Where do you get stuck` @ 0x194fda0；`OnboardingCModel` @ 0x1846d00 |
| F125 | 昵称及性别信息选择 | 有昵称与性别选择，包括非二元和暂不透露 | A | `What should we call you` @ 0x194ffe0；`Onboarding Gender Prefer not to say` @ 0x194f560 |
| F126 | 语言、语音和等级初始化 | 引导选择母语、目标语、声音及学习等级 | A | `OnboardingCurrentLanguageCell` @ 0x194e950；`OnboardingVoiceListContent` @ 0x184b7a0；`OnboardingLevelBallIntroView` @ 0x1849ef0 |
| F127 | 首次拍照及复习示例 | 提供首个词条、拍摄保存教程和闪卡试用 | A | `OnboardingTutorialCell` @ 0x194f0c0；`FlashCardTryDemoAlertView` @ 0x188b9b0；`Tap ✓ to save your first word` @ 0x19553c0 |
| F128 | 语伴创建与对话引导 | 创建伙伴、选颜色和声音，试聊并设置生活上下文 | A | `ChatOnboardingViewController` @ 0x1956f80；`Let's bring your buddy to life` @ 0x1958860 |
| F129 | 新功能介绍 | 展示分类、对话、Live Photo／视频及小组件介绍 | A | `WhatsNewSheetView` @ 0x1899a20；`WhatsNewForChatSheetView` @ 0x19a2800；`Live Photo & Video Recognition is Here`（主应用文案） |

### 会员与购买

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F130 | 免费体验与额度限制 | 免费采集次数和体验后的升级入口 | A | `Free tries used up` @ 0x1951fa0；`freeStickerCount` @ 0x19254d0 |
| F131 | 高级版功能权益 | 付费页声明无限识图、例句、AI 对话等；具体线上额度和限流未知 | A | `Unlimited AI conversation` @ 0x19510e0；`Unlimited AI word capture` @ 0x1951de0；`PurchaseBenefitItem` @ 0x184f290 |
| F132 | 订阅套餐选择 | 含月、年及周相关文案／配置线索；当前线上在售套餐需 App Store 验证 | A | `Monthly` @ 0x17e3382；`Annual Plan`（主应用文案）；`Weekly %@`（主应用文案） |
| F133 | 终身或一次性购买支持 | 有一次性购买、终身及恢复历史非订阅订单的路径；不证明当前仍售卖 | B | `Lifetime` @ 0x19edfb1；`PurchaseNonSubscriptionSnapshot` @ 0x1856870；`one-time purchase` @ 0x1951a00 |
| F134 | 试用与新用户优惠 | 免费试用、首年优惠、限时优惠与倒计时展示 | A | `PurchaseGiftViewController` @ 0x184c930；`PurchaseSaleViewController` @ 0x1950f50；`saleCountdownDate` @ 0x1925340 |
| F135 | 购买和恢复购买 | 通过应用购买状态处理和恢复历史权益 | A | `InAppPurchase` @ 0x1952510；`Restore Purchase` @ 0x1950c30；`PurchaseRestoreResult` @ 0x1856750 |
| F136 | 管理订阅 | 跳转 Apple 订阅管理页面 | A | `Manage Subscription` @ 0x19a0e70；`https://apps.apple.com/account/subscriptions` @ 0x19a0ba0 |
| F137 | 购买异常解释与支持 | 处理待批准、退款、扣款问题、无权益、账号关联与验证问题 | A | `PurchaseNotice` @ 0x18565d2；`PurchaseErrorDetails` @ 0x1831640；`Your purchase could not be verified` @ 0x1952280 |

### 帮助与支持

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F138 | 邮件联系与功能建议 | 从应用发起邮件反馈，可附诊断或购买详情；本次未发送邮件 | A | `FeedbackEmailCoordinator` @ 0x1856970；`Suggest a Feature` @ 0x19a0e30；`Contact Us` @ 0x1954680 |
| F139 | FAQ、隐私政策及服务条款 | 打开对应中英文网页 | A | `https://capwords.app/faqs` @ 0x19a0bd0；`Privacy Policy`（主应用文案）；`Terms of Service` @ 0x19519a0 |
| F140 | 关于与创作故事 | 查看开发者故事和产品来源 | A | `OurStoryViewController` @ 0x199fd10；`A Story of Exploration` @ 0x199fe00 |
| F141 | 评分邀请 | 特定使用节点邀请评分并跳转 App Store | A | `RatingPromptManager` @ 0x183c830；`Give 5 Stars`（主应用文案） |
| F142 | 语音教程和数据来源说明 | 系统声音下载指南及开源词典、词频数据许可说明 | A | `SpeechQualitySheetView` @ 0x1897b30；`Data Sources`（主应用文案）；`OPEN_LEXICON`（IPA文件目录） |

### 内部与诊断

| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |
| --- | --- | --- | --- | --- |
| F143 | 识别调试面板 | 查看识别阶段、时间及请求审计线索，受 debug 开关约束 | D | `RecognitionDebugSheetView` @ 0x1955e60；`debugRecognitionDebugEnabled` @ 0x1925220 |
| F144 | 识别、翻译与例句提示词编辑 | 打包了相应调试视图，不作为普通用户编辑 Prompt 功能 | D | `VideoVisionPromptView` @ 0x188dc90；`TranslationPromptView` @ 0x188dcc0；`ExamplePromptView` @ 0x188dce0 |
| F145 | AI 服务商、模型及路由选择 | 自动／手动路由、国内海外候选及模型切换，常规可见性未确认 | D | `ChatTabLLMModelMenuButton` @ 0x1999270；`voiceChatAutomaticRoutingEnabled` @ 0x1924f90；`backendBaseURLOverrideEnabled` @ 0x19251a0 |
| F146 | 对话引擎与隐藏规划调试 | 查看 Director／Think 结果和调试导出；不是给普通用户展示模型思维的承诺 | D | `LLMCallDebugSheet` @ 0x187a820；`Show Think LLM debug info` @ 0x1991c30；`Conversation With Hidden Think` @ 0x1991e50 |
| F147 | A/B 引导与付费墙布局 | 多版引导及购买页实验，可强制展示 | D | `debugABTestSandboxMode` @ 0x1925280；`appOnboardingExperimentVariant` @ 0x19255b0；`PurchaseLayout` @ 0x1840ec2 |
| F148 | 会员及优惠调试覆盖 | 存在强制 Pro 和优惠资格覆盖，仅归入调试 | D | `debugForceProMode` @ 0x1925260；`debugSaleEligibilityOverride` @ 0x19251e0 |
| F149 | 语言数据重置调试 | 有 DebugLanguageDataResetResult；不是普通用户注销或清空账户功能 | D | `DebugLanguageDataResetResult` @ 0x188c190；`debug.language_data_reset_fetch_failed` @ 0x199c2f0 |
| F150 | 诊断压缩包与日志脱敏 | 生成诊断档案、保留计数和日志脱敏规则 | D | `CapWords-Diagnostics.zip` @ 0x1926f90；`DiagnosticLogArchive` @ 0x18318d0；`redacted` @ 0x19264f0 |
| F151 | 崩溃、归因和质量遥测 | 包含 Crashlytics、AppsFlyer 及对话质量模块；是否启用及实际上传需运行验证 | D | `ChatQualitySessionRecorder` @ 0x186c530；`ChatQualityOutbox` @ 0x186c570；`Firebase` @ 0x194bff0 |
| F152 | 设备注册与认证恢复 | 后端设备凭据、刷新和失败恢复，不等同于用户注册账号 | D | `BackendDeviceCredentials` @ 0x1834e40；`BackendDeviceAuth` @ 0x1927c00；`device_auth.recovery_started` @ 0x1927e30 |
| F153 | 媒体缓存和任务优先级 | 图像／GIF 缓存、释放和滚动调度，属于性能基础设施 | D | `StickerMediaWorkPriorityController` @ 0x189ed30；`StickerMediaPayloadLifetimeTracker` @ 0x189ef10 |

## 语言、分类与系统扩展明细

学习语言类型及对应词频资源覆盖 16 个键：`zh` 普通话、`yue` 粤语、`en` 英语、`en-GB` 英式英语、`fr` 法语、`es` 西班牙语、`ja` 日语、`ko` 韩语、`de` 德语、`it` 意大利语、`ru` 俄语、`pt` 葡萄牙语、`pt-BR` 巴西葡萄牙语、`vi` 越南语、`th` 泰语、`id` 印尼语。这里是样本内资源与类型覆盖，不保证所有组合及每个服务商声音都可用。更多英语／法语口音文案不能直接算成额外学习语言。

界面本地化目录共 9 个：英语、简体中文、繁体中文、法语、西班牙语、日语、韩语、德语、意大利语。它与学习语言列表是两回事。

分类文案包含 20 类：动物自然、食物饮品、家居家具、衣物配饰、城市建筑、交通出行、学校学习、工作职业、科技媒体、运动锻炼、身体健康、人物家庭、情绪性格、娱乐艺术、文化节日、购物金钱、天气季节、颜色形状、数字时间、其他。它们是可见类别文案，不代表分类模型始终只返回这些值。

扩展覆盖：

- `SnapWordsWidgetExtension`：WidgetKit、6 类桌面组件、相机控制／锁屏启动入口及语言迁移 Live Activity；最低系统声明 iOS 17，具体组件另有可用性条件。
- `SnapWordsCaptureExtension`：`com.apple.securecapture` 扩展点并链接 LockedCameraCapture；最低系统声明 iOS 26。扩展存在不证明可以在完全锁定状态完成全部识别。
- App Intents：`CameraLauncherShortcutIntent`、`CameraLauncherControlIntent`、`PlayWidgetWordIntent`。相机 Intent 的元数据声明 iOS 18 起，且 openAppWhenRun=true；播放词条的 Intent 声明 openAppWhenRun=false。
- 本样本的 URL scheme 是 `snapwords`，已看到相机、设置、锁屏及控制组件来源参数，不是公开 HTTP API。

## 数据对象对应的功能

| 实体 | 支撑能力 | 不能据此推出 |
| --- | --- | --- |
| StickerItem | 图片／原图字段、GIF、场景标记、词条、日期、学习状态、复习阶段及下次日期 | 每次都存原图、每个字段均有值、具体数据保留期限 |
| DailyRecorder | 每日已学词、掌握／遗忘数量和日期 | 标准教育测量量表 |
| ChatSession | 会话、角色、语言、分类、轮次、用词数、经验和流利度字段 | 流利度指标的科学有效性 |
| ChatMessage | 原文、翻译、发送者、关联词条及提及范围 | 所有历史录音永久保存 |
| UserMemory | 事实、置信度、来源会话、引用时间和次数 | 用户可以在正式 UI 编辑或删除单条 AI 记忆 |
| User | 昵称、头像、性别、复习目标、经验起点及连续记录 | 存在邮箱／手机号注册登录产品流程 |
| AudioCheckinRecord | 日期和打卡记录 | 专业语音评测功能 |

## 不能混入正式功能的项目

1. StoreKit 文件是测试配置，周／月／年价格或免费试用天数不能当作当前线上报价。一次性购买支持不等于当前有终身套餐在售。
2. `OnboardingLogin` 类型名及设备认证不证明有邮箱、手机号或 Sign in with Apple 登录；现有证据不足以列出这些功能。
3. `Stories` 文案、开发者家庭故事及日记式对话规划不等于社交动态、公开社区或独立日记编辑器。
4. 未建立在线真人聊天、好友、排行榜、教师后台、课程商城、通用 OCR 扫描翻译、任意图像生成等产品能力。这里的缺口是“现有静态证据未建立”，不是断言它们在所有版本绝不存在。
5. SDK 中出现退款、推荐奖励、Android 商店、广告等通用符号，不自动算 CapWords 的实际界面或支持平台。
6. 样本中的调试强制会员、提示词编辑及路由选择不代表付费绕过功能对普通用户开放；注入 dylib 不归入 CapWords 正式功能。
7. “完全不上传”“无服务器”“所有数据仅本地”等旧文案不能作为技术结论；包内有应用后端、云同步及 AI 图片／语音通信实现。

## 完整性审计与待验证事项

已完成该 IPA 的主要产品域、权限、数据模型、扩展及用户文案的静态盘点。清单不是运行验收：尚需原版包对照及 iPhone 实测才能确认每个入口、地区／订阅限制、默认开关、网络行为和真实结果。

本次没有为每个函数恢复完整调用图，也没有把 UI 文案视为必然可达。只有 schema 字段或代码线索的功能保留 B 等级；内部页单列 D 等级。原有抠图指令证据详见 [IPA-REPORT.md](IPA-REPORT.md)。
