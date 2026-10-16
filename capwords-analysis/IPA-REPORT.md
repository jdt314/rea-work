# CapWords cap.ipa 静态分析

日期：2026-10-16。此报告补充并修正 REPORT.md 中仅依据官网的判断。

## 目标身份与边界

- IPA SHA-256：`c6cc5aba8194c044fea2f7df1c92c290fb58502a90fdb5afd3df9522c9f61fe8`。
- Info.plist 声明 CapWords 2.0.9，build 445，bundle ID `com.HappyPlanTech.SnapWords`，最低 iOS 17.0。
- 主程序：`Payload/SnapWords.app/SnapWords`，ARM64 Mach-O，35,766,272 字节。SHA-256：`6954430ff4342d6f2b9a096245caf1921f3e3503212f438904378548e87b0265`。
- `LC_ENCRYPTION_INFO_64.cryptid=0`。同时存在 DecryptedBy 字段、CydiaSubstrate、StopReviews、sideloadKeychainfix、zxPluginsInject 等重打包／注入痕迹。不能认定这是未经修改的官方发布包；版本、代码和配置都只能归属于本样本，不能无条件外推至官方当前版本。
- 未执行 App、未调用其在线接口、未使用包内凭据。未获得运行请求或服务器代码。

## REA 实际使用情况

本次发现本地 npm 缓存已有 rea-agents 6.5.0，直接通过其公开 scripts/rea.mjs CLI 使用，未修改客户端配置。

已完成 REA inspect-artifact 与 project-apple-application-graph，完整响应保存在 evidence/ipa/rea-artifact.json、rea-apple-graph.json。

- inspect-artifact Evidence：`ev_4c3e39eaddf0aeb8ce08b45caa702fb40b984194f8641d9c1668cf0cad6ce053`。
- 内嵌 inventory Evidence：`ev_3c72b145d1531797eaf063971824a6cf8a350af28ba237bcf11b1aa4e5412617`。
- manifest：`agm_6ac1b7f80c4aff7a8c5ce2293b2928b140475db3d96813008fa3fe6e04c15ac6`。

REA providers 表明原生 macOS inspection 在 Windows 不可用，Ghidra 未配置，Windows Ghidra P0 也不支持本目标 ARM64 Mach-O。因而进一步使用现有 LLVM 工具及 Python 对 Mach-O 原始字节、导入、chained fixups、Objective-C selector stub 和 ARM64 指令作静态交叉验证。这部分是普通工具证据，不冒充 REA 反编译结果。没有生成高级语言伪代码。LLVM 全量反汇编出现若干 invalid instruction encoding 警告，不能宣称全文件指令覆盖完整。

## 一、抠图已经定位到具体 API

结论：本样本主程序中存在使用 Apple Vision 前景实例蒙版的可执行代码，不再只是根据官网猜测 VisionKit。

关键链条：

1. 在 `0x10056aafc`，加载 classref `0x101f2f4f8`；其 chained import ordinal 对应 `_OBJC_CLASS_$_VNGenerateForegroundInstanceMaskRequest`，随后分配并初始化对象。
2. 在 `0x10056ab38` 加载 `VNImageRequestHandler`，通过 `initWithCGImage:options:` 构造请求处理器。
3. 在 `0x10056ac2c` 调用 selector stub `0x10179e980`，解析为 `performRequests:error:`。
4. 后续将结果作为 `VNInstanceMaskObservation` 处理。
5. 在 `0x10056ae60` 与 `0x10056aec8` 调用 `generateMaskedImageOfInstances:fromRequestHandler:croppedToInstancesExtent:error:`。前者 `w4=0`，后者 `w4=1`，即代码路径分别生成不裁切和按实例范围裁切的图像。
6. 在 `0x10056af2c` 调用 `generateScaledMaskForImageForInstances:fromRequestHandler:error:`，得到与输入图像匹配的蒙版。
7. 还存在 `allInstances` 调用和实例 IndexSet 处理。是否最终选取一个还是多个实例取决于前置分支，本次未完全恢复选择规则，不能简单宣称固定“只取中心物体”。

原理：系统分割模型产生实例标签／蒙版，应用选择实例集合，提取透明前景，并同时保留裁切版、未裁切版及蒙版，供显示和后续处理。包成员文件名清单中未发现 .mlmodel/.mlmodelc/.mlpackage/.onnx/.tflite 常见独立模型产物；这与调用系统 Vision 的证据一致，但不能排除隐藏、打包或下载模型。

证据：vision-references.json、vision-code-xrefs.json、objc-stub-selectors.json、vision-core-disassembly.txt、macho-headers.txt。地址为本样本静态虚拟地址，非运行时 ASLR 地址。

## 二、边缘和贴纸描边另有处理链

主程序包含 VisionManager、StickerCutoutOutlineView、StickerCutoutOutlineImageView 等类型名，以及 visionSubjectExtraction、visionEdgeExtraction、outlineRendering 分阶段计时标签。

在 `0x100568540` 加载并创建 `VNDetectContoursRequest`。同一代码片段随后：

- 设置 `contrastAdjustment=2.0`；
- 设置 `detectsDarkOnLight=false`；
- 设置 `maximumImageDimension=512`。

这些值由寄存器赋值与 Objective-C stub selector 解码共同确认。还导入了 `VNContour.normalizedPoints`，存在 `normalizedPath` selector，支持“前景提取后再检测轮廓并绘制贴纸外观”的解释。

但未完全恢复轮廓的输入图构造、路径简化、描边宽度、缩放及动画参数。上一份报告的“蒙版膨胀画白边”只是通用复现方案，不能当成本样本的真实实现；本次找到的直接证据是轮廓检测路线。

## 三、图片识别存在应用后端，不是纯本地识别

