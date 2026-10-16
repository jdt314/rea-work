"""Build a source-linked static feature catalog from the retained IPA evidence."""
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BASE = ROOT / 'evidence' / 'ipa'
F = BASE / 'features'
UI = json.loads((F / 'Payload_SnapWords.app_zh-Hans.lproj_Localizable.strings.json').read_text(encoding='utf-8'))
WUI = json.loads((F / 'Payload_SnapWords.app_PlugIns_SnapWordsWidgetExtension.appex_zh-Hans.lproj_Localizable.strings.json').read_text(encoding='utf-8'))
STRINGS = json.loads((BASE / 'cstrings-utf8.json').read_text(encoding='utf-8'))
ALL_STRINGS = json.loads((BASE / 'strings.json').read_text(encoding='utf-8'))
INVENTORY = json.loads((BASE / 'inventory.json').read_text(encoding='utf-8'))
TYPES = json.loads((F / 'app-types.json').read_text())
WIDGET = json.loads((F / 'SnapWordsWidgetExtension-strings.json').read_text())
MODELS = json.loads((F / 'coredata-model-summary.json').read_text(encoding='utf-8'))

# module | status | function | scope | exact-substring evidence selectors
# A: static corroboration; B: capability evidence with remaining reachability gaps;
# D: internal/debug. Neither A nor B claims a successful runtime test.
DATA = r'''
采集与识别|A|拍照识别实物|把相机中的物体转成双语单词贴纸|StickerCameraViewController;Snap photo
采集与识别|A|相册选图识别|从已授权照片中选图，确认后提交 AI 识别|ChatPhotoLibraryPickerViewController;Choose from Photos
采集与识别|A|按日期回看照片|按某一天选择生活照片，作为词卡和对话素材|Select Date;ChatPhotoDaySuggestion
采集与识别|A|自动建议照片|自动为所选日期寻找照片，也允许用户自己挑选|Let %@ auto-find them, or pick yourself.;ChatPhotoSuggestionDataSource
采集与识别|A|批量生成贴纸|一次最多选择 9 张照片，逐张显示生成状态|Pick up to 9 photos from this day.;ChatBatchStickerGenerationViewModel
采集与识别|A|裁剪、缩放和移动取景|调整要识别的主体范围；不是自由手绘蒙版编辑|StickerCameraCropToolView;Zoom or move the image
采集与识别|A|相机对焦与变焦|包内相机类包含点击对焦、双指缩放及双击切换相机手势成员|focusTapGestureRecognizer;pinchZoomGestureRecognizer;switchCameraDoubleTapGestureRecognizer
采集与识别|A|Live Photo 识别|有实况照片开关、视频资源提取和动态贴纸存储|Live Photo is On;LivePhotoRecognitionResources;isVideoGif
采集与识别|A|短视频识别|长按采集视频，识别动作等内容；有至少 2 秒录制提示|Long press to recognize video;A bit short, record at least 2s;VideoVisionPromptView
采集与识别|A|本地前景抠图|使用 Vision 前景实例分割提取物体，已有指令及 selector 证据|visionSubjectExtraction;VisionManager
采集与识别|A|轮廓检测与贴纸外观|独立检测边缘并绘制轮廓，带提取和绘制阶段|visionEdgeExtraction;StickerCutoutOutlineView
采集与识别|A|整图场景识别|用户可选择识别完整场景，而非只提取物体|Tap to recognize the full image;StickerSceneAlertView
采集与识别|A|抠图失败后场景回退|有保存为场景的询问及降级路径|Want to save it as a scene?;sticker.scene_fallback_started
采集与识别|A|识别重试及重新裁剪|单项失败可重试或重新裁剪后继续批量流程|Recrop or retry;ChatBatchStickerEditState
采集与识别|A|确认或放弃识别结果|预览后保存；批量结果可确认并进入聊天|Tap ✓ to save your first word;Confirm & Start Chatting
词条与语言学习|A|双语名称和释义|同一语义输出母语与目标语言的词条、描述|StickerInfo;semanticIdentity
词条与语言学习|A|音标与发音标注|支持 IPA、拼音、粤拼及其他语言学习标注|Pronunciation Annotations;LearningAidNotation
词条与语言学习|A|日语假名与罗马字|可选择假名或罗马字读音展示|JapaneseReadingStyle;Show Kana readings above Japanese words.
词条与语言学习|A|学习辅助显示策略|自动、开启或关闭，并根据语言和等级显示辅助|LearningAidSettings;Auto follows your level and target language.
词条与语言学习|A|词条和例句辅助范围|可以控制辅助标注出现的位置；朗读使用原文而非辅助注音|Show On;Speech always uses the clean original text
词条与语言学习|A|情境例句|生成母语和目标语言语义对应的三组生活例句|ExampleSentenceRequestContext;View  examples
词条与语言学习|A|单词与例句朗读|支持点击播放词条、例句或消息文本；具体页面策略不同|Select Spoken Content;Speak word;TTSManager
词条与语言学习|A|识别结果纠正|手动输入正确对象名称和编辑词条|StickerWrongWordAlertView;Enter target object name;StickerEditViewController
词条与语言学习|A|点击单词查词|在关联文本中点击词语弹出词典卡片|TapWordDictionaryCardView;LinkedWordTapTarget
词条与语言学习|A|词典词条详情|查询释义、读音、词性和例句，支持朗读|TapWordDictionaryEntry;partOfSpeech;TapWordDictionarySpeechClient
词条与语言学习|A|查词结果加入词汇本|保存查询词或加入今天词汇，检查已保存状态|Saved to Vocabulary!;Already in your words;VocabularySaveService
词条与语言学习|A|物体、场景和动作词条|语义提示词区分 object、scene、action，视频可识别动作|entryKind;imageMode=action
词条与语言学习|A|语义消歧和词条规范化|容器与内容物、品牌、冠词、性数及地区变体规则|semanticIdentity;LearningEntryGrammarAudit;LearningWordValidation
词条与语言学习|A|本地发音校验与条件 AI 复核|词典审计、确定性修复及需要时第二轮复核|PhoneticValidation;RecognitionAuditedAuditSignals;wordPhoneticPatch
词库与贴纸管理|A|个人词库|保存拍摄词、场景、动态贴纸及查词加入的词条|StickerCollectionViewController;Your personal word library
词库与贴纸管理|A|日期分组浏览|按拍摄日期展示已保存词条|View by date;StickerLibraryDailySnapshot
词库与贴纸管理|A|分类分组浏览|按语义类别查看词条|View by category;StickerLibraryCategorySnapshot
词库与贴纸管理|A|自动分类整理|生成分类并对已有词库进行分类迁移整理|Tap to organize your stickers;CategoryMigrationManager
词库与贴纸管理|A|词条详情与切换|查看大图、小图、例句并切换相邻贴纸|StickerDetailViewController;StickerDetailSwipeInteractionController
词库与贴纸管理|A|删除词条|有单项删除与不可恢复确认文案|Do you want to delete this sticker?;Once deleted
词库与贴纸管理|A|复制贴纸|把贴纸复制到系统剪贴板供其他应用粘贴|Copied! Paste it anywhere;StickerExportManager
词库与贴纸管理|A|下载与保存贴纸|下载或导出图片到系统相册|Download sticker;Sticker saved to Photos!;StickerExportManager
词库与贴纸管理|B|动态贴纸导出|存在 GIF 帧源和动态媒体导出相关路径；具体导出格式选择未验证|StickerGIFFrameSource;gifData;StickerExportManager
词库与贴纸管理|A|贴纸和场景媒体预览|静态物体、场景图、视频或 GIF 使用不同展示组件|StickerVideoView;StickerSceneImageUIView;CustomVideoPlayer
闪卡复习|A|每日待复习队列|按 nextReviewDate 等字段筛选待复习内容|nextReviewDate;You have %d words to review today
闪卡复习|A|记忆曲线复习安排|记录复习阶段、次数和下次日期；未确认是 SM-2 或 FSRS|reviewStage;reviewCount;using the memory curve
闪卡复习|A|翻面查看答案|有闪卡正反面和翻转交互|FlashCardFrontView;FlashCardBackView;FlashCardStackView
闪卡复习|A|左右滑动掌握判断|右滑掌握、左滑未掌握，更新学习状态|Swipe to master;Swipe to review;isMastered
闪卡复习|A|复习文字显示模式|双语、仅目标语言或隐藏文字|Show both languages;Show learning language;Hide all text
闪卡复习|A|闪卡标准发音播放|先听词条发音再进行练习|FlashCardSpeech;Tap to play pronunciation
闪卡复习|A|按住跟读验证|麦克风和语音识别核对朗读内容，失败可重试|Hold & Speak to conquer;FlashCardSpeechError;Please read the word
闪卡复习|B|跟读相似度反馈|存在相似度得分和正确等级线索；不是已验证的专业音素评分|相似度得分;FlashCardCorrectLevel
闪卡复习|A|每日复习数量设置|调整每天复习目标数量|Set Daily New Words Count;flashcardCount
闪卡复习|A|重复复习与剩余数量|显示剩余待复习量，允许再次复习|Review Again;You have %d words left to review
闪卡复习|A|复习结果与正确率|统计掌握、遗忘及复习数量；有准确率展示文案|DailyRecorder;masteredCount;forgottenCount
闪卡复习|A|复习日历与连续天数|按日查看复习活动与连续记录|CalendarGridView;FlashCardStatiticsView;Your %d-day streak
闪卡复习|A|连续答对奖励反馈|5、10、20 连续正确的视觉和触觉反馈|Rhythm Master!;Unstoppable Flow!;LEGENDARY STREAK!
AI 语伴与对话|A|按今天的生活开聊|使用当天贴纸作为话题和词汇目标|Speak about today;DailyModeStrategy;ChatDailyStickerSnapshot
AI 语伴与对话|A|回看某天再开聊|日期选择与历史日期素材可用于当天故事式练习|Back to Today;CalendarDateButton;diaryDateString
AI 语伴与对话|A|按词汇分类开聊|按指定分类建立练习目标及分类进度|CategoryModeStrategy;ChatCategoryStickerSnapshot;categoryChatProgress
AI 语伴与对话|A|示例聊天体验|新用户可先用样例体验对话|Start a sample chat;ChatDemoData;TryDemoViewController
AI 语伴与对话|A|实时语音输入|麦克风采集、实时 ASR、按住说话和松开发送或取消|VoiceInputTurnController;Hold to speak;Release to send
AI 语伴与对话|A|AI 生成回复并朗读|对话引擎、流式文本与 TTS 回复播放|VoiceLLMTurnController;VoicePlaybackController;ChatAgentService
AI 语伴与对话|A|实时转写文本|用户语音和 AI 发言具有转写／字幕展示|ConversationLiveTranscriptView;partial_transcript;final_transcript
AI 语伴与对话|A|对话翻译|对话文本可翻译，独立控制翻译显示|ChatTranslationController;isEnabledChatTranslate
AI 语伴与对话|A|不会说时的提示|根据当前对话提供回答提示和鼓励|HintAgentService;ConversationHintCardView;What to say?
AI 语伴与对话|A|母语输入辅助表达|输入母语意图，翻译成目标语言帮助继续对话|Type in your language;ConversationHintReverseChannelView;Send hint translation
AI 语伴与对话|A|提示自动展开|可默认展示完整提示或折叠成小按钮|Auto-expand hint;isChatHintAutoExpand
AI 语伴与对话|A|消息朗读和录音回放|菜单可读消息或回放自己的录音|Read message aloud;Replay your recording;ConversationAudioCache
AI 语伴与对话|A|撤回已发送消息|长按用户消息撤回，并维护对话状态回滚|Long press to undo a message;ChatMessageListUndoPresentationSnapshot
AI 语伴与对话|A|练习词覆盖追踪|追踪哪些贴纸词已练到，展示剩余与覆盖进度|ChatStickerCoverageTracker;%d covered;All covered
AI 语伴与对话|A|结束或继续练习|练习结束前提示，可继续或结束|Continue Practicing;Your practice is about to end
AI 语伴与对话|A|中断恢复与重试|处理网络、后台中断、闲置、回复和播放失败|ChatRequestRecoveryCoordinator;Conversation Interrupted;Connection Interrupted
AI 语伴与对话|B|个性化长期记忆|提取用户事实并保存引用计数，用于后续对话；未发现独立记忆管理界面|MemoryExtractionService;UserMemoryManager;UserMemory
AI 语伴与对话|B|生活叙事与对话规划|有日记式场景规划与关系导向引擎；不是已确认独立可编辑日记产品|DiaryGenerationService;RelationshipDirectorService;SessionNarrative
语伴与语音设置|A|选择 AI 伙伴|四个角色标识 cappy、capu、capi、capo，带不同性格文案|BotCharacterID;bubble.cappy;bubble.capu;bubble.capi;bubble.capo
语伴与语音设置|A|自定义伙伴颜色|设置角色颜色并保存|Pick your buddy's color;chatCharatorCustomColors
语伴与语音设置|A|角色动态表情及口型|角色动画、眨眼、口型同步和发言动效|ConversationLipSyncDriver;LipSyncBlinkController;CharacterAvatarSpeechRigView
语伴与语音设置|A|伙伴语音选择与试听|选择声音风格并试听，包内有多语言声音配置|Choose Your Preferred Voice;BackendQwenTTSPreviewPlayer;TTSVoiceGroup
语伴与语音设置|A|发音声音设置|管理词条朗读声音，包含系统声音和 AI 语音实现|Pronunciation Voice;SpeechTTSSheetModel;TTSProvider
语伴与语音设置|A|高质量系统声音下载引导|跳转系统相关设置并指导下载，非应用自行安装系统声音|View Download Tutorial;SpeechQualityTutorialItem
语伴与语音设置|A|语速设置|调整伙伴说话和发音播放速度|SpeakingPacePageView;savedTTSSpeedValue;Speaking Speed
语伴与语音设置|A|学习等级设置|五级描述，从入门到流利；可降低等级并保留累计 XP|VoiceLevelSelectionPageView;Level 5: Fluent;Lower your level?
语伴与语音设置|A|单次对话难度设置|快捷调整对话难度，文案说明不改变学习等级|Choose chat difficulty;Your learning level won’t change
语伴与语音设置|A|文字大小与快捷设置|对话内调整字号、语速、提示等|QuickSettingsTextSizeSelector;HomeQuickSettingsSheet;Text Size
对话历史与成就|A|聊天历史列表与详情|按会话查看过去消息和对话记录|ChatHistoryView;ChatHistoryDetailView;ChatHistoryManager
对话历史与成就|A|会话统计|保存练习时长、轮次、消息数、用到的贴纸数及等级|ChatSession;turnCount;mentionedStickerCount
对话历史与成就|A|XP 与升级|完成练习获得经验并展示等级提升|earnedXP;Level Up!;LevelUpCelebrationContent
对话历史与成就|A|口语连续练习记录|显示连续天数和每周完成反馈|My Streak;ChatSessionStatisticsSnapshot;streakDays
对话历史与成就|A|本次学到的内容|完成流程包含 Today I Learned 汇总及相关数据类型|Today I Learned;TodayILearnedItem
对话历史与成就|A|练习成果分享卡|生成包含练习表现的分享图并使用系统分享|ChatHistoryShareCardView;Share My Progress;ShareCardView
对话历史与成就|A|伙伴分享与合影卡|有伙伴介绍、合影及头像分享文案；不是社交好友关系系统|Taking a photo with;Meet my;ShareCardFeature
对话历史与成就|B|流利度指标|会话模型包含 fluencyScore；量表、算法及每次是否展示未确认|fluencyScore
生活上下文|A|城市和天气个性化|请求位置并通过 WeatherKit 获取本地天气用于聊天|Location & Weather;weather.fetch_succeeded;voiceChatUserLocation
生活上下文|A|Apple 健康授权|独立设置页，可请求选定数据的读取授权|ProfileAppleHealthView;healthkit.authorization_started
生活上下文|A|健康摘要作为话题|结合步数、活动能量、运动、睡眠、恢复及 HRV 信息生成简短摘要|HealthSummary;Heart Rate Variability;Steps & Activity
生活上下文|A|上下文使用控制与授权说明|可选择是否分享健康／位置上下文，界面提供系统授权管理说明|SpeakContextSetupView;Share my wellness;Open Health App
生活上下文|B|照片时间和位置元数据|存在提取照片拍摄时间、位置和识别会话绑定实现；实际上传字段未运行验证|PhotoMetadataExtractor;RecognitionPhotoMetadata;has_location_metadata
语言与数据|A|母语和学习语言选择|独立保存 currentLanguage 与 targetLanguage|Choose Your Native Language;Choose your learning language;SupportLanguage
语言与数据|A|多语言与地区变体|包内支持语言类型及资源覆盖 16 个学习语言键，见报告明细|ChineseCantoneseCodingKeys;EnglishBritishCodingKeys;BrazilianPortugueseCodingKeys
语言与数据|A|切换学习语言与母语|保留旧数据并迁移已有词条内容；界面有每周切换限制提示|ChangeLanguageManager;Change your native language;Note: Can be changed once per week
语言与数据|A|语言迁移进度与恢复|批量翻译、进度、断网重试、后台暂停、恢复和失败回滚|LanguageChangeBatchRequestPipeline;LanguageMigrationCheckpointWriter;language_change.rollback_completed
语言与数据|A|语言迁移实时活动|ActivityKit 展示迁移进度、等待状态及返回应用入口|LanguageMigrationLiveActivity;Updated %d of %d items
语言与数据|A|界面语言选择|独立于学习语言；有 9 套本地化目录|Interface Language;System Language
语言与数据|A|本地词库与历史持久化|Core Data 保存贴纸、消息、会话、用户及每日记录|StickerDatabase;ChatMessage;DailyRecorder
语言与数据|A|iCloud 同步及恢复实现|CloudKit 镜像、远端变更应用、账户监控与媒体下载|icloud.remote_changes_applied;icloud.account_monitor_configured;Downloading from iCloud
语言与数据|A|音频缓存清理|清理已缓存 AI 语音文件，保留功能使用能力|Clear Audio Cache;Don’t worry — the feature will still work
语言与数据|B|图片与 GIF 媒体缓存|包含磁盘缓存、加载调度及滚动时资源管理；属于底层能力|StickerMediaPayloadDiskCache;StickerPayloadLoadCoordinator
桌面与系统入口|A|贴纸日历组件|按日期显示收集过的单词|CalendarHomeWidget;Sticker calendar
桌面与系统入口|A|拍摄组件|展示拍摄入口及当天词汇素材|CaptureHomeWidget;Capture a moment
桌面与系统入口|A|复习卡组件|桌面查看待复习单词，可点击扬声器听发音|ReviewHomeWidget;Review card
桌面与系统入口|A|词汇集组件|桌面展示个人收集的词汇贴纸|VocabularyHomeWidget;Word collection
桌面与系统入口|A|连续打卡组件|展示连续练习与伙伴提示|StreakHomeWidget;Daily streak
桌面与系统入口|A|贴纸环绕组件|另一种以贴纸环绕为视觉的打卡展示|StreakRingHomeWidget;Sticker ring
桌面与系统入口|A|小组件发音交互|通过 PlayWidgetWordIntent 播放指定词条发音，无需声明打开主应用|PlayWidgetWordIntent;Play pronunciation
桌面与系统入口|A|组件尺寸和外观样式|不同尺寸及打卡样式配置；逐类尺寸支持矩阵未恢复|Choose the large widget's appearance;Streak style;WidgetDesignMetrics
桌面与系统入口|A|快捷指令打开相机|App Intent 与自动快捷短语可打开 CapWords 相机|CameraLauncherShortcutIntent;source=appShortcut
桌面与系统入口|A|控制组件打开相机|ControlWidget 对应独立相机启动入口|CameraLauncherControlWidget;source=controlWidget
桌面与系统入口|A|锁屏小组件入口|CameraLauncherScreenWidget 通过 URL 跳转相机|CameraLauncherScreenWidget;source=lockScreenWidget
桌面与系统入口|B|安全锁屏拍摄扩展|IPA 声明 securecapture 并链接 LockedCameraCapture；未证明锁定状态下完整拍摄识别流程可用|SnapWordsCaptureExtension
桌面与系统入口|A|组件安装教程与画中画|引导视频可尝试画中画，以便边看边添加桌面组件|WidgetGuidePlayback;widget.whatsnew.pipStarting
提醒与外观|A|每日学习提醒|设置提醒时间并调度本地通知|Daily Reminder;SetupReminderView;daily_reminder_notification
提醒与外观|A|复习提醒入口|提供复习提醒相关设置／说明；与每日通知如何合并未完全恢复|Review Reminder;Review_entry_source
提醒与外观|A|免费试用到期提醒|试用结束前一天通知，需通知权限|free_trial_end_notification;Remind me before the free trial ends
提醒与外观|A|迁移暂停通知|语言迁移暂停时提示返回应用继续|language_change.continuation_notification_scheduled;Language migration paused
提醒与外观|A|浅色、深色、跟随系统|全局外观选择|Appearance.Dark;Appearance.Light;AppAppearancePreference
提醒与外观|A|昵称和头像编辑|本地资料可修改，部分分享卡可能展示|Edit Profile;ProfileInfoAlertView;avatarData
提醒与外观|A|触觉、音效与过渡动画|闪卡、拍摄和贴纸使用音效、触觉及粒子／消散动画|SoundEffectManager;StickerDustImageView;Inflate
新用户引导|A|学习目标与困难问卷|收集动机、当前水平、开口障碍与坚持难点|What's your main motivation;Where do you get stuck;OnboardingCModel
新用户引导|A|昵称及性别信息选择|有昵称与性别选择，包括非二元和暂不透露|What should we call you;Onboarding Gender Prefer not to say
新用户引导|A|语言、语音和等级初始化|引导选择母语、目标语、声音及学习等级|OnboardingCurrentLanguageCell;OnboardingVoiceListContent;OnboardingLevelBallIntroView
新用户引导|A|首次拍照及复习示例|提供首个词条、拍摄保存教程和闪卡试用|OnboardingTutorialCell;FlashCardTryDemoAlertView;Tap ✓ to save your first word
新用户引导|A|语伴创建与对话引导|创建伙伴、选颜色和声音，试聊并设置生活上下文|ChatOnboardingViewController;Let's bring your buddy to life
新用户引导|A|新功能介绍|展示分类、对话、Live Photo／视频及小组件介绍|WhatsNewSheetView;WhatsNewForChatSheetView;Live Photo & Video Recognition is Here
会员与购买|A|免费体验与额度限制|免费采集次数和体验后的升级入口|Free tries used up;freeStickerCount
会员与购买|A|高级版功能权益|付费页声明无限识图、例句、AI 对话等；具体线上额度和限流未知|Unlimited AI conversation;Unlimited AI word capture;PurchaseBenefitItem
会员与购买|A|订阅套餐选择|含月、年及周相关文案／配置线索；当前线上在售套餐需 App Store 验证|Monthly;Annual Plan;Weekly %@
会员与购买|B|终身或一次性购买支持|有一次性购买、终身及恢复历史非订阅订单的路径；不证明当前仍售卖|Lifetime;PurchaseNonSubscriptionSnapshot;one-time purchase
会员与购买|A|试用与新用户优惠|免费试用、首年优惠、限时优惠与倒计时展示|PurchaseGiftViewController;PurchaseSaleViewController;saleCountdownDate
会员与购买|A|购买和恢复购买|通过应用购买状态处理和恢复历史权益|InAppPurchase;Restore Purchase;PurchaseRestoreResult
会员与购买|A|管理订阅|跳转 Apple 订阅管理页面|Manage Subscription;https://apps.apple.com/account/subscriptions
会员与购买|A|购买异常解释与支持|处理待批准、退款、扣款问题、无权益、账号关联与验证问题|PurchaseNotice;PurchaseErrorDetails;Your purchase could not be verified
帮助与支持|A|邮件联系与功能建议|从应用发起邮件反馈，可附诊断或购买详情；本次未发送邮件|FeedbackEmailCoordinator;Suggest a Feature;Contact Us
帮助与支持|A|FAQ、隐私政策及服务条款|打开对应中英文网页|https://capwords.app/faqs;Privacy Policy;Terms of Service
帮助与支持|A|关于与创作故事|查看开发者故事和产品来源|OurStoryViewController;A Story of Exploration
帮助与支持|A|评分邀请|特定使用节点邀请评分并跳转 App Store|RatingPromptManager;Give 5 Stars
帮助与支持|A|语音教程和数据来源说明|系统声音下载指南及开源词典、词频数据许可说明|SpeechQualitySheetView;Data Sources;OPEN_LEXICON
内部与诊断|D|识别调试面板|查看识别阶段、时间及请求审计线索，受 debug 开关约束|RecognitionDebugSheetView;debugRecognitionDebugEnabled
内部与诊断|D|识别、翻译与例句提示词编辑|打包了相应调试视图，不作为普通用户编辑 Prompt 功能|VideoVisionPromptView;TranslationPromptView;ExamplePromptView;PromptDebugManager
内部与诊断|D|AI 服务商、模型及路由选择|自动／手动路由、国内海外候选及模型切换，常规可见性未确认|ChatTabLLMModelMenuButton;voiceChatAutomaticRoutingEnabled;backendBaseURLOverrideEnabled
内部与诊断|D|对话引擎与隐藏规划调试|查看 Director／Think 结果和调试导出；不是给普通用户展示模型思维的承诺|LLMCallDebugSheet;Show Think LLM debug info;Conversation With Hidden Think
内部与诊断|D|A/B 引导与付费墙布局|多版引导及购买页实验，可强制展示|debugABTestSandboxMode;appOnboardingExperimentVariant;PurchaseLayout
内部与诊断|D|会员及优惠调试覆盖|存在强制 Pro 和优惠资格覆盖，仅归入调试|debugForceProMode;debugSaleEligibilityOverride
内部与诊断|D|语言数据重置调试|有 DebugLanguageDataResetResult；不是普通用户注销或清空账户功能|DebugLanguageDataResetResult;debug.language_data_reset_fetch_failed
内部与诊断|D|诊断压缩包与日志脱敏|生成诊断档案、保留计数和日志脱敏规则|CapWords-Diagnostics.zip;DiagnosticLogArchive;redacted
内部与诊断|D|崩溃、归因和质量遥测|包含 Crashlytics、AppsFlyer 及对话质量模块；是否启用及实际上传需运行验证|ChatQualitySessionRecorder;ChatQualityOutbox;Firebase
内部与诊断|D|设备注册与认证恢复|后端设备凭据、刷新和失败恢复，不等同于用户注册账号|BackendDeviceCredentials;BackendDeviceAuth;device_auth.recovery_started
内部与诊断|D|媒体缓存和任务优先级|图像／GIF 缓存、释放和滚动调度，属于性能基础设施|StickerMediaWorkPriorityController;StickerMediaPayloadLifetimeTracker
'''

