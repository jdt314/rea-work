# DeepSeek 拍照识别接入

2026-10-19：拍照和相册选图接入 DeepSeek 官方 OpenAI 兼容接口；需要用户自己的 API Key。进入「个人 → AI 图片识别」，填写密钥并保存，再拍摄或选择照片。

| 配置 | 默认值 |
| --- | --- |
| Base URL | `https://api.deepseek.com` |
| 请求路径 | `/chat/completions` |
| 模型 ID | `deepseek-flash` |
| 对应版本 | 当前官方 V4.1-Flash-1017；别名会随官方升级，非固定版本锁定 |
| 请求 | JPEG base64 `image_url`，非流式，JSON 输出，2048 输出 token，60 秒请求超时 |

官方 [版本公告](https://api-docs.deepseek.com/news/news261017/)、[图片接口](https://api-docs.deepseek.com/guides/vision/) 与 [思考模式](https://api-docs.deepseek.com/guides/thinking_mode/) 是接口依据。官方域名请求明确关闭思考模式以缩短词条生成等待；自定义网关不附带此扩展参数。

## 数据与行为

图片先校正方向并将长边限制为 1600，然后重新编码为 JPEG。上传的是用户确认裁剪后、带背景的规范化图片，不上传原始 EXIF、位置或相册资源。图片规范化后即启动网络，Vision 在本机继续生成透明贴纸。抠图完成即可展示消散和主体确认；用户确认、白页展开、词条返回三条件齐备后才揭示结果。慢请求期间保持点阵悬浮，失败保留主体并提供重试或手动填写。

模型一次生成目标语言名称、简体中文释义、读音、一组例句与中文译文、分类。支持现有五种学习语言。提示词要求主体语义一致、区分容器和内容物、避免品牌文案，不确定时返回 `needsNaming` 进入手工填写。返回的语言、字段类型、长度和结束原因会校验，截断或无效内容不会保存为词卡。

本地分割失败保留完整图像，但不会把已发出的主体识别请求自动改成场景请求；主动选择「识别完整场景」时使用场景提示词。现有分割保留所有前景实例，复杂多主体照片建议先裁剪，尚未实现 REA 研究中的中心实例选择。

API Key 保存在本机 Keychain，地址及模型保存到 UserDefaults，不写入源码或日志。设置支持移除密钥。未配置时仍可完成本地抠图，确认后明确提示配置问题，不静默回退为本地词典。认证失败、限流、超时和接口错误显示中文提示；重试由用户点击触发，不自动重复计费请求。取消或重新拍摄会取消旧请求，代次标识阻止迟到结果覆盖当前页面。

模拟器示例拍摄及现有 UI 演示仍走固定示例；模拟器验证云端识别请从相册导入实际图片。

## 研究依据与实现范围

| 证据 | 结论 | 实现位置 |
| --- | --- | --- |
| [IPA-REPORT](../../capwords-analysis/IPA-REPORT.md) 第三、四节 | 本地分割与远端双语语义生成分工，词义必须一致 | `RecognitionService`、`AIRecognitionClient` 提示词 |
| [CAPTURE-GAPS](../../capwords-analysis/CAPTURE-GAPS.md) | 请求与动画需协调；实际服务端契约未证实 | 可取消子任务、`CaptureFlow` 代次和重试 |
| DeepSeek 官方图片文档 | OpenAI 兼容图片内容块 | `Models/AIRecognition.swift` |

这里的 JSON 字段和一次生成例句是本项目实现，不是 CapWords 原始接口协议。未访问 CapWords 私有后端或使用 IPA 内凭据，未实现其条件二次审计与三组例句策略。

## 验证

从 `CapWordsSwift` 目录运行：

```bash
DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer swift test --scratch-path /tmp/capwords-startup-core
bash scripts/verify.sh
```

核心测试覆盖图片请求编码、地址及密钥校验、结构化词条、不确定结果、语言不符、空词条、截断、错误 JSON，以及模拟网络的认证失败、限流、超时、取消。应用编译成功；测试不向真实 API 上传照片。

真实端到端验收仍需配置 API Key：分别测试拍摄、相册、换语言、场景识别、断网重试、取消后重拍及保存词卡。当前未进行真实服务调用，不声明模型识别质量、真实延迟或费用已经验收。
