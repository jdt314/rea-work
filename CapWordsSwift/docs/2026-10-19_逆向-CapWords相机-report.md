# CapWords 相机界面与 IPA 静态分析报告

分析日期：2026-10-19。范围：[scope.md](../../capwords-analysis/evidence/ipa/camera-alignment/scope.md)。工具：REA、系统 otool、Python、已保留的 LLVM ARM64 反汇编。

**`cap.ipa`（2.0.9，445）主程序未处于 FairPlay 加密状态，可以继续静态分析相机实现。** `CapWords_2.0.11.ipa`（2.0.11，23）主程序仍标记加密，不能把两份包混为一谈。本轮 REA 已检查主程序结构，但函数查询受反编译 provider 缺失阻塞；以下相机细节来自经哈希核对的 LLVM 指令、Swift/ObjC 元数据及包内本地化资源，不宣称 REA 已恢复 Swift 源码。

## 1. 加密结论与样本身份

| 样本 | 版本 / Build | cryptid | cryptoff / cryptsize | 结论 |
| --- | --- | --- | --- | --- |
| `cap.ipa` | 2.0.9 / 445 | 0 | 102400 / 4096 | 主程序没有活动的加密区，可读指令 |
| `CapWords_2.0.11.ipa` | 2.0.11 / 23 | 1 | 16384 / 33832960 | 主程序仍有加密标记，相关代码区无法直接可靠反汇编 |

`cryptsize` 非零不等于仍加密，必须结合 `cryptid` 判断；这里检查的是主程序 Mach-O，不是 ZIP 是否需要密码，也不能用 Info.plist 的出口加密声明代替判断。

| 文件 | SHA-256 |
| --- | --- |
| `cap.ipa` | `c6cc5aba8194c044fea2f7df1c92c290fb58502a90fdb5afd3df9522c9f61fe8` |
| `cap.ipa` 主程序 | `6954430ff4342d6f2b9a096245caf1921f3e3503212f438904378548e87b0265` |
| `CapWords_2.0.11.ipa` | `61bb75c9a1f6329c9500d00f57bde2e3e09e0e6e6d604fccbad844a8b6ca52fc` |
| `CapWords_2.0.11.ipa` 主程序 | `01983ce0aa4eadea9aa20db9d726a404efb5e31c8f813abf006a26a525e6ffff` |

2.0.9 主程序与既有 `capwords-analysis/evidence/ipa/SnapWords` 逐字节一致，因此既有相机反汇编可复用。依赖包含 AVFoundation、SwiftUI、UIKit、Vision、QuartzCore、Metal；2.0.9 另含 `sideloadKeychainfix`、`StopReviews` 等注入库依赖，有重打包迹象。本报告结论限定于上述哈希样本，不保证与当前商店包完全相同。

## 2. REA 已做到什么

本轮 [REA 证据包](../../capwords-analysis/evidence/ipa/camera-alignment/rea-evidence.json) 包含 5 条记录，其中直接主程序检查为：

- `inspect_artifact`：`ev_6c658e68d2ac4a7de478ae226e963069f7d98602912d38ef58d08feedbe8e2ec`。
- `inspect_macho`：`ev_506f60309e9046f89d758128603596418ebb67b2c3787a8462f68348a6c8a552`。
- 摘要投影：`ev_eb3376809c54381adafe56853297abc89d41fbddfc090c2a8c10f6c6f87fe234`。

`search_procedures` 返回 `provider_unavailable`：Ghidra 未配置，Hopper 不存在，IDA 未配置。因此当前可以用 REA 检查包、Mach-O、依赖和现有证据；**当前环境尚不能通过 REA 查看已反编译的相机函数伪代码**。没有安装额外工具或修改 provider 配置。即使补齐引擎，优化后的 Swift 通常只能恢复近似控制流，不能保证还原原工程源码、注释或所有变量名。

## 3. 可确认的相机实现

下列地址都是 2.0.9 的静态虚拟地址，真机运行时需要考虑 ASLR。

