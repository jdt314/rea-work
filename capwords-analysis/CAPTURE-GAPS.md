# CapWords：五个缺口的补充逆向结果

样本：`cap.ipa`，CapWords 2.0.9（445）；分析日期：2026-10-16。本文接续 [CAPTURE-FLOW.md](CAPTURE-FLOW.md)，只记录新增恢复结果。

继续采用 REA 工作流，复用已有 IPA inventory 和资源 Evidence；本轮新增结果来自 ARM64 指令、Swift 枚举元数据、相对函数指针和调用参数的数据流检查。REA MCP／原生反编译引擎不可用，未将本地指令分析冒称为 REA 成功反编译。没有运行 App、抓包或访问其识别后端。

**五项均取得实质进展，但还不能称逐帧、全分支完全复原。** 主体选择算法、两种裁剪公式、静态白边主链、43 个动作分派、关键异步时序与逐帧 Vision／GIF 编码已恢复；完整相机坐标链、全部 UI 变换、动态主体一致性及实际运行耗时仍有边界。

| 缺口 | 本轮补齐内容 | 尚未闭合部分 |
| --- | --- | --- |
| 主体选择／坐标 | 中央像素排序、备用轮廓排序；直接比例与 aspect-fit 反算裁剪 | 所有入口与预览缩放／镜像／方向的组合 |
| 白边／平滑／阴影 | 白边宽 14、边距 14、圆头圆角、透明合成、轮廓取点及截图 | 显示层额外阴影的完整属性绑定 |
| AI／动画状态机 | 43 个 tag→分支；结果门控、取消检查、重试入口 | 网络错误到每个 UI 动作的全部映射；并发实测 |
| 动态媒体 | 抽帧、逐帧分割与轮廓、坏帧跳过、GIF 参数 | 每条媒体模式的最终帧率／尺寸和实例跨帧一致性 |
| 悬浮／落下／飞回 | 顺序等待、动作绑定的 spring、飞回完成回调 | 所有旋转／缩放／位移表达式及设备实测时间线 |

## 1. 主体选择和坐标映射

### 1.1 不是固定取最大主体，也不是只读中心一个像素

入口 `0x100569fbc` 从 `VNInstanceMaskObservation.instanceMask` 读取 `L008` 实例标签图，获取尺寸、基址、行跨度和 `allInstances`。传入 `0x100569408` 的比例是 `0.5`。

对有效实例像素 `(x,y)`，恢复出三类统计量：

```text
total[id] += 1

u = (x + 0.5) / width
v = (y + 0.5) / height
如果 0.25 <= u <= 0.75 且 0.25 <= v <= 0.75:
    central[id] += 1

distance[id] = min(distance[id],
    (2*x + 1 - width)^2 + (2*y + 1 - height)^2)
```

中央区域是**宽、高各 50% 的矩形，面积占 25%**。距离是标签图像素网格的距离，没有分别按宽高归一化。

候选先限制为实际出现过的 `allInstances`。如有实例触及中央区域，只在这些实例之间排序：

1. 中央区域像素数多的优先。
2. 相同时，离图像中心最近的像素距离小的优先。
3. 再相同时，总像素数多的优先。
4. 最后按实例 ID 小的优先。

如果没有实例进入中央区域，则对出现过的实例按“最近中心距离升序 → 总像素数降序 → ID 升序”排序。比较器分别是 `0x100550a9c`、`0x100550c10`；调用点为 `0x100569de8`、`0x100569ebc`。

因此，中央小物体可能战胜边缘大物体。不能把这一实现简化成“最大连通域”，也不能把距离理解成质心距离。

### 1.2 备用选择与最终回退

像素选择返回空时，进入 `0x10056a144`：对每个实例调用 `generateMaskForInstances:error:`，独立检测轮廓。参数为 contrast `2.0`、darkOnLight **true**、maximumImageDimension `512`。

每个实例的得分是其**最大单条轮廓的包围盒面积**；再选该分数最大的实例。不是 mask 像素面积，也不是所有轮廓面积之和。两条选择路径都失败后，主提取器使用 `allInstances` 整体集合。

主提取器最终返回三元组的映射已确定：`x0` 未裁切透明前景、`x1` scaled mask 图、`x2` 裁切到主体的前景。对应生成调用见 `0x10056ae60`、`0x10056aec8`、`0x10056af2c`，返回见 `0x10056afcc`。

