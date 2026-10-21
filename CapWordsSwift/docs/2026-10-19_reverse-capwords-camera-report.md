# CapWords 相机界面与 IPA 检查报告

日期：2026-10-19。范围为用户提供的相机截图、两份工作区 IPA，以及 `CapWordsSwift` 相机界面。类型为普通应用行为逆向，`flavor = null`。

`cap.ipa` 的版本是 2.0.9（445），主程序 `LC_ENCRYPTION_INFO_64.cryptid=0`，可作静态反编译。另一个 2.0.11（23）主程序 `cryptid=1`，仍加密。Python 解析、`otool` 与 REA Mach-O 检查交叉确认了前者状态。

REA 包体和 Mach-O 检查正常；函数分析返回 `provider_unavailable`，原因是没有配置可用的 Ghidra、Hopper 或 IDA 引擎。本次没有恢复原始 Swift 源码，也没有生成 REA 函数伪代码。相机结构由哈希一致样本的既有 ObjC／Swift 元数据、LLVM 指令及本地化资源支持：AVFoundation 预览与拍照、SwiftUI 取景框和拍摄工具栏状态模型。

界面按用户截图重建白色日期和状态栏、圆角四角框、中文提示、彩色快门、关闭及相册按钮；生成真实模拟器对照图。背景采用不含 UI 的纹理裁片，系统相机指示灯与动态岛需要真机验证。

构建通过；iOS 26.1 与 26.4 的三项现有相机 UI 测试均在 Instruments 连接阶段被阻塞，未取得交互测试通过结果。

[完整 Evidence → Finding → Path、对照图和复现命令](camera-alignment-validation/README.md)；[验证结果](camera-alignment-validation/validation.txt)。证据范围见 [`scope.md`](../../capwords-analysis/evidence/ipa/camera-alignment/scope.md)，时间线见 [`timeline.md`](../../capwords-analysis/evidence/ipa/camera-alignment/timeline.md)。

- [x] 加密标记与主程序哈希已复核。
- [x] REA 调用结果与引擎不可用诊断已保留。
- [x] 导入名称分类摘要已保存为 E-imports。
- [x] UI 已构建并实际运行截图。
- [x] 未将静态证据、截图或被阻塞的测试描述为完整真机行为验证。
