import SwiftUI
import UIKit
import MetalKit

struct DustPixel: Sendable {
    let x: Double, y: Double
    let width: Double, height: Double
    let r: Double, g: Double, b: Double
    let angle: Double, speed: Double, lifetime: Double
    // 仅首个粒子持有整张已解码纹理。
    var texture: DustTexture? = nil
}

final class DustTexture: Sendable {
    let width: Int, height: Int
    let rgba: Data

    init(width: Int, height: Int, rgba: Data) {
        self.width = width
        self.height = height
        self.rgba = rgba
    }
}

enum DustTiming {
    static let duration = 4.0 / 2.2
    static let phaseSpeed = 2.2
    static let activationWindow = 0.8
    static let releaseSpeed = 2.25 * phaseSpeed

    static func activation(x: Double, elapsed: Double) -> Double {
        min(1, max(0, (min(0.8, max(0, elapsed) * phaseSpeed) * 2.25 - x) / activationWindow))
    }

    // 积分 2 * activation * dt；phase 推进、物理步长、容器期限是独立的量。
    // 静帧与实时播放使用同一条轨迹，避免丢帧累积误差。
    static func simulationAge(x: Double, elapsed: Double) -> Double {
        let activeTime = max(0, elapsed - x / releaseSpeed)
        let ramp = activationWindow / releaseSpeed
        if activeTime < ramp { return activeTime * activeTime / ramp }
        return 2 * activeTime - ramp
    }

    static func opacity(lifetime: Double, age: Double) -> Double {
        min(1, max(0, (lifetime - age) / 0.3))
    }

    static func screenOffset(angle: Double, speed: Double, age: Double, scale: Double = 1) -> CGSize {
        // 原 shader 的正 Y 是裁剪坐标向上，这里统一为 UIKit 左上角坐标。
        CGSize(width: cos(angle) * speed * age * scale,
               height: -(sin(angle) * speed * age + 60 * age * age) * scale)
    }
}

enum DustSampler {
    static func sample(_ data: Data, subjectData: Data?, subjectRect: CGRect) async -> [DustPixel] {
        let job = Task.detached(priority: .userInitiated) {
            sampleImage(data, subjectData: subjectData, subjectRect: subjectRect)
        }
        return await withTaskCancellationHandler(operation: { await job.value }, onCancel: { job.cancel() })
    }

    private static func sampleImage(_ data: Data, subjectData: Data?, subjectRect: CGRect) -> [DustPixel] {
        guard let original = normalizedImage(data) else { return [] }
        let scale = min(1, 720.0 / Double(max(original.width, original.height)))
        let width = max(1, Int(Double(original.width) * scale))
        let height = max(1, Int(Double(original.height) * scale))
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        guard var bytes = raster(original, width: width, height: height, rect: bounds) else { return [] }
        var mask: [UInt8]?
        if let subjectData, let subject = normalizedImage(subjectData), !subjectRect.isEmpty {
            // 对外统一左上角坐标；到 CGContext 的坐标转换只在 raster 内做一次。
            let rect = CGRect(x: subjectRect.minX * CGFloat(width), y: subjectRect.minY * CGFloat(height),
                              width: subjectRect.width * CGFloat(width), height: subjectRect.height * CGFloat(height))
            mask = raster(subject, width: width, height: height, rect: rect)
        }
        var samples: [DustPixel] = []
        samples.reserveCapacity(width * height)
        for y in 0..<height {
            guard !Task.isCancelled else { return [] }
            for x in 0..<width {
                let index = y * width + x
                let offset = index * 4
                if let mask {
                    let background = 255 - Int(mask[offset + 3])
                    for component in 0..<4 {
                        bytes[offset + component] = UInt8(Int(bytes[offset + component]) * background / 255)
                    }
                }
                guard bytes[offset + 3] > 0 else { continue }
                let alpha = Double(bytes[offset + 3])
                samples.append(DustPixel(x: Double(x) / Double(width), y: Double(y) / Double(height),
                                         width: 1 / Double(width), height: 1 / Double(height),
                                         r: Double(bytes[offset]) / alpha, g: Double(bytes[offset + 1]) / alpha,
                                         b: Double(bytes[offset + 2]) / alpha,
                                         angle: random(index, lane: 0) * 2 * .pi,
                                         speed: 42 + random(index, lane: 1) * 42,
                                         lifetime: 0.7 + random(index, lane: 2) * 0.8))
            }
        }
        if !samples.isEmpty {
            samples[0].texture = DustTexture(width: width, height: height, rgba: Data(bytes))
        }
        return samples
    }

