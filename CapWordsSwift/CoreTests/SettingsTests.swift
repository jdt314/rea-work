import XCTest
@testable import CapWordsCore

final class SettingsTests: XCTestCase {
    func testClearingCachePreservesWordsProfileAndSymlinkDestination() throws {
        let manager = FileManager.default
        let root = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? manager.removeItem(at: root) }
        let cache = root.appendingPathComponent("Caches")
        let documents = root.appendingPathComponent("Application Support")
        try manager.createDirectory(at: cache.appendingPathComponent("thumbnails"), withIntermediateDirectories: true)
        try manager.createDirectory(at: documents, withIntermediateDirectories: true)
        let words = documents.appendingPathComponent("words.store")
        let profile = documents.appendingPathComponent("avatar.jpg")
        let savedWordData = Data("saved words".utf8)
        let avatarData = Data([1, 2, 3])
        try savedWordData.write(to: words)
        try avatarData.write(to: profile)
        try Data(repeating: 1, count: 31).write(to: cache.appendingPathComponent("thumbnails/preview.png"))
        let store = SettingsCacheStore(directory: cache)
        XCTAssertEqual(try store.byteCount(), 31)
        try manager.createSymbolicLink(at: cache.appendingPathComponent("external"), withDestinationURL: documents)
        try store.clear()
        XCTAssertEqual(try manager.contentsOfDirectory(atPath: cache.path), [])
        XCTAssertEqual(try Data(contentsOf: words), savedWordData)
        XCTAssertEqual(try Data(contentsOf: profile), avatarData)
        XCTAssertEqual(try store.byteCount(), 0)
        try store.clear()
    }

    func testWidgetSnapshotCarriesLatestWordAndImageAcrossProcesses() throws {
        let snapshot = WidgetWordSnapshot(name: "cup", meaning: "杯子", wordCount: 12, imageData: Data([7, 8]))
        XCTAssertEqual(try JSONDecoder().decode(WidgetWordSnapshot.self, from: JSONEncoder().encode(snapshot)), snapshot)
        let empty = WidgetWordSnapshot(name: "", meaning: "", wordCount: 0, imageData: nil)
        XCTAssertEqual(try JSONDecoder().decode(WidgetWordSnapshot.self, from: JSONEncoder().encode(empty)), empty)
    }
}
