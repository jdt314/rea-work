# CapWords 抠图与图像识别分析

调查日期：2026-10-16。目标：https://capwords.app/ ，官网链接指向 App Store ID 6738896465。

## 范围与工具限制

已读取 reverse-engineer-anything 技能，检查会话工具并尝试 REA CLI doctor。当前会话没有 REA MCP 工具；通过默认 npm 镜像及 registry.npmjs.org 获取 rea-agents@6.5.0 均因 EACCES 失败。因此本报告属于公开资料与网页静态取证，没有 REA Evidence ID，没有对 iOS App 解包、反编译或抓包；不能称为已完成二进制逆向。

官网为 Framer 宣传站。其页面代码不能证明手机 App 内部算法。下文严格区分官方自述、技术解释和未验证事项。

## 结论与证据索引

| 问题 | 结论 | 证据与状态 |
| --- | --- | --- |
| 拍照使用什么 | 官网列出 AVFoundation、VisionKit | E1，官方自述，未运行验证 |
| 背景去除使用什么 | 官网明确写 VisionKit 与 AVFoundation 用于 image capture and background removal；无法据此确定具体抠图类 | E1，官方自述 |
| 物体识别使用什么 | 隐私政策列出 OpenAI Vision API 和 Google Gemini Vision API | E2，官方自述，未确定实际模型版本、路由 |
| 是否完全离线 | FAQ 写明单词识别需要联网，已保存贴纸可离线复习 | E3，官方自述 |
| 发音 | AVSpeechSynthesizer；官网还提到 Neural Voice 支持 | E1、E2，官方自述 |
| 语音识别 | Speech、SFSpeechRecognizer | E1，官方自述 |
| 同步 | 首页与隐私政策列出 CloudKit；FAQ 又说不支持同步 | E1、E2、E3 相互冲突，当前版本行为未知 |
| 精确抠图 API、模型、Prompt | 无法从现有材料确认 | 需要 App 产物或运行证据 |

这里 E1–E4 是本地材料索引，不是 REA 生成的 Evidence ID。

## 抠图原理

抠图的任务是判断每个像素是否属于要保留的物体；识别的任务是为物体命名。两者不需要由同一个模型完成。

官网直接公开了苹果系统能力用于背景去除，因此优先考虑调用系统前景提取，而不是假定团队训练了自己的分割模型。具体可能采用 VisionKit 的主体提取，或 Vision 的前景实例分割；现有资料不能选定其中一个。

可用于实现类似效果的一个已核实苹果接口是 Vision.VNGenerateForegroundInstanceMaskRequest。苹果文档说明它生成显著物体的实例蒙版，用于分离背景，iOS/iPadOS 17.0 起提供。该接口存在不等于 CapWords 使用了它。

典型处理过程：

1. 拍照后统一图像方向和坐标系。
2. 系统模型产生前景实例蒙版，每个实例对应一个候选物体。
3. 根据点击位置、取景位置或面积等规则选中目标；CapWords 的具体选择规则未知。
4. 生成与图像对齐的遮罩，合成透明背景物体图，裁剪到主体边界。
5. 如果界面需要白边，可以对透明度蒙版做膨胀，再用膨胀后的轮廓绘制底色、叠加原物体；阴影和轻微旋转属于展示层。

合成时可理解为：透明度由蒙版决定，前景颜色来自原图；实际实现需正确处理预乘透明度和边缘，以免出现黑边或白边。白边的具体实现仅为复现建议，未验证 CapWords 内部代码。

这也解释了为什么抠图不等于“生成新图片”：一般情况下保留的仍是用户原照片中的像素，只是背景变透明。复杂毛发、透明玻璃、细线、遮挡等会增加分割难度。

## 识别与词卡原理

隐私政策的 b. Image Recognition via Third-Party APIs 明确写出：

