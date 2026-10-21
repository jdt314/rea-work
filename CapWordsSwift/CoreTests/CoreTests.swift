import Foundation
import CoreGraphics
import SwiftData
import Testing
@testable import CapWordsCore

struct CoreTests {
    @Test func reviewScheduleAndReset() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let first = ReviewSchedule.next(stage: 0, remembered: true, now: now)
        #expect(first.stage == 1)
        #expect(Calendar.current.dateComponents([.day], from: now, to: first.date).day == 1)
        let failed = ReviewSchedule.next(stage: 4, remembered: false, now: now)
        #expect(failed.stage == 1)
        #expect(Calendar.current.dateComponents([.day], from: now, to: failed.date).day == 1)
        #expect(ReviewSchedule.next(stage: 100, remembered: true).stage == 4)
        #expect(ReviewSchedule.next(stage: -1, remembered: true).stage == 1)
        #expect(ReviewSchedule.next(stage: .max, remembered: true).stage == 4)
        #expect(ReviewSchedule.next(stage: 3, remembered: true).date == .distantFuture)
        #expect(Calendar.current.dateComponents([.day], from: now, to: ReviewSchedule.next(stage: 1, remembered: true, now: now).date).day == 2)
        #expect(Calendar.current.dateComponents([.day], from: now, to: ReviewSchedule.next(stage: 2, remembered: true, now: now).date).day == 4)
    }

    @Test @MainActor func queueIncludesAllDueWordsAndLimitsOnlyNewWords() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let due = (1...7).map { number in
            let word = Word(name: "due\(number)", meaning: "旧词")
            word.reviewCount = 1; word.reviewStage = 1
            word.nextReviewAt = now.addingTimeInterval(-Double(number))
            return word
        }
        let fresh = (1...8).map { Word(name: "new\($0)", meaning: "新词", createdAt: now.addingTimeInterval(Double($0))) }
        let mastered = Word(name: "mastered", meaning: "已掌握")
        mastered.reviewCount = 5; mastered.reviewStage = 1; mastered.isMastered = true
        mastered.nextReviewAt = now.addingTimeInterval(-100)
        let future = Word(name: "future", meaning: "未到期")
        future.reviewCount = 1; future.nextReviewAt = now.addingTimeInterval(100)
        let queue = ReviewQueue.make(words: Array(fresh.reversed()) + due + [mastered, future], newLimit: 5, now: now)
        #expect(queue.count == 12)
        #expect(Array(queue.prefix(7)).map(\.id) == due.reversed().map(\.id))
        #expect(Array(queue.suffix(5)).map(\.id) == fresh.prefix(5).map(\.id))
        #expect(ReviewQueue.make(words: due + fresh, newLimit: 0, now: now).count == 7)
    }

    @Test func aliasesUnknownObjectsAndTranslations() {
        #expect(Vocabulary.match("doughnut")?.meaning == "甜甜圈")
        #expect(Vocabulary.match("coffee mug, mug")?.key == "cup")
        #expect(Vocabulary.match("unrecognized_object") == nil)
        for entry in Vocabulary.entries {
            for language in LearningLanguage.allCases {
                #expect(entry.name(in: language)?.isEmpty == false)
            }
        }
    }

    @Test @MainActor func persistenceSeedAndDelete() throws {
        let container = try ModelContainer(for: Word.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        try SeedLibrary.insert(into: context)
        try SeedLibrary.insert(into: context)
        let words = try context.fetch(FetchDescriptor<Word>())
        #expect(words.count == 9)
        let word = try #require(words.first)
        word.name = "Updated word"; word.imageData = Data([1, 2, 3])
        try context.save()
        let second = ModelContext(container)
        #expect(try second.fetch(FetchDescriptor<Word>()).contains { $0.name == "Updated word" && $0.imageData == Data([1, 2, 3]) })
        context.delete(word); try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Word>()) == 8)
    }

    @Test func transparentImageBoundsPreserveTopOrigin() throws {
        let w = 100, h = 200
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        for y in 30..<80 { for x in 20..<60 { pixels[(y*w+x)*4] = 255; pixels[(y*w+x)*4+3] = 255 } }
        let provider = try #require(CGDataProvider(data: Data(pixels) as CFData))
        let image = try #require(CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                        provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
        #expect(AlphaGeometry.bounds(of: image) == CGRect(x: 20, y: 30, width: 40, height: 50))
    }

    @Test func aspectFillProjectionAccountsForCropping() {
        let rect = ImagePlacement.aspectFill(source: CGSize(width: 400, height: 200), viewport: CGSize(width: 200, height: 400),
                                             normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))
        #expect(rect == CGRect(x: -100, y: 100, width: 400, height: 200))
        #expect(ImagePlacement.aspectFill(source: .zero, viewport: CGSize(width: 200, height: 400), normalizedRect: .zero) == .zero)
    }
}