    private static func normalizedImage(_ data: Data) -> CGImage? {
        guard let image = UIImage(data: data) else { return nil }
        if image.imageOrientation == .up { return image.cgImage }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }.cgImage
    }

    private static func raster(_ image: CGImage, width: Int, height: Int, rect: CGRect) -> [UInt8]? {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                                            | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.interpolationQuality = .high
            let quartzRect = CGRect(x: rect.minX, y: CGFloat(height) - rect.maxY,
                                    width: rect.width, height: rect.height)
            context.draw(image, in: quartzRect)
            return true
        }
        return drawn ? bytes : nil
    }

    private static func random(_ index: Int, lane: UInt32) -> Double {
        var value = UInt32(truncatingIfNeeded: index) &+ (lane &+ 1) &* 0x9E3779B9
        value = (value ^ (value >> 16)) &* 0x85EBCA6B
        value = (value ^ (value >> 13)) &* 0xC2B2AE35
        value ^= value >> 16
        return Double(value) / Double(UInt32.max)
    }
}

// 原图纹理的独立背景层；前景贴纸由 CaptureView 保留在它上方。
struct PhotoDustView: View {
    let pixels: [DustPixel]
    let start: Date
    let sourceSize: CGSize
    var elapsedOverride: TimeInterval? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var metalFailed = false