| 组件 / 行为 | 静态位置 | 直接证据 |
| --- | --- | --- |
| 底层相机 | `CameraViewController` | 持有 captureSession、photoOutput、movieOutput、previewLayer、sessionController |
| 预览填充 | `0x10045ef00` → `0x10045ef0c` | `AVLayerVideoGravityResizeAspectFill` 传给 `setVideoGravity:` |
| 照片采集 | `capturePhoto`：`0x1004622f8`；硬件调用：`0x100462b24` | `capturePhotoWithOutput:settings:delegate:` |
| 完成回调 | `0x1004643c0`；数据读取：`0x1004641cc` | `captureOutput:didFinishProcessingPhoto:error:` 与 `fileDataRepresentation` |
| 上层协调 | `StickerCameraViewController` | 管理 cameraCaptureViewController、cropViewController、boundsView、识别任务和展示状态 |
| 点击 / 双击 / 捏合 | `0x100475ed4` / `0x100475f28` / `0x1004763cc` | 对应 handleTap、handleDoubleTap、handlePinch 入口及相关手势字段 |
| 取景框承载层 | `StickerCameraBoundsView`，构建入口 `0x10046d4b8` | `0x10046d6dc` 创建 UIHostingController；`0x10046d734` / `0x10046d74c` 设置透明背景 |
| 照片取景框 | `0x1004698a8` → `0x100469900` | `Image("camera.bounds.new")`，使用 stretch 方式 resizable |
| 取景提示 | `0x10046b39c` → `0x10046b4c0` | NSLocalizedString → Text → 18pt regular system font → white |

包内相机框的类名是 `StickerCameraBoundsView`；本轮没有找到原包名为 `CameraFrameView` 的对应类型。该框是带资源图像的 SwiftUI 内容，不能仅凭当前重建工程的四角 Path 推断原版也是同样的绘图实现。

提示键为 `Please place the object\nwithin the frame`，简体中文资源实际值为 **“请将物体置于框内”**，与用户截图一致。相框还有独立的 `_showCameraFrame`、`_opacityCameraFrame`、`_showFocusIndicator`、`_zoomFactor`、`_showZoomHUD`、`_bottomObstructionHeight` 等状态。

### 取景框尺寸与底部提示

`0x1004691a0` 读取 GeometryProxy 的尺寸与一个 Published 高度值，然后执行以下计算。这是该分支的等价运算说明，不是恢复出的原 Swift 源码：

```text
base = min(max(containerHeight - publishedHeight, 0), containerWidth)
frameWidth = base * 0.8
frameHeight = frameWidth * 420 / 340
tipBottomPadding = frameWidth * 0.03
```

宽度系数位于 `0x100469238`；420 与 340 的双精度常量及运算位于 `0x100469240` 至 `0x10046925c`；提示底部 padding 位于 `0x1004699d8` / `0x1004699dc`。Published 高度值的字段映射尚未完整闭合，不能只凭邻近字段名断言它必然是 `_bottomObstructionHeight`。

框高宽比约 1.235，与截图约 300/244 的比例接近；但截图框宽约占图宽 87%，该旧包分支宽度系数是 80%。截图版本、外层容器或缩放状态尚未知，**视觉对齐以用户截图为准**，不把旧版本静态常量当作跨版本规范。

### 快门与左右按钮

Swift 元数据确认 `CameraBarContentView` 分别持有 `didTappedHiddenButton`、`didTappedCameraButton`、`didTappedSelectImageButton` 回调，以及左右按钮按下状态和出现动画。`CameraBarState` 的值为：

```text
small, prepareNormalFromSmall, prepareNormalFromCompletion, normal,
capture, prepareLoading, loading, completion, prepareSmall
```

这支持快门在今日页小按钮、展开相机、拍摄、加载及完成之间切换外观；枚举顺序不是完整运行时序。彩色环的完整路径、各段时长、所有按钮尺寸与状态栏颜色切换代码，本轮没有全部恢复。

## 4. Evidence → Finding → Path

