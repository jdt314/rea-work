import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// 从项目根目录运行：swift scripts/generate_launch_bands.swift
// 本地重建图案，不是 IPA 导出的原版素材。固定 sRGB、无透明度、显式原色渲染。
// 系统启动页、主窗口首帧遮罩、条带动画共用输出，直接打包 PNG 避免系统图集加载失败。
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let output = root.appendingPathComponent("App/Resources/LaunchArtwork")
let width = 393, height = 852
let palette: [UInt32] = [0xFFE8A6, 0xFFE082, 0xFFD95C, 0xFFCF42, 0xFFC236, 0xFFB330]
let space = CGColorSpace(name: CGColorSpace.sRGB)!
for scale in 1...3 {
    let context = CGContext(data: nil, width: width * scale, height: height * scale,
                            bitsPerComponent: 8, bytesPerRow: 0, space: space,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.translateBy(x: 0, y: CGFloat(height * scale))
    context.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))
    let bandHeight = CGFloat(height) / 4.4
    for index in -1..<7 {
        let color = palette[min(max(index, 0), palette.count - 1)]
        context.setFillColor(CGColor(colorSpace: space, components: [
            CGFloat((color >> 16) & 255) / 255, CGFloat((color >> 8) & 255) / 255,
            CGFloat(color & 255) / 255, 1
        ])!)
        let top = CGFloat(index) * bandHeight
        let rightOffset = 0.58 * CGFloat(width)
        context.move(to: CGPoint(x: 0, y: top))
        context.addLine(to: CGPoint(x: CGFloat(width), y: top - rightOffset))
        context.addLine(to: CGPoint(x: CGFloat(width), y: top + bandHeight + 1 - rightOffset))
        context.addLine(to: CGPoint(x: 0, y: top + bandHeight + 1))
        context.closePath()
        context.fillPath()
    }
    let suffix = scale == 1 ? "" : "@\(scale)x"
    let path = output.appendingPathComponent("launch-bands\(suffix).png")
    let destination = CGImageDestinationCreateWithURL(path as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("无法写入 \(path.path)") }
    print("\(path.lastPathComponent): \(width * scale) × \(height * scale)")
}