    var body: some View {
        Group {
            if !reduceMotion {
                if !metalFailed, pixels.first?.texture != nil, DustMetalResources.shared != nil {
                    DustMetalView(pixels: pixels, start: start, sourceSize: sourceSize, elapsedOverride: elapsedOverride) {
                        metalFailed = true
                    }
                } else {
                    DustFallbackView(pixels: pixels, start: start, sourceSize: sourceSize, elapsedOverride: elapsedOverride)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}


private struct DustGPUCell {
    var rect: SIMD4<Float>
    var motion: SIMD4<Float>
}

private struct DustGPUFrame {
    var imageRect: SIMD4<Float>
    var viewport: SIMD2<Float>
    var elapsed: Float
    var motionScale: Float
}

@MainActor private final class DustMetalResources {
    static let shared = DustMetalResources()
    let device: MTLDevice
    let queue: MTLCommandQueue
    let pipeline: MTLRenderPipelineState

    private init?() {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else { return nil }
        do {
            // 独立实现已验证的运动语义；运行时编译不依赖额外 Metal 工具链下载。
            let library = try device.makeLibrary(source: Self.source, options: nil)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "photoFragmentVertex")
            descriptor.fragmentFunction = library.makeFunction(name: "photoFragmentColor")
            let color = descriptor.colorAttachments[0]!
            color.pixelFormat = .bgra8Unorm
            color.isBlendingEnabled = true
            color.sourceRGBBlendFactor = .one
            color.destinationRGBBlendFactor = .oneMinusSourceAlpha
            color.sourceAlphaBlendFactor = .one
            color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
            self.device = device
            self.queue = queue
        } catch { return nil }
    }

    private static let source = """
    #include <metal_stdlib>
    using namespace metal;
    struct Cell { float4 rect; float4 motion; };
    struct Frame { float4 imageRect; float2 viewport; float elapsed; float motionScale; };
    struct Varying { float4 position [[position]]; float2 uv; float alpha; };
    vertex Varying photoFragmentVertex(uint vertexID [[vertex_id]], uint cellID [[instance_id]],
                                       const device Cell *cells [[buffer(0)]], constant Frame &frame [[buffer(1)]]) {
        const float2 corners[6] = {float2(0,0), float2(1,0), float2(0,1),
                                   float2(1,0), float2(1,1), float2(0,1)};
        Cell cell = cells[cellID];
        float activeTime = max(0.0f, frame.elapsed - cell.rect.x / 4.95f);
        float ramp = 0.8f / 4.95f;
        float age = activeTime < ramp ? activeTime * activeTime / ramp : 2.0f * activeTime - ramp;
        float2 drift = cell.motion.xy * age;
        drift.y += 60.0f * age * age;
        drift.y = -drift.y;
        float2 uv = cell.rect.xy + corners[vertexID] * cell.rect.zw;
        float2 point = frame.imageRect.xy + uv * frame.imageRect.zw + drift * frame.motionScale;
        Varying output;
        output.position = float4(2.0f * point.x / frame.viewport.x - 1.0f,
                                 1.0f - 2.0f * point.y / frame.viewport.y, 0, 1);
        output.uv = uv;
        output.alpha = clamp((cell.motion.z - age) / 0.3f, 0.0f, 1.0f);
        return output;
    }
    fragment half4 photoFragmentColor(Varying input [[stage_in]], texture2d<half> photo [[texture(0)]]) {
        constexpr sampler imageSampler(coord::normalized, address::clamp_to_edge, filter::linear);
        return photo.sample(imageSampler, input.uv) * half(input.alpha);
    }
    """
}

private struct DustMetalView: UIViewRepresentable {
    let pixels: [DustPixel]
    let start: Date
    let sourceSize: CGSize
    let elapsedOverride: TimeInterval?
    let onFailure: @MainActor () -> Void

    func makeCoordinator() -> DustMetalRenderer { DustMetalRenderer() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: DustMetalResources.shared?.device)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.delegate = context.coordinator
        if !context.coordinator.prepare(pixels: pixels) {
            Task { @MainActor in onFailure() }
        }
        context.coordinator.update(start: start, sourceSize: sourceSize, elapsedOverride: elapsedOverride, view: view)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        if context.coordinator.textureID != pixels.first?.texture.map(ObjectIdentifier.init),
           !context.coordinator.prepare(pixels: pixels) {
            Task { @MainActor in onFailure() }
        }
        context.coordinator.update(start: start, sourceSize: sourceSize, elapsedOverride: elapsedOverride, view: view)
    }

    static func dismantleUIView(_ view: MTKView, coordinator: DustMetalRenderer) {
        view.isPaused = true
        view.delegate = nil
        coordinator.releaseResources()
        view.releaseDrawables()
    }
}

@MainActor private final class DustMetalRenderer: NSObject, MTKViewDelegate {
    var textureID: ObjectIdentifier?
    private var texture: MTLTexture?
    private var cells: MTLBuffer?
    private var count = 0
    private var start = Date.now
    private var sourceSize = CGSize.zero
    private var elapsedOverride: TimeInterval?
    private var textureHeight = 1

    func prepare(pixels: [DustPixel]) -> Bool {
        guard let resources = DustMetalResources.shared, let source = pixels.first?.texture else { return false }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                width: source.width, height: source.height, mipmapped: false)
        descriptor.usage = .shaderRead
        descriptor.storageMode = .shared
        guard let texture = resources.device.makeTexture(descriptor: descriptor) else { return false }
        source.rgba.withUnsafeBytes { bytes in
            if let base = bytes.baseAddress {
                texture.replace(region: MTLRegionMake2D(0, 0, source.width, source.height), mipmapLevel: 0,
                                withBytes: base, bytesPerRow: source.width * 4)
            }
        }
        let packed = pixels.map { pixel in
            DustGPUCell(rect: SIMD4(Float(pixel.x), Float(pixel.y), Float(pixel.width), Float(pixel.height)),
                        motion: SIMD4(Float(cos(pixel.angle) * pixel.speed), Float(sin(pixel.angle) * pixel.speed),
                                      Float(pixel.lifetime), 0))
        }
        let buffer = packed.withUnsafeBytes { bytes -> MTLBuffer? in
            guard let base = bytes.baseAddress else { return nil }
            return resources.device.makeBuffer(bytes: base, length: bytes.count, options: .storageModeShared)
        }
        guard let buffer else { return false }
        self.texture = texture
        cells = buffer
        count = packed.count
        textureID = ObjectIdentifier(source)
        textureHeight = source.height
        return true
    }

    func update(start: Date, sourceSize: CGSize, elapsedOverride: TimeInterval?, view: MTKView) {
        self.start = start
        self.sourceSize = sourceSize
        self.elapsedOverride = elapsedOverride
        view.isPaused = elapsedOverride != nil || Date.now.timeIntervalSince(start) >= DustTiming.duration
        if view.isPaused { view.draw() }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if view.isPaused { view.draw() }
    }

    func draw(in view: MTKView) {
        guard view.bounds.width > 0, view.bounds.height > 0,
              let resources = DustMetalResources.shared,
              let renderPass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let command = resources.queue.makeCommandBuffer(),
              let encoder = command.makeRenderCommandEncoder(descriptor: renderPass) else { return }
        let elapsed = max(0, elapsedOverride ?? Date.now.timeIntervalSince(start))
        if elapsed < DustTiming.duration, let cells, let texture {
            let imageRect = ImagePlacement.aspectFill(source: sourceSize, viewport: view.bounds.size,
                                                     normalizedRect: CGRect(x: 0, y: 0, width: 1, height: 1))
            var frame = DustGPUFrame(imageRect: SIMD4(Float(imageRect.minX), Float(imageRect.minY),
                                                      Float(imageRect.width), Float(imageRect.height)),
                                     viewport: SIMD2(Float(view.bounds.width), Float(view.bounds.height)),
                                     elapsed: Float(elapsed), motionScale: Float(imageRect.height) / Float(textureHeight))
            encoder.setRenderPipelineState(resources.pipeline)
            encoder.setVertexBuffer(cells, offset: 0, index: 0)
            encoder.setVertexBytes(&frame, length: MemoryLayout<DustGPUFrame>.stride, index: 1)
            encoder.setFragmentTexture(texture, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: count)
        }
        encoder.endEncoding()
        command.present(drawable)
        command.commit()
        if elapsed >= DustTiming.duration {
            view.isPaused = true
            releaseResources()
        }
    }

    func releaseResources() {
        texture = nil
        cells = nil
        count = 0
        textureID = nil
    }
}

// Metal 不可用时仍然可见：降低网格密度，保留相同的释放方向和寿命尾段。
private struct DustFallbackView: View {
    let pixels: [DustPixel]
    let start: Date
    let sourceSize: CGSize
    let elapsedOverride: TimeInterval?
    @State private var finished = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: elapsedOverride != nil || finished)) { timeline in
            let elapsed = max(0, elapsedOverride ?? timeline.date.timeIntervalSince(start))
            Canvas { context, size in
                guard elapsed < DustTiming.duration else { return }
                let imageRect = ImagePlacement.aspectFill(source: sourceSize, viewport: size,
                                                         normalizedRect: CGRect(x: 0, y: 0, width: 1, height: 1))
                let texture = pixels.first?.texture
                let stride = texture == nil ? 1 : 4
                let scale = texture.map { Double(imageRect.height) / Double($0.height) } ?? 1
                for pixel in pixels {
                    if stride > 1 {
                        let column = Int((pixel.x / pixel.width).rounded())
                        let row = Int((pixel.y / pixel.height).rounded())
                        guard column % stride == 0, row % stride == 0 else { continue }
                    }
                    let age = DustTiming.simulationAge(x: pixel.x, elapsed: elapsed)
                    let opacity = DustTiming.opacity(lifetime: pixel.lifetime, age: age)
                    guard opacity > 0 else { continue }
                    let drift = DustTiming.screenOffset(angle: pixel.angle, speed: pixel.speed, age: age, scale: scale)
                    let rect = CGRect(x: imageRect.minX + pixel.x * imageRect.width + drift.width,
                                      y: imageRect.minY + pixel.y * imageRect.height + drift.height,
                                      width: pixel.width * imageRect.width * Double(stride),
                                      height: pixel.height * imageRect.height * Double(stride))
                    context.opacity = opacity
                    context.fill(Path(rect), with: .color(Color(red: pixel.r, green: pixel.g, blue: pixel.b)))
                }
            }
        }
        .task(id: start) {
            finished = false
            guard elapsedOverride == nil else { return }
            let remaining = max(0, DustTiming.duration - Date.now.timeIntervalSince(start))
            do {
                try await Task.sleep(for: .seconds(remaining))
                finished = true
            } catch { }
        }
    }
}

