import Foundation
import CoreGraphics

enum ImagePlacement {
    static func aspectFill(source: CGSize, viewport: CGSize, normalizedRect: CGRect) -> CGRect {
        guard source.width > 0, source.height > 0 else { return .zero }
        let scale = max(viewport.width / source.width, viewport.height / source.height)
        let width = source.width * scale, height = source.height * scale
        return CGRect(x: (viewport.width - width) / 2 + normalizedRect.minX * width,
                      y: (viewport.height - height) / 2 + normalizedRect.minY * height,
                      width: normalizedRect.width * width, height: normalizedRect.height * height)
    }
}

enum AlphaGeometry {
    static func bounds(of image: CGImage) -> CGRect {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let bounds: CGRect? = pixels.withUnsafeMutableBytes { buffer in
            guard let ctx = CGContext(data: buffer.baseAddress, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            let bytes = buffer.bindMemory(to: UInt8.self)
            var minX = width, minY = height, maxX = 0, maxY = 0
            for y in 0..<height {
                for x in 0..<width where bytes[(y * width + x) * 4 + 3] > 24 {
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
            }
            guard minX <= maxX, minY <= maxY else { return .zero }
            return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        }
        return bounds ?? .zero
    }
}
