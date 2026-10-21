# 复习界面验证（2026-10-21）

最新源码已通过 `bash CapWordsSwift/scripts/verify.sh build-for-testing`。本次成功在 iPhone 17 Pro / iOS 26.1 模拟器安装并启动构建产物，完成以下页面的实际渲染截图检查；交互测试尚未执行。

## 渲染证据

设备标识：`4607AA88-3821-4245-91AA-A1E6B8E407E4`。所有最新截图均为 **1206 × 2622 px**。

| 截图 | 真实启动参数 | 观察 |
| --- | --- | --- |
| [final-prompt.png](final-prompt.png) | `--uitesting --exercise-startup --seed-library --onboarding-complete` | 米黄色全屏背景、左上关闭按钮、五张错落卡片、居中问候和待复习数量、黑色圆角开始按钮及底部彩色相机图标均完整显示；未见文字重叠、截断或按钮越界。当前测试数据为 5 个单词，问候按运行时间显示。 |
| [final-review-home.png](final-review-home.png) | `--uitesting --seed-library --preview-home-review` | 复习标题、卡片预览、连续天数、今日状态、开始复习及月份切换均正常显示；原生标签栏固定在底部，月历内容可在其下方滚动。此次未执行滚动或点击，未验证屏幕下方统计和每日数量入口。 |
| [final-review-sheet.png](final-review-sheet.png) | `--uitesting --seed-library --preview-review` | 词库入口的复习页面以 sheet 呈现；标题、卡片、连续天数、开始按钮及月历正常显示。该现有调试入口打开的是复习首页，并非闪卡轮次。 |

参考图中的物品与测试数据不同；本次只核对页面构成、相对位置与可读性，未声称逐像素一致。

## 构建和 UI 执行器结果

- [final-build.log](final-build.log)：末尾为 `TEST BUILD SUCCEEDED`。
- [final-ui-tests-environment-failure.log](final-ui-tests-environment-failure.log)：在进入测试前，Xcode 无法连接 `com.apple.instruments.deviceservice.lockdown`，报错 `DTServiceHubClient failed to bless service hub` / `'localDeviceConnectionWithError:' failed but didn't provide an error.`。
- `launchctl print system/com.apple.instruments.deviceservice.lockdown` 返回该服务不存在。
- 本次测试进程 PID `37175` 已用 `SIGINT` 停止，没有反复重跑同一失败环境。Xcode 中断后还报告 action log 未结束，无法正常保存 xcresult；因此以完整文本日志保留失败证据。

以下 6 项仅完成测试构建，**均未执行，不能视为通过**：

1. `testDailyReviewWaitsForLaunchAndDismissesToHome`
2. `testDailyReviewStartsFixedQueue`
3. `testDailyReviewCameraOpensAfterDismissal`
4. `testTodaysReviewIsNotPresentedAgain`
5. `testNativeTabBarAndLibraryNavigation`
6. `testReviewRoundWritesDailyStatisticsAndChangesNewWordLimit`

测试截图 helper 已补充 `app.debugDescription` 层级附件，并在固定队列开始处增加截图；由于执行器未能启动，本次未产出有效 UI 层级文件，也没有用截图推测坐标点击。

收尾时同步修正旧的拍照保存回归测试：词库打开复习首页后先点击“开始复习”，结束轮次后返回首页并下滑关闭 sheet，再继续删除单词。该修订再次通过 `build-for-testing`，尚未执行交互测试。

## 自动化能力与限制

当前环境无 DeviceInteraction MCP；`cliclick` 不在 PATH 中。仓库现有 capture 脚本使用 simctl 启动调试路由并截图，没有提供可靠的触摸/层级替代。`simctl ui` 仅支持外观、对比度及字体大小设置，不能导出可访问性层级或执行点击。

本次结论限于构建和实际页面渲染。关闭、开始复习、相机入口、标签栏导航、完成统计及每日数量保存仍需可工作的 XCTest 执行器补验；语音练习不在本次验证范围。