def proof(query):
    hits = []
    for label, table in [('主应用文案', UI), ('组件文案', WUI)]:
        for key, value in table.items():
            if query in key or query in value:
                hits.append({'source': label, 'key': key, 'value': value})
                break
    for label, entries in [('主程序UTF8', STRINGS), ('主程序类型', TYPES), ('组件程序', WIDGET), ('主程序ASCII及符号', ALL_STRINGS)]:
        for item in entries:
            if query in item['text']:
                hits.append({'source': label, 'offset': item['offset'], 'text': item['text'][:180]})
                break
    for item in INVENTORY:
        if query in item['path']:
            hits.append({'source': 'IPA文件目录', 'path': item['path']})
            break
    for entity in MODELS:
        if query == entity['entity'] or query in entity['properties']:
            hits.append({'source': 'CoreData模型', 'entity': entity['entity'], 'field': query})
            break
    return hits

features = []
for line in DATA.strip().splitlines():
    group, status, title, scope, selectors = line.split('|')
    evidence = [{'query': q, 'matches': proof(q)} for q in selectors.split(';')]
    features.append({'id': f'F{len(features)+1:03}', 'module': group, 'status': status,
                     'function': title, 'scope': scope, 'evidence': evidence})

missing = [(f['id'], e['query']) for f in features for e in f['evidence'] if not e['matches']]
(ROOT / 'FEATURE-CATALOG.json').write_text(json.dumps({'artifact_sha256': 'c6cc5aba8194c044fea2f7df1c92c290fb58502a90fdb5afd3df9522c9f61fe8',
    'scope': 'IPA静态功能清单，非运行验收结果', 'features': features, 'unmatched_selectors': missing}, ensure_ascii=False, indent=2), encoding='utf-8')

