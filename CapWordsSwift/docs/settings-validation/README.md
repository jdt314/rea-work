# 设置页修改与验证

对照 [6.mp4 逐帧观察](../video-6-evidence/OBSERVATIONS.md) 重做个人页。主页面分为资料、学习设置、应用与账户、帮助与关于，使用大圆头像、语言胶囊、白色圆角分组卡片和橙色开关。个人页标题随滚动从左侧大标题缩小并移至导航栏中央，下拉回顶部恢复。标题独立于内容布局，避免收起时列表跳动；二级页面沿首页的同一导航栈推进。顶部复用首页的材质渐变遮罩，标题绘制在遮罩上方，保持清晰。[标题双向滚动验证](../settings-title-validation/README.md) 提供本轮录屏及截图。

## 实际行为

- 编辑头像和昵称使用临时草稿，保存后写入本机偏好；头像缩小后保存，取消不改原资料。
- 学习语言包含中文、粤语、美式／英式英语、法语、西班牙语、日语、韩语、德语、意大利语。母语另行选择，后续识别请求按母语生成释义及例句译文，旧词卡继续保留原内容。
- 学习提醒使用独立 ID 的每日重复本地通知，开启时才申请通知权限；调整时间替换原提醒，关闭时取消。复习提醒继续使用已有启动复习偏好。
- 声音页列出本机可用系统声音，选择即试听；所选声音及语速影响词卡实际朗读。视频中的云端声音不在本机可用时，不伪造声音名称。
- 外观菜单保留跟随系统、浅色、深色，修改即时生效并在重启后保留。界面语言连接 iOS 应用设置，并提供中英文设置文案。
- 订阅管理打开 Apple 订阅管理页面。缓存清理仅删除 Caches 子项及 URLCache，不删除词库、贴纸和个人资料。
- Apple 健康只在用户主动连接时请求读取步数、运动、睡眠、活动能量和心率变异性。只有真实读到样本的来源才显示勾选；不会写入或上传健康数据。
- 小组件有独立 WidgetKit 扩展，小／中尺寸显示最新词卡，点击打开词库。共享快照随最新词卡或图片变更更新，测试词库不会覆盖真实小组件数据。
- FAQs、支持信息分享、功能建议草稿与分享、关于、天气来源、隐私和条款均有可进入的页面。AI 图片识别配置入口保留。

## 验证及边界

应用与 Widget 扩展已构建，UI 测试通过 `build-for-testing` 编译。8 项核心测试实际执行通过，覆盖缓存清理及符号链接目标保护、小组件快照编解码、母语与目标语言传递和既有 AI 请求／错误处理。

另完成 24 张浅深色页面截图、2 张英文界面截图，以及 11 项设置页外观背景检查：含即时切换、跟随系统、显式模式优先及重启保留。英文核对中修正了原生底栏标签和 Apple 健康标题的本地化。结果汇总见 [validation.json](validation.json)，主题专项像素结果见 [settings-checks.json](../theme-validation/settings-checks.json)。

截图来自 iPhone 17 Pro / iOS 26.1 模拟器的实际 SwiftUI 渲染。通过 Debug 路由进入页面，不等同于触摸自动化，也不证明系统授权弹窗、真人健康数据、主屏幕添加小组件或订阅操作已经完成。此前 XCTest 运行服务的 DTServiceHub/lockdown 连接故障仍需环境恢复后再做触摸回归。

主应用配置 HealthKit 与 App Group，Widget 使用同一 `group.com.wordrove.a2px.cn`。真机安装需要开发团队的描述文件包含这些能力；当前验证使用模拟器本地签名。健康和通知权限由设备用户实际决定。

## 页面证据

| 页面 | 浅色 | 深色 |
| --- | --- | --- |
| 个人页 | [截图](light-header.png) | [截图](dark-header.png) |
| 应用与账户 | [截图](light-general.png) | [截图](dark-general.png) |
| 帮助与页脚 | [截图](light-footer.png) | [截图](dark-footer.png) |
| 资料编辑 | [截图](light-profile.png) | [截图](dark-profile.png) |
| 学习语言 | [截图](light-language.png) | [截图](dark-language.png) |
| 母语 | [截图](light-native-language.png) | [截图](dark-native-language.png) |
| 学习提醒 | [截图](light-reminder.png) | [截图](dark-reminder.png) |
| 发音声音 | [截图](light-voice.png) | [截图](dark-voice.png) |
| 小组件引导 | [截图](light-widgets.png) | [截图](dark-widgets.png) |
| Apple 健康 | [截图](light-health.png) | [截图](dark-health.png) |
| FAQs | [截图](light-faq.png) | [截图](dark-faq.png) |
| 关于 | [截图](light-about.png) | [截图](dark-about.png) |

`metadata.json` 记录采集设备和场景；可查看 [浅色总览](contact-light.jpg)、[深色总览](contact-dark.jpg)、[英文个人页](en-light-header.png)、[英文应用与账户](en-light-general.png)。

复现：在仓库根目录执行 `bash CapWordsSwift/scripts/verify.sh build-for-testing`，再运行 `python3 CapWordsSwift/scripts/capture_settings.py`。可用 `--only light-header dark-health` 仅补采指定页面。外观专项回归使用 `python3 CapWordsSwift/scripts/capture_themes.py --only settings` 和 `python3 CapWordsSwift/scripts/verify_theme_captures.py --settings-only`。
