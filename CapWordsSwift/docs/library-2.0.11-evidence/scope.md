# 分析范围

- auth：用户明确允许“使用 REA 分析最新的 CapWords_2.0.11.ipa”，用于当前 CapWordsSwift 的词库交互复现。
- in_scope：指定 IPA 的版本身份、Mach-O 加密和依赖、中文空态资源、眼睛动画候选；给实现提供可核验线索。
- network_profile：离线读取；未连接 App 服务、未执行目标、未安装或修改 IPA。
- out_of_scope：旧版本代码推断为最新版实现、绕过 FairPlay、声明未观察到的真机触觉参数。
- output：本目录的证据 JSON、可重复运行脚本和报告；App 修改由主代理处理。