### 1.3 两条真实存在的裁剪公式

在 `0x10055cdd0` 恢复出直接比例映射。以代码读取的显示边界宽高 `Vw,Vh`、CGImage 像素宽高 `Iw,Ih` 和矩形 `R=(x,y,w,h)` 表示：

```text
sx = Iw / Vw; sy = Ih / Vh
pixelRect = CGRectIntegral(x*sx, y*sy, w*sx, h*sy)
CGImageCreateWithImageInRect(image, pixelRect)
```

在 `0x10055f348` 恢复出包含居中留白偏移的 **aspect-fit** 反算：

```text
s = min(Vw/Iw, Vh/Ih)
ox = (Vw - Iw*s)/2
oy = (Vh - Ih*s)/2
pixelRect = CGRectIntegral((x-ox)/s, (y-oy)/s, w/s, h/s)
```

它使用 `min` 对应适配留白，不能直接套到使用 aspect-fill 的相机预览。两个裁剪点都读取原 UIImage 的 `scale` 和 `imageOrientation`，供后续构造图像使用。

另一个坐标变换 `0x1005692b4` 将 Vision 点 `(x,y)` 转成 `(x,1-y)` 再构造闭合路径。`0x10056bce8` 根据前景图片纵横比在目标矩形中 aspect-fit，并将路径 bounds 缩放、平移到图片呈现区域，额外加入 14 的边距。

**范围限制：**以上是已定位分支的公式；尚未把相机 preview、相册裁剪、前摄镜像、八种 UIImage 方向到这些入口的全部调用组合闭合，不能宣称全入口坐标转换已完成。

证据：[主体选择指令](evidence/ipa/capture-flow/gaps/subject-selection.txt)、[裁剪指令](evidence/ipa/capture-flow/gaps/crop-coordinates.txt)。

## 2. 最终静态贴纸白边、轮廓和阴影

### 2.1 白边主链已经恢复

`0x10056bce8` → `StickerOutlineImageView` 构造实现 `0x1004d1f00` → shape layer 构造 `0x1004d1db0`。

| 属性 | 确认值／行为 | 证据 |
| --- | --- | --- |
| 外围留白 | 四周 14，目标宽高增加 28 | `CGRectInset(-14,-14)` |
| 描边宽度 | 主链显式传入 14 | `0x10056be88`、`0x10056c440` |
| 描边色 | whiteColor | `0x1004d1e18…44` |
| 填充色 | clearColor | `0x1004d1e8c…b8` |
| 线连接／线帽 | kCALineJoinRound／kCALineCapRound | `0x1004d1e60…84` |
| 层顺序 | 描边层插入容器 layer 的 index 0；图片位于子视图 | `0x1004d1edc`、`0x1004d201c` |
| 图片布局 | 四边约束 ±传入边距 | `0x1004d2094…218c` |
| 导出位图 | UIGraphicsBeginImageContextWithOptions → layer.renderInContext → UIImage | `0x1004d1c20` |
| 导出比例 | 读取 UIScreen.main.scale | `0x1004d1c50…7c` |

`0x1004d1f00` 中先写入的默认值 10 随后被调用参数覆盖；当前主链有效值是 **14**。14 是该绘制坐标空间的数值，不是保证所有缩略图都显示 14 个屏幕像素。描边以路径为中心，理论两侧各 7；被前景图片覆盖的部分不能等同于外露白边厚度。

`fetchOutlineImage` 分支还给出 `300×300` 的目标矩形（`0x1004c5bdc…bf4`）；加留白后容器为 `328×328`。另一 helper `0x10056c28c` 先复制路径、将 bounds 原点归零，再按目标宽高缩放并平移 `(14,14)`，最终仍传入宽 14。

### 2.2 轮廓没有证据支持“贝塞尔平滑”

正常轮廓提取 `0x100568bb4` 使用 contrast `2.0`、darkOnLight **false**、maxDimension `512`，比较轮廓包围盒面积，选中一条轮廓。它和主体选择备用路径的 darkOnLight 参数不同。

`0x100568f98` 调用 `polygonApproximationWithEpsilon:error:`，浮点参数位模式 `0x3e99999a`，即约 `0.3`。但返回对象保存在 x21 后即被 release；`0x100568fbc` 将原 VNContour（x27）置于 Swift self 寄存器，再读取 `normalizedPoints`。因此本路径实际使用原轮廓点；不能把“调用过简化接口”写成“最终轮廓成功采用 epsilon=0.3 简化”。

