# CapWords 2.0.11：词库下拉进入相机的资源证据

本轮新增确认了包内的下滑提示和一个触觉资源，尚不能从加密主程序恢复“词库顶部下拉进入相机”的阈值、几何变化或弹簧参数。最新版中文资源含 `Swipe down to try` → `下滑试试看`。`Inflate.ahap` 的事件表已由 REA 读取，但其相机转场绑定没有得到证实。实现时应以视频 3 的可见行为确定容器移动、相机显露、圆角和松手回弹，不把通用资源的时间数值当作转场时长。

分析日期：2026-10-19。用户明确要求对指定 IPA 研究词库下拉相机动画。本轮沿用[离线分析范围](../library-2.0.11-evidence/scope.md)，将资源查询聚焦此交互；没有运行目标、连接网络、安装工具或修改 App。报告采用普通逆向结构，`flavor=null`。

## 目标和复用边界

- IPA：`CapWords_2.0.11.ipa`，版本 2.0.11 / build 23。
- IPA SHA256：`61bb75c9a1f6329c9500d00f57bde2e3e09e0e6e6d604fccbad844a8b6ca52fc`。
- 主程序 SHA256：`01983ce0aa4eadea9aa20db9d726a404efb5e31c8f813abf006a26a525e6ffff`。
- 复用[上一轮报告](../library-2.0.11-evidence/2026-10-19_逆向-CapWords词库-report.md)和[原始 REA bundle](../library-2.0.11-evidence/rea-native-bundle.json)中的版本、依赖和加密事实，没有重新执行失败的反编译或大资产目录分析。
- `cryptid=1`，文件偏移 16,384 起 33,832,960 字节被标记加密，覆盖应用逻辑、Swift 类型/字段名及 ObjC 名称区。最新版 `handlePanGesture` 的代码、调用关系和参数仍不可得。

## Evidence → Finding

以下 E-id / F-id 是本报告局部索引。完整新记录在 [rea-camera-resource-bundle.json](rea-camera-resource-bundle.json)，资源摘要及有界搜索结果在 [ipa-camera-resources.json](ipa-camera-resources.json)。

| E-id | source_ref | content_hash / 复现 |
|---|---|---|
| E-localization | REA `ev_c60afb915b30890558a3eae2862d086044f8252a91393614834ee561f7227d0e`；最新版中文 Localizable.strings | SHA256 `4b710d5b586f30be873da50f6ca568977ec72532d95c82b8afd17f941217e790`；复用原始 bundle 的 normalized_result.value |
| E-haptic | 新 REA `ev_46764bbb3891ce299872eda8618b86802ce3fde548abf02eea99fe0b8bd7bd3c`；`Payload/SnapWords.app/Inflate.ahap` | 1,743 字节；SHA256 `32d505eed04c6332689b8a39a4680bac6fc3e45c658717791e18d61ee7733c4d`；REA `inspect_plist` 指定此资源路径 |
| E-inventory | `ipa-camera-resources.json`；读取 IPA ZIP 成员 | 同上 IPA SHA256；枚举 `.ahap` / `.pag` / `.riv` 文件，并在中文 key/value 内匹配 `pull/swipe/camera/下拉/相机/拍摄` |
| E-imports | 复用 REA `ev_bf530b9cf224981cb503ed4ead618e93f1daaa416bfbbe7083d4744070a8c39d` | 同上主程序 SHA256；Mach-O 依赖包含 UIKit、SwiftUI、QuartzCore、CoreHaptics、libpag、RiveRuntime、Lottie；导入列表返回 0 且 non-exhaustive，不能声称没有导入 |

