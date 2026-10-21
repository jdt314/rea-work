import Foundation

enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    static let storageKey = "appearanceMode"
    var id: String { rawValue }

    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? .system
    }

    var title: String {
        switch self {
        case .system: "跟随系统"
        case .light: "浅色"
        case .dark: "深色"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
}