> Service Providers: OpenAI Vision API and Google Gemini Vision API
>
> Data Flow: Images are securely transmitted over TLS-encrypted connections to the selected provider for one-time processing; results are returned immediately to CapWords.

由此可以确认的是：官方披露过将图像发送给第三方模型识别的方案。不能由此确认每次识别同时调用两家、是否自动回退、所用模型版本，以及客户端是否直接访问服务商域名。

合理的数据流为：照片 → 物体识别 → 得到物体名称 → 生成目标语言词汇信息 → 组合透明贴纸与文字 → 保存复习。命名、翻译、例句可能由一次多模态请求完成，也可能分成多次请求，现有证据不能确定。

若复现，可以让识别服务返回结构化字段，如 object、target_word、native_meaning、example。此字段设计是实现建议，不是截获的 CapWords 返回格式。发音可交给系统 AVSpeechSynthesizer，无需把文本转换成语音文件后再下载。

还不能确定上传的是整张照片、主体裁剪图、带背景裁剪图，还是处理后的贴纸；也不能确定识别与抠图谁先完成、是否并行。这些选择会影响识别上下文、延迟与多物体选择一致性。

## 公开说明的冲突

- 首页及 FAQ 说照片完全在本地处理、不上传任何服务器；但首页详细说明及隐私政策又明确承认发送给第三方 AI。不能把“CapWords 无自有服务器”理解为“图片不离开设备”。
- 隐私政策 a 节写不上传任何服务器，b 节又描述上传第三方 API；这是同一文件内部的冲突。
- 隐私政策写服务商可能保留请求数据至多 30 天。这是 CapWords 的政策声明，本次没有核验服务商当前条款或该 App 的具体服务协议，不能当作实际删除时限的保证。
- “原始照片不保留”与“保存词卡贴纸”可能指不同数据，但照片、裁剪图、透明贴纸的确切存储边界没有说明。
- 隐私政策标注更新时间为 2025-04-18，不能据此认定其准确描述 2026 年最新 App 版本。

## 若要做出类似功能

建议先验证一条最小技术链：AVFoundation 拍照 → 苹果前景分割 → 透明物体贴纸；另一路把选定主体的图像提交多模态识别服务 → 结构化词汇信息 → 系统 TTS 朗读 → 本地保存。识别、抠图及词卡展示应有独立错误处理。

重点处理同一照片中多个物体的目标一致性、旋转图像坐标映射、透明物体边缘，以及识别不确定时的手动改词。若做非苹果平台版本，需要另选可部署的前景分割模型或抠图服务，不能直接照搬 VisionKit。

## 要进一步确认内部实现，需要什么证据

1. 合法取得且可分析的 App 产物：检查 Mach-O 依赖、类与符号、模型资源、相关 API 调用及交叉引用。仅发现字符串不能证明实际执行。
2. 自有设备上对 App 拍照流程的运行记录：确认请求域名、模型标识、请求与返回结构、错误与回退。仅域名记录不能确定上传图像内容。
3. 离线对照实验：观察断网时能否抠图、何时识别失败；该实验支持职责划分，但不能单独确定调用了哪个类。

在没有这些材料的情况下，精确模型、Prompt、API 密钥管理、请求路由、抠图类名、缓存及生成顺序仍未解决。

## 来源与本地证据

- E1：https://capwords.app/ — evidence/home.html、evidence/home-text.txt。关键原文：VisionKit and AVFoundation: for image capture and background removal。
- E2：https://capwords.app/privacy — evidence/privacy.html、evidence/privacy-text.txt。
- E3：https://capwords.app/faqs — evidence/faqs.html、evidence/faqs-text.txt。
- E4：https://developer.apple.com/documentation/vision/vngenerateforegroundinstancemaskrequest — evidence/apple-foreground.json，苹果文档 JSON 原始响应。
- 补充：https://capwords.app/about — evidence/about.html、evidence/about-text.txt，讲述把真实物体变成贴纸的产品构想，没有披露算法。
