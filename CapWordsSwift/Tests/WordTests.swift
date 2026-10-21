import Testing
import SwiftData
import UIKit
@testable import CapWordsSwift

struct WordTests {
    @Test @MainActor func firstFrameCoverDoesNotDependOnAppearanceCallback() {
        let launch = LaunchCoordinator()
        #expect(launch.isVisible)
        #expect(launch.needsFirstFrameCover)
        // 还没有动画窗口时，错误的提前退场通知也不能撤掉兜底。
        launch.beginContentReveal()
        #expect(launch.needsFirstFrameCover)
        launch.finish()
        #expect(!launch.needsFirstFrameCover)
        let skipped = LaunchCoordinator(skipAnimation: true)
        #expect(!skipped.needsFirstFrameCover)
    }

    @Test @MainActor func launchScreenKeepsFullBleedBandsAndCenteredLogo() throws {
        #expect(Bundle.main.url(forResource: "launch-bands", withExtension: "png") != nil)
        #expect(LaunchArtwork.bands.size == CGSize(width: 393, height: 852))
        #expect(Bundle.main.object(forInfoDictionaryKey: "UILaunchStoryboardName") as? String == "LaunchScreen")
        #expect(Bundle.main.object(forInfoDictionaryKey: "UILaunchScreen") == nil)
        let controller = try #require(UIStoryboard(name: "LaunchScreen", bundle: .main).instantiateInitialViewController())
        controller.loadViewIfNeeded()
        let view = try #require(controller.view)
        let images = view.subviews.compactMap { $0 as? UIImageView }
        #expect(images.count == 2)
        let background = try #require(images.first)
        let logo = try #require(images.last)
        #expect(background.image != nil)
        #expect(background.image?.renderingMode != .alwaysTemplate)
        #expect(logo.image != nil)
        #expect(background.contentMode == .scaleAspectFill)
        #expect(logo.contentMode == .scaleAspectFit)
        for size in [CGSize(width: 393, height: 852), CGSize(width: 402, height: 874), CGSize(width: 430, height: 932)] {
            view.frame = CGRect(origin: .zero, size: size)
            view.setNeedsLayout()
            view.layoutIfNeeded()
            #expect(background.frame == view.bounds)
            #expect(logo.bounds.size == CGSize(width: 86, height: 86))
            #expect(abs(logo.center.x - view.bounds.midX) < 0.5)
            #expect(abs(logo.center.y - view.bounds.midY) < 0.5)
        }
    }