HEADER = '''# CapWords 全量静态功能清单

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

'''

def brief(feature):
    parts = []
    for e in feature['evidence']:
        matched = e['matches']
        if matched:
            m = next((x for x in matched if 'offset' in x), matched[0])
            label = e['query'].replace('|', '\\|').replace('\n', ' ')
            parts.append('`' + label + '`' + (' @ ' + m['offset'] if 'offset' in m else '（' + m['source'] + '）'))
    return '；'.join(parts[:3])

text = HEADER
for group in dict.fromkeys(f['module'] for f in features):
    text += '### ' + group + '\n\n| 编号 | 功能 | 行为与边界 | 等级 | 证据定位 |\n| --- | --- | --- | --- | --- |\n'
    for f in features:
        if f['module'] == group:
            text += '| ' + ' | '.join([f['id'], f['function'], f['scope'], f['status'], brief(f)]) + ' |\n'
    text += '\n'

text += '''## 语言、分类与系统扩展明细

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
'''

counts = Counter(f['status'] for f in features)
summary = f"共记录 **{len(features)} 项**：A {counts['A']} 项、B {counts['B']} 项、D {counts['D']} 项，分布于 {len(set(f['module'] for f in features))} 个模块。\n\n"
text = text.replace('## 功能总表\n\n', '## 功能总表\n\n' + summary)
(ROOT / 'FEATURES.md').write_text(text, encoding='utf-8')
print(json.dumps({'total': len(features), 'status': counts, 'modules': dict(Counter(f['module'] for f in features)), 'unmatched_selectors': missing}, ensure_ascii=False, indent=2))