// 两个页面共享屏幕坐标，目标仅由实际词库布局提供。
@MainActor @Observable
final class StickerFlightState {
    var targetID: UUID?
    var targetFrame: CGRect?
    var isFlying = false
}

struct SubjectEnergyView: View {
    let data: Data
    let start: Date
    var result = false
    var elapsedOverride: TimeInterval? = nil
    var dotSpacing: CGFloat = 19
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || elapsedOverride != nil)) { timeline in
            let elapsed = reduceMotion ? 0 : max(0, elapsedOverride ?? timeline.date.timeIntervalSince(start))
            let pulse = (sin(elapsed * .pi * 2 / 2.4) + 1) / 2
            ZStack {
                if result {
                    Ellipse()
                        .fill(RadialGradient(colors: [Color(red: 1, green: 0.91, blue: 0.35).opacity(0.50 + pulse * 0.14),
                                                      Color(red: 1, green: 0.96, blue: 0.66).opacity(0.28), .clear],
                                             center: .center, startRadius: 10, endRadius: 130))
                        .blur(radius: 14)
                        .scaleEffect(1.02 + pulse * 0.09)
                }
                // 视频的彩色点阵在主体周围呼吸，中心留空，边缘渐隐。
                // 不需要解码图片；点阵是背景层，与上方贴纸共用中心。
                Canvas { context, size in
                    let spacing = max(1, dotSpacing)
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let extent = max(1, min(size.width, size.height) / 2)
                    for row in 0...Int(size.height / spacing) {
                        for column in 0...Int(size.width / spacing) {
                            let x = CGFloat(column) * spacing
                            let y = CGFloat(row) * spacing
                            let nx = Double((x - center.x) / extent)
                            let ny = Double((y - center.y) / extent)
                            let distance = sqrt(nx * nx + ny * ny)
                            let edge = max(0, 1 - pow(distance / (0.90 + pulse * 0.18), 4))
                            let centerOpening = min(1, distance / 0.55)
                            let envelope = edge * centerOpening
                            guard envelope > 0 else { continue }
                            let shimmer = 0.72 + 0.28 * sin(elapsed * 2.1 - distance * 5)
                            let hue = 0.47 + ny * 0.22 + nx * 0.14
                            let alpha = envelope * (0.22 + pulse * 0.32) * shimmer * (result ? 0.5 : 1)
                            let diameter = 1 + envelope * (1 + pulse * 2)
                            context.fill(Path(ellipseIn: CGRect(x: x - diameter / 2, y: y - diameter / 2,
                                                                width: diameter, height: diameter)),
                                         with: .color(Color(hue: hue, saturation: 0.65, brightness: 0.85).opacity(alpha)))
                        }
                    }
                    if result {
                        for index in 0..<3 {
                            let phase = elapsed * 2.2 + Double(index) * 2.1
                            let brightness = max(0, sin(phase))
                            let anchors = [CGPoint(x: 0.29, y: 0.32), CGPoint(x: 0.72, y: 0.38), CGPoint(x: 0.60, y: 0.68)]
                            let anchor = anchors[index]
                            let x = size.width * anchor.x, y = size.height * anchor.y
                            let radius = 2 + brightness * 4
                            var star = Path()
                            star.move(to: CGPoint(x: x, y: y - radius))
                            star.addQuadCurve(to: CGPoint(x: x + radius, y: y), control: CGPoint(x: x + 1, y: y - 1))
                            star.addQuadCurve(to: CGPoint(x: x, y: y + radius), control: CGPoint(x: x + 1, y: y + 1))
                            star.addQuadCurve(to: CGPoint(x: x - radius, y: y), control: CGPoint(x: x - 1, y: y + 1))
                            star.addQuadCurve(to: CGPoint(x: x, y: y - radius), control: CGPoint(x: x - 1, y: y - 1))
                            context.fill(star, with: .color(.white.opacity(brightness * 0.9)))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
