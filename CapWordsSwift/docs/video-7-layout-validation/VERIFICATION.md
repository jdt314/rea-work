# 7.mp4 页面布局验证

验证时间：2026-10-21。设备：iPhone 17 Pro 模拟器，iOS 26.1，`4607AA88-3821-4245-91AA-A1E6B8E407E4`。

最终 `ReviewView.swift` SHA-256：`734254af5c3175bd6077cca2eec8c15e1a1d630cf61de54ffa52b1fb8fc82716`。

`bash CapWordsSwift/scripts/verify.sh build-for-testing` 成功，见 [构建日志](build.log)。安装最新应用后通过 DEBUG 启动参数截取并查看了 [闪卡](flashcard.png) 和 [复习首页](review-home.png)。

- 闪卡使用 `--uitesting --seed-library --preview-home-review --preview-flashcard`。对照视频 `frame-01.jpg`，返回/菜单按钮、居中进度、倾斜叠卡、单词与音标、底部语音提示和虚线麦克风的主要位置与比例接近；未见文字重叠、意外裁切或控件越界。卡片阴影和随机颗粒已在最后版本刷新确认。
- 主页使用 `--uitesting --seed-library --preview-home-review`。五卡预览、复习状态、开始按钮和月历正常呈现，未见文字重叠；月历后半部分延伸至可滚动区域。视频 `frame-22.jpg` 是向下滚动后的状态，本次截图是页面顶部，不能据此逐像素比较月历的屏幕纵坐标。
- 种子词库是 Forest 等内容，总数显示真实队列的 5；视频是牙膏等内容和 11。日期、连续天数及状态栏也来自当前模拟器，并未硬编码参考值。

当前工具没有 DeviceInteraction/UI 层级服务，使用 simctl 启动和截图；未根据截图猜测坐标触控。此前 XCTest 的 DTServiceHubClient 服务故障未重复测试。因此本次只确认构建和静态渲染，未验证滚动、滑卡动画、菜单点击、设置弹窗、返回导航及麦克风触控。语音识别仍未接入，不能把麦克风外观还原视为语音功能验证通过。
