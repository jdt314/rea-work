# 首页日期卡片与展开转场

> 后续已根据用户要求改为全局「跟随系统 / 浅色 / 深色」外观。本文记录当时日期卡片对齐过程，固定首页深色的描述已被 [全局主题实现](../theme-validation/README.md) 取代。

按用户截图调整首页日期卡片，并根据 `5.mp4` 将日期卡片到词库的导航改为从卡片放大、关闭时缩回卡片。日期、数量、预览贴纸均读取真实词库，不固定为参考截图中的数据。

## 尺寸与实现

参考截图为 602 × 1308，按约 402 pt 屏幕宽度换算。以下为重建采用的布局值，不是反编译得到的原版常量。

| 项目 | 实现 |
| --- | --- |
| 卡片 | 高 194 pt，左右边距 20 pt，垂直间隔 12 pt |
| 圆角 | 连续圆角，半径 44 pt |
| 内边距 | 24 pt |
| 日期 | 28 pt 衬线字体，`M月d`，不加“日” |
| 数量 | 16 pt，深色文字 70% 不透明度 |
| 贴纸 | 四个等宽槽位，间隔 12 pt，高 66 pt，最多预览四项 |
| 配色 | 深色首页背景；卡片按粉、蓝、紫、黄等顺序显示 |
| 菜单 | 固定在右上角，44 pt 点击区域 |

日期卡片使用自然日起点生成稳定来源 ID，以 `matchedTransitionSource` 和 `navigationTransition(.zoom)` 建立双向转场。首页保留在导航栈中，展开页通过 `initialDay` 定位所选日期。减少动态效果打开时不启用缩放转场。保留原生 TabView，展开词库时隐藏底栏。

应用根视图通过 `HomeAppearancePreferenceKey` 接收首页主题，避免根视图固定浅色使底栏、展开页出现错误颜色。非首页模块和默认启动词库仍使用原有浅色表现；相机主题继续由已有偏好控制。

## 参考证据与边界

- [参考截图](reference.jpeg)：日期格式、卡片颜色、尺寸比例、四列贴纸和深色首页。
- [视频关键帧](reference-contact.jpg)：`5.mp4` 约 1.4–1.8 秒从卡片区域展开词库，约 3.0–3.4 秒缩回首页。抽帧真实时间见 [metadata](reference-metadata.json)，部分请求时间对应重复编码帧，不能据此精确恢复原动画曲线。
- REA 本轮确认 `cap.ipa` SHA-256 为 `c6cc5aba8194c044fea2f7df1c92c290fb58502a90fdb5afd3df9522c9f61fe8`。包检查证据 `ev_6c658e68d2ac4a7de478ae226e963069f7d98602912d38ef58d08feedbe8e2ec`，摘要见 [rea-summary.json](rea-summary.json)。包检查不证明运行时行为。
- 已逐字节校验包内 `Payload/SnapWords.app/SnapWords` 的 SHA-256 与已有 `capwords-analysis/evidence/ipa/home-defaults/identity.json` 一致。复用 HOME-02、HOME-03、HOME-07：日期快照来自持久化词库，保留当天空日期，按所选日期进入词库控制器。
- 缩放转场采用系统实现匹配视频观感，未声称恢复原版私有动画参数，也未在本轮执行原 IPA。

## 验证

构建成功，见 [build.log](build.log)。真实模拟器截图及回放由独立内存词库生成，示例贴纸和日期与用户截图不同。收起前后按卡片背景色测量的纵向边界完全一致，见 [position-check.json](position-check.json)；完整蓝色、紫色卡片实测为 582 px，即 3× 屏幕上的 194 pt。

- [收起状态](collapsed.png)
- [展开状态](expanded.png)
- [返回状态](returned.png)
- [转场录屏](date-zoom.mov)

回放调用与点击相同的导航方法，但由 Debug 定时任务触发，不代表真实触摸自动化通过。仅在 `--uitesting --preview-home` 配合预览参数时运行，不写入用户词库。

新增 `testDateCardZoomReturnsToSameScrolledCard`，检查历史日期定位、尺寸、两次展开/返回及滚动位置保持。尝试执行该测试和既有底栏导航测试时，XCTest 卡在 DTServiceHub/lockdown 连接，尚未执行断言；已中断本次挂起任务，日志见 [ui-tests-interrupted.log](ui-tests-interrupted.log)。真实点击及交互式手势取消仍需测试服务恢复后回归。

重新生成视觉验证：在仓库根目录执行 `python3 CapWordsSwift/scripts/capture_home_dates.py`。脚本默认使用已启动的 iPhone 17 Pro（iOS 26.1），可以用 `CAPWORDS_SIMULATOR_ID` 指定其他设备；先运行 `bash CapWordsSwift/scripts/verify.sh` 编译。
