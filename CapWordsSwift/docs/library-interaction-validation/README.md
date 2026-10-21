# 日期词库交互验收

2026-10-19：根据用户两张截图、`2.mp4` 和 `CapWords_2.0.11.ipa` 实现。今天没有拍摄时保留整屏空态和会转动、眨眼的眼睛，向上滑松手时立即轻震动，并短弹到下一个有词的日期；空白页向下滑不触发。历史列表返回空白今日也采用整页弹回和轻触觉。今天有词时直接连续滚动。顶部返回、日期与计数固定，日期数字向下替换，底部快门固定。首次保存当天词条会移除空态高度并回到今天。

27 项核心测试通过，应用及 UI 测试产物编译通过。iOS 26.1 开发模拟器已采集页面与程序化滚动录屏。XCTest runner 因 `DTServiceHubClient failed to bless service hub` 未执行手势用例，不能把截图或 `scrollTo` 录屏当作触摸吸附测试通过；震动触感仍需 iPhone 确认。

用户最终明确：空白日期向下滑不能触发，列表返回空白日期也要有整页动画。空白页使用独立上滑手势，达到 36 pt 后松手，立即触觉并以约 0.28 秒弹动切页。从历史返回时先到达首个历史日边界，再下拉 36 pt 触发同样的整页动画；到边界之前的滚动距离不计入触发阈值。快滑惯性跨过边界也使用相同返回动画。手势提交后才暂时停用原生滚动，动画完成恢复，一次切页只震动一次。下方旧录屏只作为布局和数字方向证据，不能代表最终手势实测。

## 实际页面

| 场景 | 产物 | 检查内容 |
| --- | --- | --- |
| 今天为空、有历史 | [empty-today.png](empty-today.png) | 今天 0 个词、眼睛、两行文案；底部没有历史标题露出 |
| 今天有一个词 | [populated-today.png](populated-today.png) | 今天 1 个词、昨天 5 个词；没有整屏空态留白 |
| 定位到第一个历史日 | [first-history.png](first-history.png) | 顶部日期和数量对应历史组，首行贴纸在其下方 |
| 完全没有词 | [completely-empty.png](completely-empty.png) | 保留今天和拍摄入口，不制造第二页 |
| 程序化日期切换 | [programmatic-scroll.mov](programmatic-scroll.mov) | `scrollTo` 驱动今天→昨天→更早→今天，检查固定标题及渲染；不是手势测试 |

采样设备为 iPhone 17 Pro 开发模拟器，iOS 26.1，UDID `4607AA88-3821-4245-91AA-A1E6B8E407E4`。示例词只写入 `--uitesting` 内存数据库，不更改正常词库。示例贴纸与原版物件不同，截图用于检查布局与状态，不声称逐像素一致。

## 实现与依据

原录像的逐帧测量见 [视频 2 记录](../video-2-evidence/notes.md)。最新版 IPA 静态证据和范围见 [REA 报告](../library-2.0.11-evidence/2026-10-19_逆向-CapWords词库-report.md) 与 [scope.md](../library-2.0.11-evidence/scope.md)。主程序有 FairPlay 加密，未提取原版滚动阈值、触觉强度或眼睛时间轴。

| 代码 | 行为 | 参数性质 |
| --- | --- | --- |
| `App/Views/LibraryView.swift` | 空白日高度采用实际视口；实测最后一组高度补齐尾部；剪裁安全区域外的内容 | 适应不同屏幕，修复首屏漏出与短历史日吸附边界 |
| `App/Models/LibraryScrollPolicy.swift` | 空白页仅上滑切页，历史自由滚动，向下跨越首历史日边界整页返回 | 手势阈值 36 pt、双向 0.28 秒 spring；惯性边界位移 64 pt、速度 180 pt/s 均为复现选择 |
| `App/Views/LibraryTimeline.swift` | 固定月、日和计数；只替换变化的数字，新字自上入 | 0.18 秒数值过渡；跨月错峰细节未逐字复刻 |
| `EmptyDayEyes` | 白色眼球、深色瞳孔、视线变化和眨眼；离屏、后台、减少动态效果时停动画 | 独立 SwiftUI 绘制；4.6 秒周期和眨眼曲线为设计选择，未复制 PAG |
| `LibraryScrollBehavior.onPageSnap` | 松手确定跨页目标时执行一次 soft impact，停稳时只作去重兜底 | 程序化跳转和普通历史滚动不触发；真实强度未验收 |

