# CapWords 拍照到识别流程与视频 4 对照

本轮基于 cap.ipa 静态证据与用户提供的 4.mp4，调整了 CapWordsSwift 的拍摄、抠图确认、云端等待和结果揭示。最主要的变化是：图片规范化后即发起 AI 请求，本地分割独立继续；抠图可以先展示，不必等网络返回。用户确认后展开白页，未完成的识别继续等待，已返回的词条也不会跳过用户确认和展示过渡。当前已完成应用编译、39 项核心测试，并提供真实模拟器的演示识别录像；不等同于真实 DeepSeek 服务质量验收。

范围和授权见 [scope.md](video-4-evidence/scope.md)，过程见 [timeline.md](video-4-evidence/timeline.md)。

## 视频观察

原片为 592×1280、14.867 秒，平均约 27.98 fps。概览间隔 0.5 秒，关键区间 2.6–12.6 秒按 0.1 秒抽样；这是关键帧采样，不宣称逐个编码帧全部检查。AVFoundation 零容差提取，实际 PTS 记在 metadata.json。

| 原片时间（约） | 可见行为 | 本轮实现 |
| --- | --- | --- |
| 2.8 秒 | 取景框与快门退场，照片冻结 | 进入本地准备状态，保留当前照片 |
| 3.6–4.4 秒 | 背景化为细粒，主体位置不变，三枚操作按钮出现 | Vision 完成后立即启动纹理粒子，背景归于中性灰 |
| 4.4–6.9 秒 | 主体等待用户确认 | 不因 AI 提前返回而自动跳过确认 |
| 7.0 秒 | 灰底退为黑色，白页从底部展开 | lifting 阶段和 0.50 秒弹簧展开 |
| 7.4–8.9 秒 | 白边主体、彩色点阵、上下悬浮，底部取消 | 展开完成后悬浮；等待实际请求，不硬编码录像中的等待长度 |
| 9.0–9.4 秒 | 黄光先出现，主体缩小上移，词条与按钮随后弹入 | revealing → result，两阶段揭示 |
| 约 12.0–12.5 秒 | 保存后飞回词库 | 沿用真实目标框飞回，补充重复保存防护 |

观察入口：[概览](video-4-evidence/overview/contact-000.jpg)、[抠图阶段](video-4-evidence/transitions/contact-000.jpg)、[确认与展开](video-4-evidence/transitions/contact-001.jpg)、[悬浮与结果](video-4-evidence/transitions/contact-002.jpg)。视频中看不到网络发包与返回时刻，不能把 7.4–8.9 秒直接认定为真实请求耗时。

## Evidence

| ID | source_ref | repro_command / 复现方式 | content_hash |
| --- | --- | --- | --- |
| E-IPA | [REA bundle](../../capwords-analysis/evidence/ipa/video-4-rea.json)，`inspect_artifact` | REA `open_binary` 指向仓库 cap.ipa，随后 `inspect_artifact` | IPA：`c6cc5aba8194c044fea2f7df1c92c290fb58502a90fdb5afd3df9522c9f61fe8` |
| E-imports | [REA imports 分组](../../capwords-analysis/evidence/ipa/video-4/imports.json) | REA 打开主程序并 `inspect_macho`；父证据 `ev_506f60309e9046f89d758128603596418ebb67b2c3787a8462f68348a6c8a552` | 主程序：`6954430ff4342d6f2b9a096245caf1921f3e3503212f438904378548e87b0265` |
| E-state | [43 个动作分派](../../capwords-analysis/evidence/ipa/capture-flow/gaps/action-dispatch.json)、[状态指令](../../capwords-analysis/evidence/ipa/capture-flow/gaps/state-and-timing.txt) | `python3 capwords-analysis/decode_capture_gaps.py`；复核本地静态解析结果 | 同上主程序；[身份核对](../../capwords-analysis/evidence/ipa/video-4/identity.json) |
| E-video | [原片采样元数据](video-4-evidence/transitions/metadata.json) | 下方抽帧命令 | `4.mp4`：`ac8b42510e1ff17566e17629c05cf5653307bede10e7757f240de02b83ba4306` |
| E-provider | [深度分析失败记录](../../capwords-analysis/evidence/ipa/video-4/provider-unavailable.json) | REA `analyze_function`，procedure=`0x1004c4980` | n/a，工具诊断 |
| E-render | [模拟器采样记录](video-4-validation/metadata.json)、[录屏](video-4-validation/slow.mp4) | `capture_recognition_flow.py`，见下方 | 文件校验见 [hashes.json](video-4-validation/hashes.json) |

