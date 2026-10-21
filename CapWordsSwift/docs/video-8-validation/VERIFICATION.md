# 视频8效果验证

日期：2026-10-21。最终 ReviewView.swift SHA-256：833307748f24696d26b86fcc3a483efc11937254214011c3cc5fb93ec2bca664。

最新 build-for-testing 成功，日志见 build.log。iPhone 17 Pro / iOS 26.1 模拟器安装最新产物后，使用 DEBUG 路由固定拖动状态截图。

- idle.png：同中心4°/9°同向叠放，前卡竖直，深色背景。
- drag-left.png：向左75pt，右侧纸边更近，透视和浅色细边清晰，物品保留原图。
- drag-right.png：向右75pt，左侧纸边更近，物品切换为彩虹渐变闪点；文字与卡纸不被染色。
- right-cutout.png：选第二张透明冰茶物体，彩虹严格跟随杯子及吸管轮廓，没有覆盖物体外的卡纸。

启动基础参数：--uitesting --seed-library --preview-home-review --preview-flashcard --appearance=dark；左右效果分别追加 --preview-drag-left / --preview-drag-right；透明物体验证追加 --preview-flashcard-index=1。

截图已目视检查，无意外文字重叠或特效超出遮罩。拖动时后卡的物体可能仍被前卡遮挡，取决于位移；没有把无遮挡程度硬编码成视频某帧。

这是静态渲染验证，不是实际触摸手势测试。此前 XCTest 执行器系统服务失败，本次未重跑交互测试；未验证帧率、手势取消回弹或连续快速切卡。减少动态效果时禁用透视旋转，调度及保存规则沿用原实现。

视频逐帧观察见 ../video-8-evidence/OBSERVATIONS.md。角度、透视强度、阈值和光效是对视频的本地近似实现，未声称恢复了原版GPU参数。语音识别仍处于规划阶段。