路径生成使用 `moveToPoint`、逐点 `addLineToPoint`、`closePath`。已确认的圆滑处理是描边圆头／圆角；没有在该路径发现二次／三次贝塞尔拟合。

### 2.3 阴影需要区分图层

已恢复的 `StickerOutlineImageView` 构造链没有设置 shadowColor／shadowRadius／shadowOffset。它能证明“透明图片加白色描边”，尚不能证明结果 UI 没有在外层追加阴影。

此前流光视图的白色 shadow、opacity `0.35`、radius `4` 属于扫描轮廓效果；stroking width `3` 用于其 shadowPath。**这组值不能替代静态贴纸白边与最终投影的参数。**

证据：[白边与路径指令](evidence/ipa/capture-flow/gaps/outline-rendering.txt)。

## 3. 识别与动画的状态协调

### 3.1 真实 reducer 与动作 tag

恢复了 `0x1004c4980` 的 43 路分派表。Swift descriptor 显示 payload cases `25`、empty cases `18`，字段记录与之吻合；本枚举字段先列 payload cases，后列 empty cases，可据此与运行 tag 对应。跳表位于 `0x1004c61fc`，相对基址 `0x1004c4b14`。

完整 43 项映射见 [action-dispatch.json](evidence/ipa/capture-flow/gaps/action-dispatch.json)，下面列关键项：

| tag | 动作 | 分支入口／关键行为 |
| --- | --- | --- |
| 4 | layerState | `0x1004c4fcc`，写入状态 |
| 12 | setStickerItem | `0x1004c51d4`，存词条后检查是否为 loading（3） |
| 18 | prepareReturnFlight | `0x1004c55a8`，处理目标矩形 |
| 26 | startFloatingAnimation | `0x1004c5c8c`，启动异步动作链 |
| 27 | showResult | `0x1004c4cf4`，启动结果异步动作链 |
| 28 | showResultIfNeed | `0x1004c5984`，结果门控 |
| 31 | skipFloatingAnimation | `0x1004c53fc`，设置跳过标记 |
| 32 | enterReloadingMode | `0x1004c571c`，启动独立 effect |
| 33 | enterLoadingMode | `0x1004c4f98`，布局／进入加载分支 |
| 35 | retryButtonTapped | `0x1004c4ba4`，设置 retry=true |
| 36 | doneButtonTapped | `0x1004c4bb8`，检查 done 标记及词条 |
| 37 | cancelButtonTapped | `0x1004c4b38`，独立取消展示 effect |
| 41 | returnFlightCompleted | `0x1004c5424`，更新飞回完成标记 |
| 42 | setLowMemoryMode | `0x1004c5814`，读取可用内存后设置模式 |

State 的 7 个值为 begin=0、floating=1、dropped=2、loading=3、showResult=4、error=5、done=6。枚举值本身不等于已证明所有转移边。

### 3.2 快／慢结果的门控

`showResultIfNeed` 的实际条件是：

```text
if layerState == showResult: return
if stickerDatabase == nil: return
启动 showResult effect
```

它本身没有“必须是 loading”条件；`setStickerItem` 分支则检查 `layerState == loading` 才进入后续 effect。因此实现是“词条到达”和“演出推进”分别驱动门控，而非按网络进度线性播放动画。

结果 effect `0x1004c8bbc` 的可见顺序包含：

```text
scaleMovingAnimation(true), spring(0.5,0.5,0)
showResultBgLayer(true),    spring(0.5,0.5,0)
按 lowMemory 条件及等待继续
showCompletionAnimation(true), spring(0.5,1.0,0)
showResultCounter / layerState(showResult) / showStickerLayerButtons(true)
```

低内存标记参与 `0x1004c8fd8` 的分支，其中一条路径额外等待 `0.2s`。同一 effect 后部也有 `0.2s` 等待，不能把它们不分条件地都累加成固定耗时。

### 3.3 取消、重试与失败的证据边界

多个异步 continuation 在回到 MainActor 后检查 `Task.isCancelled`，取消则跳过动作发送，例如 `0x1004c86e4`、`0x1004c89b0`、`0x1004c999c`。这是阻止已取消 effect 继续修改 UI 的证据；尚不能单凭这一点证明所有网络和媒体任务都被 cancel。