| Evidence | source_ref / artifact_path | content_hash | repro_command |
| --- | --- | --- | --- |
| E-001 | [static-camera-review.json](../../capwords-analysis/evidence/ipa/camera-alignment/static-camera-review.json)：样本身份、自有 Mach-O 解析、otool 摘录、元数据与指令摘录 | `48cf2d944bc95b10a3bad78fa71d683808de78d7505a38494151fa56aec91342` | `python3 capwords-analysis/verify_camera_alignment.py` |
| E-002 | [rea-evidence.json](../../capwords-analysis/evidence/ipa/camera-alignment/rea-evidence.json)：REA 原生检查与投影 | `2bdb440468d08730b57c6f1fd53f013b6769e92c1850ad1832514cb454fe0918` | 在 REA 中以 cap-main 为当前主程序执行 `inspect_macho`；离线复核可读取已导出 JSON，重新生成需要同版本 REA provider |
| E-003 | [ObjC 元数据](../../capwords-analysis/evidence/ipa/capture-flow/objc-classes.json)、[Swift 元数据](../../capwords-analysis/evidence/ipa/capture-flow/swift-types.json)、[LLVM 指令](../../capwords-analysis/evidence/ipa/capture-flow/annotated-capture-disassembly.txt)、[简体中文资源](../../capwords-analysis/evidence/ipa/features/Payload_SnapWords.app_zh-Hans.lproj_Localizable.strings.json) | 各源文件完整 SHA-256 见 E-001 的 `source_sha256` | `python3 capwords-analysis/probe_capture.py 0x1004691a0 0x1004692bc`；本轮源文件哈希由 E-001 重算 |

所有证据 observed_at 为 2026-10-19；来源为文件与静态命令，没有原版运行时内存、抓包或设备拍照证据。

| Finding | severity / category | evidence_ids | location | status / confidence |
| --- | --- | --- | --- | --- |
| F-001：2.0.9 主程序 cryptid=0，2.0.11 主程序 cryptid=1 | n/a_re / other | E-001、E-002 | 两份主程序 LC_ENCRYPTION_INFO_64 | validated / high；自有解析与 otool 交叉确认，限主程序 |
| F-002：相机使用 aspect-fill 预览，SwiftUI 透明承载层与相框图像资源 | n/a_re / design | E-001、E-003 | CameraViewController、StickerCameraBoundsView | candidate / high；静态确认，未动态验收原版 |
| F-003：提示为 18pt regular 白字，中文为“请将物体置于框内” | n/a_re / design | E-001、E-003 | `0x10046b39c` 至 `0x10046b4c0`、zh-Hans 本地化 | validated / high；代码与独立资源交叉确认，最终动态缩放仍未知 |
| F-004：原版 UI 存在分阶段快门状态和独立按钮回调 | n/a_re / design | E-001、E-003 | CameraBarState、CameraBarContentView | candidate / high；元数据确认，完整状态转移未闭合 |

**P-001，path_type=callflow：相机预览至照片数据。** 起点是 CameraViewController 预览配置，目标是拿到照片数据供上层使用。

1. 创建相机会话与预览层并设为 aspect-fill（E-001 / E-003，F-002）。
2. 上层承载透明 SwiftUI 取景框，显示相框资源与本地化提示（E-001 / E-003，F-002 / F-003）。
3. `capturePhoto` 入口通过拍照封装发送 AVFoundation 拍摄请求（E-001 / E-003）。
4. 照片处理完成代理读取 `fileDataRepresentation` 并交由上层处理（E-001 / E-003）。

residual_risks：这里只列直接定位的主干节点，按钮闭包到所有拍摄模式的映射、异步队列细节、失败重试与设备实际时序没有全部恢复。既有抠图及识别研究见 [CAPTURE-FLOW.md](../../capwords-analysis/CAPTURE-FLOW.md) 与 [CAPTURE-GAPS.md](../../capwords-analysis/CAPTURE-GAPS.md)。

## 5. 复现与验收边界

在仓库根目录运行以下命令，输出应与 E-001 一致。脚本只读取包与现有证据，不执行原 App，不修改原始证据。

```bash
python3 capwords-analysis/verify_camera_alignment.py
python3 capwords-analysis/probe_capture.py 0x1004691a0 0x1004692bc
python3 capwords-analysis/probe_capture.py 0x10046b398 0x10046b4c4
```

脚本已成功运行，并验证两份提取主程序与各自 IPA 内容一致。**静态分析不能替代真机触摸、权限弹窗、实际拍摄、保存、震感或动画时长验收。** Swift UI 对齐和构建验收由本次 UI 修改的独立验证记录提供，本报告只确认原包实现证据。

时间线：[timeline.md](../../capwords-analysis/evidence/ipa/camera-alignment/timeline.md)。
