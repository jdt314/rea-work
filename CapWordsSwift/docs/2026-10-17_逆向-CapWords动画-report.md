# CapWords 动画与词库布局对齐

本轮已实现主体 alpha 驱动的背景粒子、轮廓流光、等待波纹、结果呼吸光，以及读取实际词库位置的保存飞回。真机逐帧验收尚未完成；新版 TabBar 的精确外观仍缺运行证据。报告采用普通逆向模板，flavor=null。

## 范围

用户授权研究本地 `cap.ipa`，并修改 `CapWordsSwift`。仅本地静态 IPA 检查、源码修改和本地构建／测试；未调用原版识别接口，也未执行原版应用。本轮复用既有官网视频抽帧。日期按会话 America/Los_Angeles 记为 2026-10-17；主机日志为 2026-10-18。

## Evidence

| ID | source_ref | repro_command / 离线限制 | content_hash |
| --- | --- | --- | --- |
| E-001 | `cap.ipa`；REA 父记录 `ev_6c658e68d2ac4a7de478ae226e963069f7d98602912d38ef58d08feedbe8e2ec`；摘要 `ev_b9a993d7b834367ffd314a39b92df1060c8fee0adc9ccf60167224c14ba1878c` | REA `open_binary` 指向项目根 `cap.ipa`，再 `inspect_artifact`；依赖同版本 REA 会话 | c6cc5aba8194c044fea2f7df1c92c290fb58502a90fdb5afd3df9522c9f61fe8 |
| E-002 | `../../capwords-analysis/VIDEO-VALIDATION.md` 和 `evidence/video/m2/detail-donut/` | 既有抽帧为请求 seek 时间，未认证为源帧 PTS；保留原视频范围限制 | n/a，关联视频身份见该报告 |
| E-003 | `animation-evidence/build.log` | 项目根运行 `bash CapWordsSwift/scripts/verify.sh` | n/a，构建日志 |
| E-004 | 本轮 Xcode 设备检查与签名查询 | `DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer xcrun devicectl list devices`；`security find-identity -v -p codesigning` | n/a，命令输出 |

E-001 的静态字符串包括 BasicTabbarView (0x183bf38)、BasicTabbarItem (0x183bf78)、LiquideTabbarView (0x183bf90)、StickerLibraryCategorySnapshot (0x1830bb0)、StickerLibraryDailySnapshot (0x1830bd0)、View by category (0x1999f80)。这些是类型和模式线索，不能还原按钮数量、尺寸或动画。依赖信息复用既有 IPA 报告；本轮未新增原生函数反编译或导入表结论。

## Findings

| ID | 结论 | evidence_ids | severity | confidence | location | status |
| --- | --- | --- | --- | --- | --- | --- |
| F-001 | 存在日期／分类快照与不同 TabBar 类型线索；精确 TabBar 外观未知 | E-001 | n/a_re | medium | IPA 上述字符串偏移 | candidate |
| F-002 | 视频支持保留主体、背景消散、结果柔光和保存归位的顺序 | E-002 | n/a_re | medium | 官网视频约 3.1–8 秒 | candidate，沿用抽帧精度限制 |
| F-003 | 当前主机可见已配对 iPhone 17，但未检测到有效签名身份 | E-004 | n/a_re | medium | Xcode 设备／签名服务 | candidate，不能据此宣称真机验证完成 |

## 实现路径

P-001，path_type=callflow：E-002 → F-002 → `RecognitionService` 输出主体 PNG 和归一化矩形 → `DustSampler` 将主体 alpha 放回原图坐标，排除前景采样 → `PhotoDustView` 在约 0.72 秒内消退背景 → `SubjectEnergyView` 扩张主体 alpha 并扣除内部形成轮廓流光，同时绘制等待波纹／结果呼吸光。粒子为 Canvas 网格实现，不是原版 GPU shader 的逐指令复现。

P-002，path_type=callflow：E-002 → F-002 → 保存成功 → `StickerFlightState.targetID` → 词库清除搜索、切回日期模式并滚动 → GeometryReader 上报目标 artwork 全局 frame → 在相同屏幕坐标中将结果 artwork 飞向实际词库位置 → 交还词库显示。目标布局超时／减少动态效果时直接返回；写入失败不播放成功动画。列表底栏的日期／分类入口为当前复刻设计，E-001 → F-001 不足以证明原版视觉相同。

## 验证与未完成项

首次模拟器通用构建通过。现有 UI 测试存在 `XCUIElement.lastMatch` 编译错误，已修复为明确选择确认 alert 按钮；后续运行结果另见日志与验证记录。

检测到已配对真机，签名查询返回 `0 valid identities found`，未发现本机 provisioning profiles。因此未安装本轮构建到真机，也未生成真机录屏，不能声称完成逐帧对照。需有可用开发签名后录制同一机型完整正常保存、慢识别、取消重拍会话，并按视频阶段而非快门绝对时刻对齐。官网视频与 IPA 可能不同版，底栏不能混同。

## 时间线与检查

2026-10-17：复用既有视频 → REA 检查 IPA 类型与布局线索 → 实施动画和布局坐标共享 → 通用模拟器构建通过 → 修复已有 UI 测试编译问题 → 检查真机签名与模拟器运行条件。

已核对原请求：动画与实际目标位置已编码；分类与底栏已提供可审阅实现但缺原版新版布局实证；真机逐帧验收未完成。未生成恶意样本／攻击链报告，也未把静态字符串写成运行事实。
