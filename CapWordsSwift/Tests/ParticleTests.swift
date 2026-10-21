import Testing
import UIKit
@testable import CapWordsSwift

struct ParticleTests {
    @Test func releaseMovesAcrossPhotoBeforeAllFragmentsAge() {
        #expect(DustTiming.activation(x: 0, elapsed: 0) == 0)
        #expect(DustTiming.activation(x: 0, elapsed: 0.1) > 0.6)
        #expect(DustTiming.activation(x: 0.9, elapsed: 0.1) == 0)
        #expect(DustTiming.simulationAge(x: 0.9, elapsed: 0.1) == 0)
        #expect(DustTiming.activation(x: 0.99, elapsed: 0.4) == 1)
        let leftAge = DustTiming.simulationAge(x: 0, elapsed: 0.4)
        let rightAge = DustTiming.simulationAge(x: 0.99, elapsed: 0.4)
        #expect(leftAge > rightAge)
        // 激活完成后，真实 0.1 秒对应物理寿命的 0.2 个单位。
        let laterAge = DustTiming.simulationAge(x: 0.99, elapsed: 0.5)
        #expect(abs(laterAge - rightAge - 0.2) < 0.000001)
    }

    @Test func fragmentsFadeOnlyAtEndOfTheirOwnLifetime() {
        #expect(DustTiming.opacity(lifetime: 1.2, age: 0) == 1)
        #expect(DustTiming.opacity(lifetime: 1.2, age: 0.8) == 1)
        #expect(abs(DustTiming.opacity(lifetime: 1.2, age: 1.05) - 0.5) < 0.000001)
        #expect(DustTiming.opacity(lifetime: 1.2, age: 1.3) == 0)
        // 效果容器结束时，即便最右边、最长寿命的粒子也已经消失。
        let lastAge = DustTiming.simulationAge(x: 1, elapsed: DustTiming.duration)
        #expect(DustTiming.opacity(lifetime: 1.5, age: lastAge) == 0)
    }

    @Test func gravityUsesScreenUpAfterClipSpaceConversion() {
        let offset = DustTiming.screenOffset(angle: 0, speed: 42, age: 0.5)
        #expect(abs(offset.width - 21) < 0.000001)
        #expect(abs(offset.height + 15) < 0.000001)
    }

    @Test @MainActor func subjectMaskAndPhotoShareTopOrigin() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let source = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 200), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 100, width: 100, height: 100))
        }
        // 主体内部也不对称：仅上半部有 alpha，可同时抓到 mask 平移和内部翻转。
        let subject = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 40), format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        let sourceData = try #require(source.pngData())
        let subjectData = try #require(subject.pngData())
        let samples = await DustSampler.sample(sourceData, subjectData: subjectData,
                                                subjectRect: CGRect(x: 0.2, y: 0.1, width: 0.2, height: 0.2))
        func sample(x: Double, y: Double) -> DustPixel? {
            samples.first { abs($0.x - x) < 0.0001 && abs($0.y - y) < 0.0001 }
        }
        #expect(sample(x: 0.25, y: 0.15) == nil)
        let clearHalf = try #require(sample(x: 0.25, y: 0.25))
        #expect(clearHalf.r > 0.95 && clearHalf.b < 0.05)
        let lowerPhoto = try #require(sample(x: 0.25, y: 0.75))
        #expect(lowerPhoto.b > 0.95 && lowerPhoto.r < 0.05)
        let texture = try #require(samples.first?.texture)
        #expect(texture.rgba[(30 * texture.width + 25) * 4 + 3] == 0)
        #expect(texture.rgba[(150 * texture.width + 25) * 4 + 3] == 255)
    }

    @Test @MainActor func samplingPreservesFineTextureAndIndependentRandomProperties() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 40), format: format).image { context in
            for x in 0..<80 {
                (x.isMultiple(of: 2) ? UIColor.red : UIColor.blue).setFill()
                context.fill(CGRect(x: x, y: 0, width: 1, height: 40))
            }
        }
        let samples = await DustSampler.sample(try #require(image.pngData()), subjectData: nil, subjectRect: .zero)
        #expect(samples.count == 80 * 40)
        let texture = try #require(samples.first?.texture)
        #expect(texture.width == 80 && texture.height == 40)
        #expect(texture.rgba[0] > 240 && texture.rgba[6] > 240)
        #expect(samples.allSatisfy { (42...84).contains($0.speed) && (0.7...1.5).contains($0.lifetime) })
        let difference = samples.prefix(256).reduce(0.0) { total, particle in
            total + abs((particle.speed - 42) / 42 - (particle.lifetime - 0.7) / 0.8)
        } / 256
        #expect(difference > 0.2)
    }
}
