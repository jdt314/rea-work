# 范围

- auth：用户要求修复拍照识别后的中文、按钮尺寸位置、随文字变化的白底，并使用原生流体玻璃；补充指定 `4.mp4` 和 REA 解析 `cap.ipa`。
- in_scope：本地 CapWordsSwift 源码与测试、4.mp4 已有零容差抽帧、cap.ipa 包身份与主程序导入检查、同一样本已有元数据、隔离模拟器演示截图。
- network_profile：本轮未调用真实识别接口；截图使用 Debug 模拟数据，无线上写入。
- 方法：普通应用 UI 复现，flavor=null。没有新获得原版源码，没有运行原版 IPA。
