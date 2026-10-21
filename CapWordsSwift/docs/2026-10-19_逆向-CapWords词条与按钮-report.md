# CapWords 词条、确认按钮与原生玻璃

本轮以用户指定的 `4.mp4` 为布局依据，并用 REA 检查 `cap.ipa` 及其主程序。原版包确实导入文字描边、alpha 阈值和 SwiftUI 原生玻璃相关 API；已有同一主程序的元数据包含带 `strokeSize` 的词条视图。源码重建采用文字 alpha 白边、独立中文行、按全屏尺寸校准的操作按钮和原生透明玻璃。模拟器布局与文字检查通过，真实识别接口和原版函数内部调用链仍未验证。

授权与范围见 [scope.md](result-alignment-validation/scope.md)。类型为普通应用 UI 复现，flavor=null。

## Evidence

| ID | source_ref | repro_command / 方法 | content_hash |
| --- | --- | --- | --- |
| E-video | [4.mp4 10 秒帧](video-4-evidence/overview/t0010000.jpg)、5.5 秒帧、已有 `metadata.json` | 仓库 `extract_video_evidence.swift`，使用 AVFoundation 零容差抽帧；实际 PTS 见元数据 | 视频 SHA-256：`ac8b42510e1ff17566e17629c05cf5653307bede10e7757f240de02b83ba4306` |
| E-package | [rea-package.json](result-alignment-validation/rea-package.json) | REA `open_binary(cap.ipa)` → `inspect_artifact(detail: summary)` | `c6cc5aba8194c044fea2f7df1c92c290fb58502a90fdb5afd3df9522c9f61fe8` |
| E-imports | [rea-imports.json](result-alignment-validation/rea-imports.json)，`ev_08bad7c6655acd8698acb221c1a32fc6ff254bd7209925d4addd16b434c07be4` | 打开包内同一主程序 → `inspect_macho` → imports view；导入结果非穷尽 | 主程序：`6954430ff4342d6f2b9a096245caf1921f3e3503212f438904378548e87b0265` |
| E-type | [word-outline-metadata.json](result-alignment-validation/word-outline-metadata.json) | 对照既有 `capture-flow/swift-types.json`，重新验证其样本主程序与 IPA 成员 SHA-256 一致 | 原始文件哈希见 JSON；不是本轮新反编译 |
| E-provider | [rea-provider.json](result-alignment-validation/rea-provider.json) | REA `analyze_function(0x1004c4980)` 返回 `provider_unavailable` | n/a，工具诊断 |
| E-render | [截图和验证记录](result-alignment-validation/README.md) | 截图脚本、像素连通区域测量、Vision OCR | 文件哈希见 `result-alignment-validation/hashes.json` |

## Findings

| ID | severity / status | evidence_ids | confidence / location | 结论 |
| --- | --- | --- | --- | --- |
| F-01 | n/a_re / validated | E-video, E-render | high；视频最终结果与本项目按钮 | 结果按钮应比抠图确认小，左右分散。现改为60/80/60 pt，中心 x=0.226/0.5/0.774、y=0.537；抠图确认主按钮100 pt、y=0.902。测量已由修改前失败转为通过。 |
| F-02 | n/a_re / validated | E-type, E-imports, E-video | high（元数据与导入）；`StickerOutlinedTargetWordView`、descriptor `0x101bf1128` | 原版元数据含 text、annotatedText、lineLimit、strokeSize；导入含 NSStrokeWidthAttributeName、TextRenderer、alphaThreshold。可确认有文字描边能力，不能断言这几种 API 全部用于同一视图。 |
| F-03 | n/a_re / validated | E-imports, E-render | high；原版导入及 `CameraGlass` | 原版导入 glassEffect、Glass.clear、Glass.interactive 等。重建相机关闭与相册使用系统玻璃，实际截图呈透明折射效果。 |
| F-04 | n/a_re / validated | E-render | high；`CaptureView.resultCaption` | 当前实现英文/中文独立排版，长词完整换行，轮廓从排版后的 alpha 生成。5 个场景的 OCR 能读取中文，且中文没有与三按钮相交。 |
| F-05 | n/a_re / candidate | E-render | medium；用户真实识别个例 | 本地旧版示例截图已有中文，无法证明用户个例由数据或布局哪一方单独引起。本轮移除负行距压叠、提高中文字号、补充空中文入口，并验证解码器拒绝空中文成功响应。尚无真实接口响应可复现用户的缺失个例。 |

## Path 与实现

P-01，`path_type=callflow`：识别结果包含 name/meaning → 确认与过渡门控 → 按目标语言和中文分别排版 → Canvas 对排版结果生成白色轮廓 → 字面绘于白边上 → 朗读按钮独立叠放 → 确认保存前校验中英文非空。关联 F-02、F-04、F-05。

P-02，`path_type=callflow`：取景 → 50 pt 相机辅助控件应用系统玻璃 → 抠图确认区100 pt主按钮 → 结果揭示后切换60/80/60 pt三按钮；全屏坐标减去安全区顶部偏移后定位。关联 F-01、F-03。

`StickerLabel` 也复用字形白边，使词库标签随文字与换行变化。`RoundButton` 支持独立符号尺寸，重拍符号按视频绘制；其余调用方保留默认参数。裁剪和完整场景仍可在“点击调整”长按菜单访问。

## 验证与边界

应用与测试产物编译成功，39 个核心测试通过。7 个真实模拟器截图中，5 个结果场景通过按钮几何与 OCR 检查。使用的识别数据是 Debug fixture；短词与长词测试没有更换甜甜圈素材，因此不是识别准确率测试。按钮比例依据视频测量，字体、主体图、玻璃折射背景等不构成原版逐像素一致声明。

REA 当前没有可用的 Ghidra、Hopper、IDA 深度分析引擎；本轮没有获得函数伪代码。已有元数据和导入事实已与推断分开记录。用户原始在线识别缺失中文的个例、真机摄像头、相册触摸、保存飞回及旧系统材质未在本轮实际操作验证。

## Timeline

- 2026-10-19：读取用户提供视频的已有关键帧，启动旧构建，保存 before 截图；按钮测量失败。
- 同日：REA 核对包、主程序、导入；确认深度分析 provider 不可用，保留诊断。
- 同日：改中文和白边布局、原生玻璃、按钮尺寸位置；第一轮截图揭示长词与朗读位置问题，进一步修正。
- 同日：最终7场景截图，5场景几何和 OCR 通过，39核心测试通过，构建产物通过。

可直接运行的复现命令见[验收记录](result-alignment-validation/README.md)。