REA 清单包含 528 个 occurrence。Mach-O 导入信息为非穷尽集合，本轮分组看到 Vision、AVCapture、Core Animation/Metal 与 URLSession；这证明符号依赖，不单独证明运行调用链。函数深度分析因 Ghidra 未配置、Hopper 缺失、IDA 未配置而失败；后续状态结论复用并重新解析已有本地指令证据，不冒充新 REA 反编译。

## Findings 与实现路径

| ID | severity / status | evidence_ids | confidence / location | 结论及落地 |
| --- | --- | --- | --- | --- |
| F-01 | n/a_re / validated | E-state, E-video | high；`0x1004c51d4`、`0x1004c5984` | 词条到达与展示门控独立；本项目用 `CaptureResultGate` 等待确认、白页展开、词条三信号 |
| F-02 | n/a_re / validated | E-video | high；3.6–9.4 秒画面 | 先消散、确认、展开，再悬浮和结果；由 `CaptureFlow` 的独立任务推进 |
| F-03 | n/a_re / validated | E-state | medium；`0x1004c86e4` 等 continuation | 原版可见取消检查；本项目对准备、网络、动画分别取消，并检查拍摄及请求代次 |
| F-04 | n/a_re / validated | E-render | high；本项目白页展开过渡 | 首轮录屏有主体交叉淡化重影；关闭图片内容隐式动画，保留外层尺寸位置动画，悬浮在展开完成后启动 |

P-01，`path_type=callflow`：拍照/相册 → 方向和尺寸规范化 → 发起 DeepSeek 请求，同时执行 Vision 分割 → 主体和背景消散 → 用户确认 → 白页展开 → 等待词条 → 黄光、缩小上移 → 文字按钮揭示 → 用户保存 → 真实词库落点飞回。关联 F-01、F-02、F-03。

P-02，`path_type=callflow`：网络错误 → 保留抠图 → 确认后显示错误 → 用户重试同一张图或手动填写；取消则清除当前流程，旧请求不得回写。此错误界面是本项目实现选择，视频 4 未展示原版失败分支。

## 验证与限制

- 核心测试 39 项通过：原有 30 项、AI 请求 5 项、结果门控 4 项。门控覆盖全部到达顺序、快/慢返回、重复结果与重拍复位。
- 最终 [展开过渡联系表](video-4-validation/final-transition/contact-000.jpg) 的采样帧未再见首轮双主体交叉淡化；[慢返回结果](video-4-validation/slow-13.0.png)、[失败状态](video-4-validation/failure-6.0.png)、[取消后状态](video-4-validation/cancel-14.0.png) 已人工检查。
- iOS 模拟器构建成功。实时渲染验证使用 iPhone 17 Pro / iOS 26.1；快、慢、失败、取消场景通过 Debug 演示参数驱动，并非真实服务调用或 XCTest 触摸自动化。
- 减少动态效果跳过粒子和悬浮，保留短淡入；代码已编译，尚未单独录制该系统设置。
- 保存飞回沿用既有实现，本轮增加重复保存保护；本轮录屏未覆盖自动点击保存。
- 当前 Vision 仍保留所有前景实例；中心实例筛选、复杂透明边缘和原版白边路径不是本次新增内容。模拟演示甜甜圈素材本身清晰度有限，不能用于评价真实图片分割质量。
- 真实 DeepSeek 成功/失败、真机摄像头性能和网络延迟仍需配置密钥后验收。动画参数是根据视频和既有证据选定的实现值，不声称逐像素一致。

## 复现

从仓库根目录执行；需要本机 Xcode 和已启动模拟器：

```bash
export DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer
swift -module-cache-path /tmp/capwords-video-module-cache CapWordsSwift/scripts/extract_video_evidence.swift 4.mp4 CapWordsSwift/docs/video-4-evidence/transitions 0.1 2.6 12.6
python3 capwords-analysis/decode_capture_gaps.py
bash CapWordsSwift/scripts/verify.sh
CAPWORDS_SIMULATOR_ID=4607AA88-3821-4245-91AA-A1E6B8E407E4 python3 CapWordsSwift/scripts/capture_recognition_flow.py
```

从 `CapWordsSwift` 目录运行 `swift test --scratch-path /tmp/capwords-startup-core`。录像的时间是模拟器启动请求后的时间，受启动和截图开销影响；截图真实完成时间保存在 metadata，不把文件名当作精确帧时刻。