    @Test func reviewIntervalsAndReset() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let first = ReviewSchedule.next(stage: 0, remembered: true, now: now)
        #expect(first.stage == 1)
        #expect(Calendar.current.dateComponents([.day], from: now, to: first.date).day == 1)
        let failed = ReviewSchedule.next(stage: 4, remembered: false, now: now)
        #expect(failed.stage == 1)
        #expect(Calendar.current.dateComponents([.day], from: now, to: failed.date).day == 1)
        #expect(ReviewSchedule.next(stage: 100, remembered: true).stage == 4)
        #expect(ReviewSchedule.next(stage: -20, remembered: true).stage == 1)
        #expect(Calendar.current.dateComponents([.day], from: now, to: ReviewSchedule.next(stage: 1, remembered: true, now: now).date).day == 2)
        #expect(Calendar.current.dateComponents([.day], from: now, to: ReviewSchedule.next(stage: 2, remembered: true, now: now).date).day == 4)
        #expect(ReviewSchedule.next(stage: 3, remembered: true, now: now).date == .distantFuture)
    }

    @Test @MainActor func reviewQueueLimitsOnlyNewWordsAndExcludesMastered() {
        let now = Date.now
        let fresh = (0..<8).map { index in Word(name: "new\(index)", meaning: "新词", createdAt: now.addingTimeInterval(Double(index))) }
        let due = Word(name: "due", meaning: "到期", createdAt: now.addingTimeInterval(-100))
        due.reviewCount = 1; due.reviewStage = 1
        let mastered = Word(name: "mastered", meaning: "掌握", createdAt: now.addingTimeInterval(-200))
        mastered.reviewCount = 4; mastered.reviewStage = 4
        let future = Word(name: "future", meaning: "未到期", createdAt: now)
        future.reviewCount = 1; future.nextReviewAt = now.addingTimeInterval(1000)
        let result = ReviewQueue.make(words: fresh + [due, mastered, future], newLimit: 5, now: now)
        #expect(result.map(\.name) == ["due", "new0", "new1", "new2", "new3", "new4"])
    }

    @Test func classificationAliasesAndUnknowns() {
        #expect(Vocabulary.match("doughnut")?.meaning == "甜甜圈")
        #expect(Vocabulary.match("coffee mug, mug")?.key == "cup")
        #expect(Vocabulary.match("unrecognized_object") == nil)
        #expect(Vocabulary.match("donut")?.name(in: .japanese) == "ドーナツ")
        #expect(Vocabulary.match("donut")?.name(in: .english) == "Donut")
    }

    @Test @MainActor func seedIsIdempotentAndDeletionPersists() throws {
        let container = try ModelContainer(for: Word.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        try SeedLibrary.insert(into: context)
        try SeedLibrary.insert(into: context)
        let words = try context.fetch(FetchDescriptor<Word>())
        #expect(words.count == 9)
        let word = try #require(words.first)
        word.name = "Updated word"
        word.imageData = Data([1, 2, 3])
        try context.save()
        let secondContext = ModelContext(container)
        let saved = try secondContext.fetch(FetchDescriptor<Word>())
        #expect(saved.contains { $0.name == "Updated word" && $0.imageData == Data([1, 2, 3]) })
        context.delete(word)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Word>()) == 8)
    }

    @Test func cropClampsOffsetsAndUsesSquareOutput() throws {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let source = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200), format: format).image { ctx in
            UIColor.red.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
            UIColor.blue.setFill(); ctx.fill(CGRect(x: 200, y: 0, width: 200, height: 200))
        }
        let data = try #require(ImageCropRenderer.render(image: source, viewport: 200, zoom: 1, offset: CGSize(width: 9999, height: 9999)))
        let output = try #require(UIImage(data: data))
        #expect(output.size == CGSize(width: 1000, height: 1000))
        let cgImage = try #require(output.cgImage)
        var pixel = [UInt8](repeating: 0, count: 4)
        let color = CGColorSpaceCreateDeviceRGB()
        let context = try #require(CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8,
                                           bytesPerRow: 4, space: color, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        // 偏移夹在最右侧合法值，视口只显示原图左半部红色，没有露出空白。
        #expect(pixel[0] > 240)
        #expect(pixel[2] < 20)
        #expect(ImageCropRenderer.render(image: source, viewport: 0, zoom: 1, offset: .zero) == nil)
    }

    @Test func invalidPhotoFails() async {
        do {
            _ = try await RecognitionService.shared.recognize(data: Data([0, 1, 2]), language: .english)
            Issue.record("无效图片不应识别成功")
        } catch { #expect(error is RecognitionError) }
    }

    @Test func subjectBoundsAndAspectFillCoordinates() throws {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 200), format: format).image { ctx in
            UIColor.red.setFill(); ctx.fill(CGRect(x: 20, y: 30, width: 40, height: 50))
        }
        let bounds = AlphaGeometry.bounds(of: try #require(image.cgImage))
        #expect(bounds == CGRect(x: 20, y: 30, width: 40, height: 50))
        let projected = ImagePlacement.aspectFill(source: CGSize(width: 400, height: 200),
                                                   viewport: CGSize(width: 200, height: 400),
                                                   normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))
        #expect(projected == CGRect(x: -100, y: 100, width: 400, height: 200))
    }
}