取消按钮 effect `0x1004c986c` 会发送 `hideVideoImmediatly(true)`，随后以 spring `(0.5,1,0)` 发送 `dismissAniamtion`。重试动作直接设置 `_isRetry=true`；重新发请求的完整外层订阅链仍需进一步闭合，不能写成固定重试次数／退避算法。

错误方面，静态图片仍有 Vision／轮廓错误和场景回退证据；本轮不能将所有 error 都合并为同一个终态，也没有证据支持统一超时秒数。

证据：[reducer、异步动作和时序指令](evidence/ipa/capture-flow/gaps/state-and-timing.txt)。

## 4. Live Photo／视频、逐帧蒙版与 GIF

已追到以下实际代码链：

1. `AVAssetImageGenerator` 设置 requestedTimeToleranceBefore／After、maximumSize，异步加载 track.preferredTransform；随后将 appliesPreferredTrackTransform 设为 true（`0x100552008…2a8`）。容差与最大尺寸的全部有效参数来源尚未闭合。
2. `copyCGImageAtTime:actualTime:error:` 按 CMTime 抽帧。`0x100554754` 使用 timescale `30`，该区域计算 `duration*30/step`。这证明 30 的时间基准及抽样步长存在，**不能直接称最终 GIF 固定 30 fps**。
3. CGImage 转 UIImage 的 helper `0x10056bbc8` 只打印传入 transform，最终用 scale=1、orientation=up 构造 UIImage，没有再次 apply 该 transform。旋转主要依赖上一步 generator，不能再盲目旋转一次。
4. 正常帧分支 `0x10055acf8` 通过相对函数指针 `0x10185fa18` 调用 `0x10056aa08`，即前景实例分割；continuation `0x1005596d0` 保存三张输出，再通过 `0x10185fa20` 调轮廓提取。因此至少该真实循环分支逐帧重做 Vision 与轮廓，不能说只取第一帧的 mask 套全片。
5. 抽帧／分割／轮廓失败有日志、释放对象和继续循环的分支。`0x100559880` 包含“抠图失败，跳过原始图像”日志。某些循环也主动 `Task.yield` 或 sleep；具体设备策略未全部还原。
6. 最终由 ImageIO 写临时 GIF，路径前缀 `live_photo_custom_gif_` 加 UUID，编码 UTType.gif。

### 4.1 GIF 编码参数

编码函数 `0x100552d74` 可确认：

| 项目 | 实现 |
| --- | --- |
| 帧数 | 来自实际输入帧数组长度 |
| 每帧延迟 | 传入 duration / 输入帧数 |
| 延迟字段 | GIFDelayTime 与 GIFUnclampedDelayTime 都写入同一值 |
| 循环次数 | 来自传入参数，不是此函数内固定 0 |
| 全局色表 | GIFHasGlobalColorMap=true |
| 色彩模型／深度 | RGB／8 |
| 写入 | CGImageDestinationAddImage，最后 Finalize |

若失败帧被过滤后仍沿用原 duration，这一函数会将时长平均分配给剩余帧；它没有在该编码路径逐帧保留原始采集时间戳。GIF 属性声明也不等于已验证每个编码器的色表与透明色实际输出。

### 4.2 仍需区分的实现问题

- 没有恢复跨帧固定实例 ID 或目标跟踪绑定。逐帧使用独立选择规则时存在主体切换的可能，但未实测发生率。
- 已找到两种 crop 公式，但还不能保证所有视频模式均使用同一种。
- GIF 是 8-bit 色彩路径，不能保证细发丝和半透明边缘保留原始 mask 的全部精度。
- 有独立 gif／gifScene、showGifView、maskAnimation 等状态，不应把静态消散时长直接外推到全部动态入口。

证据：[动态媒体指令](evidence/ipa/capture-flow/gaps/dynamic-media.txt)。

## 5. 悬浮、落下、结果与飞回的参数

### 5.1 startFloatingAnimation 的可恢复时间线

真实入口：reducer tag26 → `0x1004c5c8c` → relative thunk `0x1004ced00` → async `0x1004c690c`。

| 相对进入该 effect 的名义时间 | 动作 | 证据 |
| --- | --- | --- |
| 0.2s | incrementRippleCounter | 等待 `0x1004c6a08`；tag25 写入 `0x1004c6b0c` |
| 0.5s | startDustAnimation(true) | 再等待 0.3s；tag2 写入 `0x1004c6d48` |
| 1.5s | stickerFloat(true) | 再等待 1.0s；tag5 写入 `0x1004c6f48` |
| 2.1s | showPathAnimation(true) | 再等待 0.6s；tag3 写入 `0x1004c714c` |

