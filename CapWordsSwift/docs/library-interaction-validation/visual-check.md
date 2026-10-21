# 日期列表程序化滚动：图像验收

日期：2026-10-19。输入为 [programmatic-scroll.mov](programmatic-scroll.mov)，时长 11.025 秒，分辨率 1206 × 2622。启动参数为 `--uitesting --preview-timeline-motion`，录屏由程序化 `scrollTo` 驱动。本次仅检查可见布局与动画，不是手指拖动、吸附阈值或震动实测。

结论：本次可见行为没有明显阻塞。今天空白页停稳时占满屏幕，底部没有历史标题或贴纸漏出；眼睛与文案参与滚动；返回按钮、顶部日期、数量和底部相机保持固定。日期及计数随当前内容正确更新，数字方向与参考视频一致。

## 状态检查

图像总览：[每秒联系表](frames/contact-000.jpg)。表内时间采用 AVFoundation 返回的真实帧时间，未把请求的整数秒误当作实际视频 PTS。

| 实际时间 | 固定日期 / 数量 | 可见内容 | 结果 |
| --- | --- | --- | --- |
| 1.945、2.913 s | 10 月 19 / 0 个单词 | 空白今天；眼睛、两行文案、相机 | 历史内容未在底部漏出 |
| 3.995 s | 10 月 19 / 0 个单词 | 眼睛与文案已移近顶部，昨天标题和贴纸从下方进入 | 空白内容随滚动移动，相机固定 |
| 4.997 s | 10 月 18 / 4 个单词 | Switch、Binder clip、Tape、Monstera | 日期与数量正确 |
| 5.995 s | 10 月 18 / 4 个单词 | 昨天末行离开上方，更早日期标题与贴纸进入 | 历史组连续滚动 |
| 6.928 s | 10 月 17 / 2 个单词 | Bread、Toast；下方还有 10 月 16 | 日期与数量正确 |
| 7.995 s | 10 月 18 / 4 个单词 | 返回途中经过昨天，空白提示从上方进入 | 日期跟随过渡中的内容更新 |
| 8.930、9.998、10.997 s | 10 月 19 / 0 个单词 | 空白今天恢复；眼睛位置/形状变化 | 返回正确；底部没有下一日漏出 |

3.995 与 7.995 秒画面中的历史分组标题属于正在移动的正常滚动内容，不是空白页停稳后的漏出。9.998 秒眼睛接近闭合，其他相邻帧恢复睁眼，录像可见眨眼动画。

## 数字方向核对

逐帧范围为 3.6–4.8 秒，共 71 个实际视频样本，见 [逐帧元数据](transition-frames/metadata.json)。日期裁切放大图：[numeric-transition.jpg](numeric-transition.jpg)。

4.312–4.448 秒的 19 → 18 清楚显示：旧数字 9 向下移动并模糊离开，新数字 8 从上方落到原来的基线；未变化的“10 月 1”保持稳定。计数 0 → 4 同期更新。这与参考 [视频 2 的数字放大图](../video-2-evidence/digits-19-to-18.jpg) 方向相符。

该结论来自画面观察，适用于本次录屏中 `numericText(countsDown: true)` 的可见结果。没有用此录像证明触觉先后或真实手势释放后的响应。

## 复现

在仓库根目录执行，需要 macOS 的视频解码服务：

```sh
DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer swift -module-cache-path /tmp/capwords-video2-module-cache CapWordsSwift/scripts/extract_video_evidence.swift CapWordsSwift/docs/library-interaction-validation/programmatic-scroll.mov CapWordsSwift/docs/library-interaction-validation/frames 1
DEVELOPER_DIR=/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer swift -module-cache-path /tmp/capwords-video2-module-cache CapWordsSwift/scripts/extract_video_evidence.swift CapWordsSwift/docs/library-interaction-validation/programmatic-scroll.mov CapWordsSwift/docs/library-interaction-validation/transition-frames 0 3.6 4.8
```

每帧的请求时间与实际时间保存在各目录的 `metadata.json`。数字图仅裁切原始帧的 `(60, 320)–(390, 455)` 区域并加上实际 PTS 时间标签，没有补帧或重绘。

证据路径：录屏 → 原始帧及真实时间 → 固定日期/空白页/内容运动观察 → 数字局部放大 → 本文结论。

录屏后的最终需求修正：空白页向下滑不触发，仅上滑进入历史；从历史返回空白也使用整页动画。实现采用 36 pt 手势阈值和双向 0.28 秒 spring，起跳时触发一次 Haptics，普通历史组自由滚动。**这段旧的程序化录屏只支持布局与数字动画验收，不代表上述最终手势修正已经通过实际触摸或触觉验证。**
