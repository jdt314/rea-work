# 启动衔接修复范围

- case_id: capwords-launch-handoff-2026-10-19
- auth: 用户在已有 IPA／视频研究后要求“开始修改”“继续”，并明确指出系统启动结束到动画之间闪现首页；本轮包含当前 Swift 工程的实现修复与本地验证。
- in_scope: 复用 `cap.ipa`、`1.mp4` 的启动资源证据；修改本地启动 storyboard、图片、窗口衔接、测试和说明；在开发模拟器运行隔离测试场景。
- out_of_scope: 执行原版 IPA、访问原版后端、购买／订阅绕过、清空正常词库、卸载应用、重置模拟器、改变全局系统服务。
- network_profile: offline；仅本地 Xcode／模拟器与保存的 REA 证据。
- report_flavor: null；普通应用界面复核，不是漏洞或恶意软件任务。
- limitations: 未进行原版 IPA 真机动态验证；录像为模拟器可变帧率，不等同于真机性能测试；XCTest 服务故障独立记录。

此前纯研究授权与样本哈希见 [2026-10-18 scope](../../../capwords-analysis/evidence/ipa/startup/scope.md)；该旧 scope 不覆盖实现，本文件单独记录后续修改授权。
