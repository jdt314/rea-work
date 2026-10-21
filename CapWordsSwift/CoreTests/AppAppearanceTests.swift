import Testing
@testable import CapWordsCore

struct AppAppearanceTests {
    @Test func missingAndUnknownPreferencesFollowSystem() {
        #expect(AppAppearance(storedValue: nil) == .system)
        #expect(AppAppearance(storedValue: "") == .system)
        #expect(AppAppearance(storedValue: "obsolete-value") == .system)
    }

    @Test(arguments: AppAppearance.allCases)
    func storedSelectionRoundTrips(mode: AppAppearance) {
        #expect(AppAppearance(storedValue: mode.rawValue) == mode)
    }
}
