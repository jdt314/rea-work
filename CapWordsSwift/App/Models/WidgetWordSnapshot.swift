import Foundation

struct WidgetWordSnapshot: Codable, Equatable, Sendable {
    static let suite = "group.cn.a2px.wordrove.dev.f89luflt5b.c9e48b12"
    static let storageKey = "latestWordWidgetSnapshot"
    let name: String
    let meaning: String
    let wordCount: Int
    let imageData: Data?
}
