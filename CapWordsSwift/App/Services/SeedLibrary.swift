import SwiftData
import Foundation

@MainActor
enum SeedLibrary {
    static func insert(into context: ModelContext, daysAgoOffset: Int = 0) throws {
        let existing = Set(try context.fetch(FetchDescriptor<Word>()).compactMap(\.assetName))
        let samples: [(String, String, Int)] = [
            ("monstera", "sample-monstera", 0), ("tape", "sample-tape", 0),
            ("clip", "sample-clip", 0), ("switch", "sample-switch", 0),
            ("toast", "sample-toast", 1), ("bread", "sample-bread", 1),
            ("donut", "sample-donut", 2), ("forest", "sample-forest", 4), ("tea", "sample-tea", 4)
        ]
        for (key, asset, daysAgo) in samples where !existing.contains(asset) {
            guard let entry = Vocabulary.entries.first(where: { $0.key == key }) else { continue }
            let date = Calendar.current.date(byAdding: .day, value: -(daysAgo + daysAgoOffset), to: .now)!
            context.insert(Word(name: entry.english, meaning: entry.meaning, pronunciation: entry.pronunciation,
                                example: entry.example, exampleMeaning: entry.exampleMeaning,
                                category: entry.category, createdAt: date, assetName: asset))
        }
        do { try context.save() } catch { context.rollback(); throw error }
    }
}