主程序代码引用以下地址和路径：

- `https://app-api.zenshine.app`
- `https://app-api.dtdstudio.com`
- `/api/v1/generate/cap-words`
- `/api/v1/generate/common`
- `/api/v1/device/register`
- `/api/v1/device/refresh`

相邻服务和事件标识包含 BackendAIChatService、BackendAuthenticatedRequestFactory、BackendDeviceAuth、backend.request_started、backend.server_fallback、backend.model_fallback、backend.sticky_route_used。

二进制还包含 `google/gemini-3-flash`、`openai/gpt-4o-mini` 模型字符串，以及 image_url、video_url、data:image/jpeg;base64,、temperature、max_tokens、response_format 请求字段。

这证明本样本内置应用后端通信、模型配置和回退相关实现；不支持继续沿用官网旧说法“没有服务器”。不过，未抓包就不能确定实际运行选哪个域名、哪个模型、是否受远端配置覆盖，也不能仅凭域名证明服务器归属或实际托管主体。GPT-4o-mini 是否负责识图、对话或特定回退仍需逐条追踪调用分支。

## 四、从包内还原出的识别策略

UTF-8 C 字符串保留了相当完整的中文提示词，已提取至 recognition-prompts.txt。不是凭功能猜测 Prompt。

### 第一阶段：图片语义与双语词条

提示词要求先确定 semantic identity，再生成双语词条。主体可为 object、scene 或视频 action。输出包括：

- words、phonetics、descriptions：使用 key/value 数组，而不是语言字典。
- semanticIdentity：canonicalGloss、visualEvidence，并可含 ambiguityNotes。
- category。
- 日语词条附 wordLearningAids。
- audited 方案还要求 auditSignals：语义、词汇、语法、发音、品牌相关置信度，以及 needsReview、riskTypes、entryKind 等。

这不是“识别英文名后简单翻译”。提示词明确要求 current 与 target 始终对应同一个物体语义，结合包装文字、容器／内容物、使用环境消歧；普通词条不应混入品牌和包装文案。

### 第二阶段：条件触发的文本复核

提示词说明 auditSignals 用于客户端决定是否进入第二轮文本复核；任一相应置信度 <=0.90 或指定风险应触发复核。这里只确认 Prompt 合同，尚未完全恢复客户端实现中的所有阈值和分支。

Stage2 候选输出包含 candidateChecklist、status、wordPhoneticPatch、repairedChecklist。它主要修正 word、phonetic 和日语注音，不允许随意修改 semanticIdentity、descriptions、category。还有本地词典读音候选、冠词语法、冗长词条、品牌泄漏的审计及程序化修复线索。

包内同时有 Recognition V1、singlePassAuditedRecognitionWithSignalsPrompt、Stage2 等路径，说明不能把每次识别固定描述成“两次 AI 调用”。哪种配方启用、第二次是否触发需要运行证据。

### 例句是另一套生成任务

包内 Prompt 要求 current／target 各生成三句、逐句语义对应，覆盖使用动作、请求提供、寻找携带购买等不同交际功能，并强调“不是给图片写说明”。这解释了为什么词卡例句可以超出照片场景，同时通过 semanticAnchor 防止换词义。

## 五、端到端处理与降级

结合已定位的系统调用、提示词和计时事件，可以提出以下静态重建：

照片方向修正 → Vision 主体分割 → 前景／蒙版生成 → 轮廓检测与贴纸绘制 → 向 AI 提交图像 → 解码与审计词汇结果 → 必要时文字复核／修复 → 编码并保存词卡。

其中先后和分支的部分关系由计时标签支持，尚未完整验证异步任务是否并行。`stickerToSceneFallback`、`sticker.scene_fallback_started` 和独立 sceneImageResize／sceneImageRendering 标签支持“主体贴纸失败时存在整图场景回退”的推断；具体触发条件未恢复。

不能确定识图上传的是原图、裁剪前景、未裁剪前景还是重绘图，也不能保证抠图失败必然调用场景回退。不能仅凭 base64 字符串确定实际上传图像内容。

## 六、与旧官网的差异

| 项目 | 官网资料 | 本 IPA 证据 |
| --- | --- | --- |
| 抠图 | 笼统写 VisionKit | 主程序具体使用 Vision.VNGenerateForegroundInstanceMaskRequest |
| 贴纸边缘 | 未披露 | VNDetectContoursRequest 与自定义 OutlineView |
| AI 通信 | 第三方 AI，同时宣称无自有服务器 | 内置应用后端、设备认证、区域／路由与回退实现 |
| 词汇处理 | 简单识别描述 | 语义锚点、多语学习规则、本地审计、条件复核 |
| 发音 | AVSpeechSynthesizer | 除系统语音相关能力外，还存在 Qwen／MiniMax TTS 后端路径；当前默认方案未知 |
| 本地数据 | 说明含混 | Core Data 模型包含 StickerItem、ChatSession、ChatMessage、UserMemory 等实体 |

这些差异可能来自产品版本演进、官网未更新或样本被修改，当前不能唯一归因。

## 七、结论与剩余问题

已回答：本样本抠图 API、前景／裁切图和蒙版输出、轮廓检测的部分参数、后端接口候选、词条 Prompt 合同、条件复核策略。

部分回答：实例选择、多阶段执行顺序、失败回退、具体模型职责与实际生效路由。

未回答：服务器内部代码、实际请求内容、线上模型版本、动态配置、每次请求成本及耗时、完整白边动画参数、对官方未修改包的真实性对照。

最可靠的复现方向是：Apple Vision 负责本地分割；轮廓检测与自定义绘制负责贴纸外观；多模态后端负责物体语义；结构化多语 Prompt 与程序化审计负责词卡质量。不要把这些职责合并成一个“识图模型”。
