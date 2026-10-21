# 卡片旋转与白色反面验证

日期：2026-10-21。iPhone 17 Pro 模拟器，iOS 26.1，设备 `4607AA88-3821-4245-91AA-A1E6B8E407E4`。

`bash CapWordsSwift/scripts/verify.sh build-for-testing` 成功，见 [build.log](build.log)。截图时 `ReviewView.swift` SHA-256 为 `c1be369856c5d61667ceac67bf0e95df3caaf7f721c3961eb93a06b9815ab75e`。

- [正面](front.png)：后两层卡片明显向相反方向旋转；卡片未越界，单词、音标、导航和语音入口未重叠。
- [反面](back.png)：白色卡片隐藏后层，音标和播放图标、英文、横向分隔线、大中文及左下浅灰标记均完整呈现，未见文字重叠或意外裁切。使用真实种子词 Forest / 森林，未硬编码参考文字。
- 对照 [用户参考图](reference.png)，左对齐层级及主要布局一致；当前白卡颗粒比参考更淡。参考为局部截图，不能用全屏纵坐标做逐像素对照。

通过 simctl 安装与启动，正面参数为 `--uitesting --seed-library --preview-home-review --preview-flashcard`，反面增加 `--preview-flashcard-back`。环境没有 DeviceInteraction 层级/触控工具，未猜测坐标操作；没有重跑此前被 DTServiceHubClient 服务故障阻断的 XCTest。故本次只验证编译和正反面的静态渲染，未验证点击翻面过程、3D 动画、减少动态效果、长词换行及语音功能。
