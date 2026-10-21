import Foundation

/// Only the app's disposable cache directory is managed here; saved words live elsewhere.
struct SettingsCacheStore: Sendable {
    let directory: URL

    static var appCache: Self {
        Self(directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0])
    }

    func byteCount() throws -> Int64 {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]
        guard let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: Array(keys),
                                                        options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in files {
            let values = try url.resourceValues(forKeys: keys)
            if values.isRegularFile == true { total += Int64(values.fileSize ?? 0) }
        }
        return total
    }

    func clear() throws {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        let entries = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for entry in entries { try FileManager.default.removeItem(at: entry) }
    }
}