日期与计数在下一历史组进入顶部约 72 pt 区域时切换，空白今天进入历史时延后到第一历史组到顶。该提前量根据视频所见约 62–105 像素差距选择，并非原版内部算法。日期视觉不带“日”，无障碍标签保留完整日期与词数含义。

搜索和分类沿用正常分组浏览；切换模式清理滚动位置。保存第一词时清空搜索并返回日期视图，布局稳定后再取得贴纸飞行终点。调试用示例入口移至词库菜单，不占据空态正文。

## 可复现检查

在仓库根目录构建并采样（目标模拟器须已启动）：

```bash
bash CapWordsSwift/scripts/verify.sh build-for-testing
CAPWORDS_SIMULATOR_ID=4607AA88-3821-4245-91AA-A1E6B8E407E4 bash CapWordsSwift/scripts/capture_library.sh
```

核心测试从 `CapWordsSwift/` 执行：

```bash
DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer swift test --scratch-path /tmp/capwords-startup-core
```

覆盖快速滑动只离开一页、短拖与回弹、返回今天、普通历史自由滚动、无历史不分页、短尾页的舍入误差，以及日期提前切换和原有存储、日期分组、启动策略。日志：[核心测试](core-tests.log)、[编译](build.log)、[runner 失败](ui-runner-failure.log)。所有产物摘要见 [manifest.json](manifest.json)。

`UITests/LibraryTimelineUITests.swift` 已编译，待 XCTest 服务正常后执行四个手势场景。真机验收应包含空白页向下不触发、上滑弹入历史、从历史整页弹回、短拖不切页、普通历史连续滚动、跨日数字切换、首次保存，以及减少动态效果开启后的静态眼睛。物理震动以真机实际感受为准。

## 证据与结果对应

本节沿用普通逆向记录，`flavor = null`。范围是用户指定参考资料与本地重建工程，不涉及外部服务或原版后端。

| Evidence | 来源及复现 | 内容摘要 |
| --- | --- | --- |
| E-video | [视频逐帧记录](../video-2-evidence/notes.md)，其中包含原录像 hash 和抽帧命令 | 原版空白页运动、固定日期、数字方向与时间 |
| E-ipa | [REA 证据报告](../library-2.0.11-evidence/2026-10-19_逆向-CapWords词库-report.md) | 2.0.11 / 23、加密边界、空态中文和动画候选；含 Evidence IDs 与 hash |
| E-render | 本目录截图与录屏，复现 `capture_library.sh` | 重建版实际可见状态；摘要见 manifest |
| E-tests | `core-tests.log`、`build.log`，复现命令见上文 | 核心测试与编译成功 |
| E-runner | `ui-runner-failure.log` | XCTest 系统服务连接失败，手势自动化未执行 |

| Finding | severity | evidence_ids | confidence / status | location |
| --- | --- | --- | --- | --- |
| F-empty | n/a_re | E-video、E-render | high / validated（布局） | `LibraryView.groupContent` |
| F-dates | n/a_re | E-video、E-render | high / validated（渲染） | `LibraryDateHeading` |
| F-snap | n/a_re | E-tests、E-runner | medium / candidate（真实手势待验收） | `LibraryScrollPolicy`、UI tests |
| F-feedback | n/a_re | 用户文字要求、源码 | medium / candidate（触感待验收） | `LibraryScrollBehavior.onPageSnap` |

P-implementation（`path_type=solve`）：E-video 分离空白页与历史滚动 → E-ipa 确认静态证据边界 → 依据可见行为独立编写组件 → E-tests 检查边界 → E-render 核对布局 → E-runner 保留自动化限制。2026-10-19 的顺序记录：提取原录像；核对最新版 IPA；实现空态与固定日期；发现并修正底部露出和尾部高度误差；通过核心测试及编译；采集重建版截图与录屏。
