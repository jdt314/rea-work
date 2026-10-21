import Foundation
import Security

/// 当前开发版使用用户自己的密钥；不将服务端共享密钥打包进 App。
enum AIRecognitionSettings {
    private static let service = "dev.reawork.CapWordsSwift.recognition"
    private static let account = "api-key"

    static func load() throws -> AIRecognitionConfiguration {
        let defaults = UserDefaults.standard
        return AIRecognitionConfiguration(baseURL: defaults.string(forKey: "recognitionBaseURL") ?? "https://api.deepseek.com",
                                          model: defaults.string(forKey: "recognitionModel") ?? "deepseek-flash",
                                          apiKey: try readKey())
    }

    static func save(_ configuration: AIRecognitionConfiguration) throws {
        _ = try configuration.endpoint()
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service, kSecAttrAccount as String: account]
        let attributes: [String: Any] = [kSecValueData as String: Data(configuration.apiKey.utf8),
                                        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            attributes.forEach { item[$0.key] = $0.value }
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw KeyError.storage }
        } else if status != errSecSuccess { throw KeyError.storage }
        UserDefaults.standard.set(configuration.baseURL, forKey: "recognitionBaseURL")
        UserDefaults.standard.set(configuration.model, forKey: "recognitionModel")
    }

    static func removeKey() throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service, kSecAttrAccount as String: account]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeyError.storage }
    }

    private static func readKey() throws -> String {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service, kSecAttrAccount as String: account,
                                    kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return "" }
        guard status == errSecSuccess, let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else { throw KeyError.storage }
        return key
    }

    private enum KeyError: LocalizedError {
        case storage
        var errorDescription: String? { "无法读写钥匙串，请解锁设备后重试。" }
    }
}
