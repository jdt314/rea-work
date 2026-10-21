import Foundation
import AVFoundation
import AppKit
import CoreText

// swift -module-cache-path /tmp/capwords-video-module-cache scripts/extract_video_evidence.swift SOURCE OUTPUT [STEP [START [END]]]
// STEP=0 按轨道内每个样本的真实 PTS 抽取，不以稀疏时间间隔排除短暂闪帧。
let args = CommandLine.arguments
guard args.count >= 3 else { fatalError("Expected source and output directory") }
let source = URL(fileURLWithPath: args[1])
let output = URL(fileURLWithPath: args[2], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let asset = AVURLAsset(url: source)
let duration = CMTimeGetSeconds(asset.duration)
let track = asset.tracks(withMediaType: .video).first!
let step = args.count > 3 ? Double(args[3])! : 1
let start = args.count > 4 ? Double(args[4])! : 0
let end = args.count > 5 ? min(Double(args[5])!, duration - 0.001) : duration - 0.001
precondition(step.isFinite && step >= 0 && end >= start, "STEP 必须非负，END 必须不早于 START")
let sampleTimes: [CMTime]
if step == 0 {
    let reader = try AVAssetReader(asset: asset)
    let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
    trackOutput.alwaysCopiesSampleData = false
    reader.add(trackOutput)
    guard reader.startReading() else { throw reader.error! }
    var timestamps: [CMTime] = []
    while let sample = trackOutput.copyNextSampleBuffer() {
        let time = CMSampleBufferGetPresentationTimeStamp(sample)
        if time.seconds >= start && time.seconds <= end { timestamps.append(time) }
    }
    if reader.status == .failed { throw reader.error! }
    sampleTimes = timestamps.sorted { $0.seconds < $1.seconds }
} else {
    sampleTimes = stride(from: start, through: end, by: step).map { CMTime(seconds: $0, preferredTimescale: 60000) }
}
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
var records: [[String: Any]] = []
var frames: [(CGImage, Double)] = []
for time in sampleTimes {
    let seconds = time.seconds
    var actual = CMTime.zero
    let image = try generator.copyCGImage(at: time, actualTime: &actual)
    let filename = String(format: "t%07d.jpg", Int((seconds * 1000).rounded()))
    let bitmap = NSBitmapImageRep(cgImage: image)
    try bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])!.write(to: output.appendingPathComponent(filename))
    records.append(["file": filename, "requestedSeconds": seconds, "actualSeconds": CMTimeGetSeconds(actual)])
    // 联系表只保留缩略图，逐帧验证长视频时不将全部原尺寸帧驻留内存。
    let thumbWidth = 180
    let thumbHeight = Int(CGFloat(image.height) * CGFloat(thumbWidth) / CGFloat(image.width))
    let thumbnail = CGContext(data: nil, width: thumbWidth, height: thumbHeight, bitsPerComponent: 8,
                              bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    thumbnail.draw(image, in: CGRect(x: 0, y: 0, width: thumbWidth, height: thumbHeight))
    frames.append((thumbnail.makeImage()!, CMTimeGetSeconds(actual)))
}
let meta: [String: Any] = ["source": source.path, "durationSeconds": duration,
    "naturalWidth": track.naturalSize.width, "naturalHeight": track.naturalSize.height,
    "nominalFrameRate": track.nominalFrameRate, "frames": records,
    "sampling": step == 0 ? "every encoded video sample presentation timestamp" : "fixed interval \(step) seconds",
    "extraction": "AVAssetImageGenerator with zero requested time tolerance; actual times recorded"]
try JSONSerialization.data(withJSONObject: meta, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("metadata.json"))

let cols = 6, rows = 4, cellW = 180, cellH = 420
for begin in stride(from: 0, to: frames.count, by: cols * rows) {
    let context = CGContext(data: nil, width: cols * cellW, height: rows * cellH, bitsPerComponent: 8,
                            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.setFillColor(CGColor(gray: 0.90, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: cols * cellW, height: rows * cellH))
    for (offset, item) in frames[begin..<min(begin + cols * rows, frames.count)].enumerated() {
        let x = (offset % cols) * cellW, y = (rows - 1 - offset / cols) * cellH
        let scale = min(CGFloat(cellW) / CGFloat(item.0.width), CGFloat(cellH - 24) / CGFloat(item.0.height))
        let w = CGFloat(item.0.width) * scale, h = CGFloat(item.0.height) * scale
        context.draw(item.0, in: CGRect(x: CGFloat(x) + (CGFloat(cellW) - w) / 2, y: CGFloat(y), width: w, height: h))
        let label = NSAttributedString(string: String(format: "%.3f s", item.1), attributes: [.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), .foregroundColor: NSColor.black])
        context.textPosition = CGPoint(x: x + 5, y: y + cellH - 18)
        CTLineDraw(CTLineCreateWithAttributedString(label), context)
    }
    let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
    try bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.88])!.write(to: output.appendingPathComponent(String(format: "contact-%03d.jpg", begin / (cols * rows))))
}
print("duration=\(duration), size=\(track.naturalSize), fps=\(track.nominalFrameRate), extracted=\(records.count), output=\(output.path)")
