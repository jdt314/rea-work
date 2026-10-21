# 全局外观设置与主题

首页黑色背景属于深色外观。现在可在「个人 → 外观」或词库菜单中的「设置 → 外观」选择跟随系统、浅色、深色。默认跟随系统，修改后立即生效，重启保留选择。

## 已完成的方案

| 层次 | 实现 |
| --- | --- |
| 偏好 | `AppAppearance` 定义三种值，以 `appearanceMode` 持久保存；缺失或未知值回退跟随系统 |
| 应用窗口 | 根视图通过同一 UserDefaults 的 AppStorage 观察选择，统一设置 preferredColorScheme；跟随系统传 nil |
| 配色 | Palette 集中管理 home、paper、library、surface、ink、muted、separator 和强调色，使用动态 UIColor 跟随窗口特征 |
| 设置 | 外观行打开原生菜单，提供跟随系统、浅色、深色三项和当前选项勾选；外观行的 VoiceOver 值同时说明当前实际外观 |
| 页面 | 首页、分类、词库、搜索、对话、复习、设置、AI 配置、词卡详情、编辑、裁剪、识别结果统一使用主题表面及文字颜色 |
| 特殊视觉 | 相机取景保持黑底白色操作提示；关闭相机恢复用户模式。日期卡片自身色彩、贴纸白边和深色字面、品牌开屏保持固定视觉 |

移除了上一版的 HomeAppearancePreferenceKey 和首页专用强制深色逻辑，以及 Info.plist 中固定 Light 的限制。主题由用户选择决定，与当前标签、是否点击日期卡片无关。

浅色背景保留原有纸张质感，深色使用纯深灰背景和更亮的文字；输入框、复习卡片、例句容器及圆形操作按钮不再固定白底。贴纸字面使用独立的 `stickerInk`，不会随暗黑模式变成白字白边。浅色强调色加深，避免浅色背景上文字对比不足。

## 验证结果

2026-10-20 按 6.mp4 重做设置页后，设置的浅色页面背景调整为 RGB(246,246,246)，深色保持 RGB(27,27,27)。新设置页的分组、弹层和二级页面证据见 [设置页验证](../settings-validation/README.md)。下述七类页面记录包含前一轮主题验证；本轮设置专项结果另存 `settings-checks.json`。

- 应用构建通过，新增 UI 测试也通过 build-for-testing 编译。
- AppAppearanceTests 通过：缺失/未知偏好回退系统，以及三种存储值的解析。
- iPhone 17 Pro / iOS 26.1 真实模拟器：七类页面的浅深色渲染已检查。
- 设置保持打开时，通过其 AppStorage 绑定回放浅色 → 深色 → 浅色 → 系统，验证即时更新。
- 选择系统后，不重启应用切换模拟器系统外观，验证两个方向均同步。
- 系统浅色时手动深色、系统深色时手动浅色，验证用户选项优先。
- 在专用测试偏好中保存深色，终止进程再启动、不重新传入模式，验证重启后保留深色。
- 保留 24 张主题验证截图及首页底部留白补充截图，23 项页面背景与切换结果校验通过；相机白色操作提示另行目视检查。
- 脚本完成后恢复模拟器原系统外观；测试使用独立偏好与内存词库。

截图和 `checks.json` 仅证明真实渲染与程序化切换行为，不等于真实触摸自动化。上一轮 XCTest 运行服务卡在 DTServiceHub/lockdown 连接，本轮没有重复启动该挂起路径。已添加 `testAppearanceChangesImmediatelyAndSurvivesRelaunch`，待测试服务恢复后可验证点击操作。

## 查看截图

| 页面 | 浅色 | 深色 |
| --- | --- | --- |
| 首页 | [浅色](light-home.png) | [深色](dark-home.png) |
| 设置 | [浅色](light-settings.png) | [深色](dark-settings.png) |
| 词库 | [浅色](light-library.png) | [深色](dark-library.png) |
| 复习 | [浅色](light-review.png) | [深色](dark-review.png) |
| 对话 | [浅色](light-conversation.png) | [深色](dark-conversation.png) |
| 词卡详情 | [浅色](light-detail.png) | [深色](dark-detail.png) |
| 识别结果 | [浅色](light-result.png) | [深色](dark-result.png) |

行为证据：[即时深色](live-dark.png)、[跟随系统深色](system-dark.png)、[跟随系统浅色](system-light.png)、[重启保留深色](persisted-dark.png)、[深色系统下手动浅色](explicit-light-on-dark.png)。

## 复现

在仓库根目录运行：

```sh
bash CapWordsSwift/scripts/verify.sh build-for-testing
python3 CapWordsSwift/scripts/capture_themes.py
python3 CapWordsSwift/scripts/verify_theme_captures.py
```

可用 `CAPWORDS_SIMULATOR_ID` 指定已经启动的模拟器。`--appearance=`、主题回放、预览页面和保留测试偏好的参数均仅 Debug 测试使用；Release 不读取这些参数。

静态页面采集会等待目标背景出现，最多额外等待 20 秒，避免把启动画面当成页面结果。可通过 `python3 CapWordsSwift/scripts/capture_themes.py --only light-review` 补采单个静态场景。
