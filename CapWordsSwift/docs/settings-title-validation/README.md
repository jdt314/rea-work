# 个人标题随滚动收起

页面顶部保留左侧 32pt 的“个人”。上移最初 56pt 内，标题随实际滚动距离连续缩小、移向中央；收起后为 17pt，位于顶部 44pt 导航区域中央。继续滚动保持居中，下拉回顶部恢复大标题。滚动内容中的占位高度保持固定，避免标题切换导致列表跳动。顶部材质渐变在标题下方绘制，不模糊文字。

顶部安全区域和导航栏共用首页的 `ScrollTopEdge`：相同的 ultraThinMaterial、主题底色、渐变停点及 48pt 过渡高度。个人页不再叠加独立的导航栏底色，也不再使用单独的 16pt 渐变。标题在这层统一背景上方移动，收起前后不会切换背景处理方式。

滚动几何观察仅传递 0–56pt 的范围，超过收起距离不再随每一帧滚动重建标题。标题单独测量文字尺寸，居中位置支持中英文；辅助功能只暴露一个标题。

构建及 `build-for-testing` 编译通过。iPhone 17 Pro / iOS 26.1 模拟器分别在浅、深色模式下，用同一个进程回放“顶部 → 应用与账户 → 顶部”，核对收起位置及恢复后的排版。回放通过 Debug 的 ScrollViewReader 驱动真实滚动，不代表触摸自动化。

| 状态 | 浅色 | 深色 |
| --- | --- | --- |
| 顶部大标题 | [截图](light-expanded.png) | [截图](dark-expanded.png) |
| 收起后居中 | [截图](light-collapsed.png) | [截图](dark-collapsed.png) |
| 下拉恢复 | [截图](light-restored.png) | [截图](dark-restored.png) |

录屏：[浅色](light-scroll.mp4)、[深色](dark-scroll.mp4)。截图文字位置检查见 [checks.json](checks.json)，采集方式见 [metadata.json](metadata.json)。

复现：`bash CapWordsSwift/scripts/verify.sh build-for-testing`，然后运行 `python3 CapWordsSwift/scripts/capture_settings_title.py`。回放开关仅在 Debug 且传入 `--uitesting` 时生效。