| F-id | 发现 | severity / confidence / status | evidence_ids / location |
|---|---|---|---|
| F-down-hint | 最新资源确有“下滑试试看”；不能只由本地化键判定它在哪个页面显示 | n/a_re / high（文本），low（页面绑定）/ candidate | E-localization；中文资源 |
| F-camera-hint | 存在“打开相机”“打开 CapWords 相机”“快速打开 CapWords 相机页面”等文案；没有从这组匹配中读到转场参数 | n/a_re / high（文本）/ candidate | E-localization；中文资源 |
| F-haptic | 存在下述连续/瞬态触觉事件与控制曲线；调用页面、触发条件和是否运行均未知 | n/a_re / high（文件内容），low（转场绑定）/ candidate | E-haptic；Inflate.ahap |
| F-logo | `snaplogo.pag` 存在，1,915 字节，SHA256 `babc19797bade00da870393c7653471c0d1e0c57be4333f51fd25e440bc5e139`；本轮未渲染，不能认定它就是下拉过程中的快门动画 | n/a_re / high（存在），low（绑定）/ candidate | E-inventory；bundle 根目录 |

`Inflate.ahap` 的原始参数：

| 时间（秒） | 项目 | 数值 |
|---|---|---|
| 0 | HapticContinuous | duration `0.4997617558070583`，intensity `1`，sharpness `0.93` |
| 0.5564284406389501 | HapticTransient | intensity `1`，sharpness `1` |
| 0 → 1.7 | HapticSharpnessControl | `-0.8 → 0.8` |
| 0 → 1.1 → 1.7 | HapticIntensityControl | `0.1896663 → 0.5 → 0` |

控制曲线延伸到 1.7 秒不等于存在一个持续 1.7 秒的触觉事件，更不等于相机转场为 1.7 秒。普通录屏也不能验证触觉强度。

## 明确标注的旧版辅助

仓库中的 `cap.ipa` 是 **2.0.9 / build 445 重打包样本**，主程序 SHA256 为 `6954430ff4342d6f2b9a096245caf1921f3e3503212f438904378548e87b0265`，含注入痕迹，不能视为当前官方代码。其既有[类型元数据](../../../capwords-analysis/evidence/ipa/home-defaults/swift-types.json)在 `SnapWords.StickerCollectionViewController` 中保留了 `panGesture`、`beginOffset`、`initialTouchPoint`、`originalPosition`、`containerTopConstraint`、`collectionTopConstraint`、`cameraBarHeightConstraint`、`maxCornerRadius`、`maxDragThreshold`。

这些旧版字段只能帮助选择视频观测重点：容器位置、相机区域高度、圆角和手势提交阈值。它们没有给出最新版常量、计算式或完整调用链，本轮没有迁移旧版地址，也没有用结果页的 spring 参数冒充词库→相机参数。

## 可回答的范围与后续实施依据

| 问题 | 状态 |
|---|---|
| 新版本是否包含下滑提示 | 已确认文本存在；具体显示页面未知 |
| 是否有相关动画/触觉资源候选 | 已确认存在；页面绑定未知 |
| 下拉中背景相机何时显露、词库如何移动/缩放、圆角如何变化 | IPA 未恢复；由视频 3 测量 |
| 提交阈值、取消阈值、速度权重、动画弹簧及完成时机 | IPA 未恢复；实现参数应标为视频拟合选择 |
| 是否先预热相机、何时开始预览 | IPA 未恢复；录屏只能观察预览出现，不能证明底层会话生命周期 |

P-camera，`path_type=solve`：复用版本与加密证据 → 有界查询本地化（E-localization → F-down-hint）→ 枚举小型动画资源（E-inventory → F-logo）→ REA 读取触觉资源（E-haptic → F-haptic）→ 将动态几何与时序交由视频 3 观测。这是调查路径，不是已恢复的 App 调用链。

本轮关键时间线（同日，按顺序）：读取已保存的最新版证据；发现下滑提示与 Inflate.ahap；为指定目标临时打开 REA 原生会话并读取 AHAP；导出新记录；关闭会话并写入本说明。

复现新 REA 读取时，先 `open_binary` 指向指定 IPA 解包目录中的 `Payload/SnapWords.app/SnapWords`，再以 `inspect_plist({"path":"解包绝对路径/Payload/SnapWords.app/Inflate.ahap"})` 读取。路径随解包目录变化；现有 bundle 已完整保留本轮实际调用路径与返回值，无需为阅读记录重新分析。