其中 1.0s 来自 Duration 常量两个 64-bit words `[0x0de0b6b3a7640000,0]`，对应 `10^18` attoseconds。其他时间来自 `Duration.seconds` 的显式参数。

这条表是**相对 effect 开始的顺序等待**，不是相对快门的实测秒数；还要加任务调度、主线程切换及取消分支的影响。它也不表示轮廓流光固定只播放到 2.1 秒。

### 5.2 移动和落下动作链

`enterLoadingMode` 经 `0x101859d60` 指向的 thunk 进入 `0x1004c7d18`，效果链包含：

| 动作 | 参数 |
| --- | --- |
| startMoving(true) | spring response=0.5、dampingFraction=1、blend=0 |
| moveStickerToFrame(rect) | spring response=0.5、dampingFraction=1、blend=0 |
| 后续等待 | 0.35s（`0x1004c80c4`） |
| fetchOutlineImage | tag29（`0x1004c81d4`） |
| stickerDrop(true) | tag7（`0x1004c82b4`） |
| 后续等待 | 0.1s（`0x1004c83ac`） |
| incrementRippleCounter | tag25（`0x1004c84bc`） |
| layerState(loading) | tag4，payload=3（`0x1004c8594…a0`） |
| showResultIfNeed | tag28（`0x1004c8670`） |

还恢复出 `enterReloadingMode` → `0x1004c7604` 的重置链：隐藏按钮 spring `(0.5,1,0)`，关闭 scaleMoving／结果背景 spring `(0.5,0.5,0)`，关闭 completion spring `(0.5,1,0)`，增加 ripple、设 loading。

spring 的 response 不是保证动画结束的硬时长；不能把 `(0.5,1,0)` 写成“固定 0.5 秒结束”。`stickerDrop(true)` 的完整视图变换与旋转表达式尚未绑定完，不能仅凭动作名宣称自由落体、重力大小或弹跳次数。

### 5.3 飞回已经与具体动作和完成条件绑定

`0x1004ad09c` 使用 spring `(response=0.6, dampingFraction=0.9, blendDuration=0)`，并指定 `AnimationCompletionCriteria.removed`。

- animation body `0x1004b4cc0` → `0x1004ad234` 发送 **moveStickerToFrame(rect)**（tag6）。
- completion `0x1004b4ce0` 将 **tag41=returnFlightCompleted** 交给发送 helper。
- `prepareReturnFlight` 提供目标矩形；飞回目标由状态传入，不能写成固定屏幕坐标。

这使上轮“0.6／0.9 的 spring 是否属于飞回”的不确定性得到闭合：它连接到了移动矩形与飞回完成动作。完成应依赖动画 completion；不应以 sleep(0.6) 代替。

仍未恢复主体常态悬浮的全部 scale／rotation／offset 公式，也没有逐设备运行录像。结果背景的 `easeInOut(1.5).repeatForever` 仍只归属于背景星光，不归到主体悬浮周期。

## 6. 对自用重建的直接影响

现在可以按已恢复行为实现“中央优先选主体 → 本地前景／mask／裁切图 → 路径白边合成 → 独立识别任务 → 结果门控 → 确认飞回”的可用主链；这些客户端行为不需要原应用订阅系统。若要求动画逐帧一致，还需补足视图变换和原版运行记录。

建议重建时显式保存原图到显示图的 affine transform，避免把两种 crop 分支混用；视频目标一致性可以另外设计跟踪规则。以上是开发建议，不冒充原 App 已确认实现。识别服务和密钥应自行配置；现有样本尚未证明服务端当前模型与完整图片上传编码契约。

## 7. 证据复核

新增脚本：[decode_capture_gaps.py](decode_capture_gaps.py)。它仅读取本地样本和既有反汇编，校验 25+18=43、payload 标记、43 个跳表目的地址，并输出动作映射和五份聚焦指令证据。没有运行目标代码。

复核方式：`python capwords-analysis/decode_capture_gaps.py`。与上轮文件一起阅读时，以本文对主体选择、白边参数、枚举分派和飞回的补充为准。未闭合内容均保留为未知，没有以通用 iOS 实现代替样本证据。
