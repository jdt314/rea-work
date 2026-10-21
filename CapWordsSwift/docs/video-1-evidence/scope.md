# 本轮范围

- auth：用户要求根据本地 `1.mp4` 并使用 REA 解析 IPA，继续修改 tabbar 和粒子；追加明确 tabbar 使用 iOS 26／27 原生 Liquid Glass。
- in_scope：项目根 `1.mp4`、`cap.ipa`、既有 capwords-analysis 证据、CapWordsSwift 源码及本地构建／模拟器验证。
- network_profile：离线；未调用 CapWords 在线接口，未执行原版 IPA。
- constraints：保留已有未提交工程；不安装额外反编译器、不修改系统 Xcode 选择、不修改用户词库；预览使用内存数据库。
