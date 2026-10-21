import SwiftUI
import SwiftData

@main
struct CapWordsApp: App {
    private let container: ModelContainer
    private let preferences: UserDefaults
    @State private var cameraAppearance = false
    @AppStorage private var appearanceRawValue: String
    init() {
        #if DEBUG
        let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
        #else
        let testing = false
        #endif
        if testing {
            // 仅清理专用测试偏好；不污染真实引导/复习状态，也不清空用户词库。
            let suite = "dev.reawork.CapWordsSwift.UITesting"
            let isolated = UserDefaults(suiteName: suite)!
            if !ProcessInfo.processInfo.arguments.contains("--preserve-test-preferences") {
                isolated.removePersistentDomain(forName: suite)
            }
            preferences = isolated
        } else {
            preferences = .standard
        }
        #if DEBUG
        if testing, let value = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--appearance=") }) {
            preferences.set(AppAppearance(storedValue: String(value.dropFirst("--appearance=".count))).rawValue,
                            forKey: AppAppearance.storageKey)
        }
        #endif
        _appearanceRawValue = AppStorage(wrappedValue: AppAppearance.system.rawValue,
                                        AppAppearance.storageKey, store: preferences)
        do {
            container = try ModelContainer(for: Word.self, ReviewRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: testing))
        } catch {
            // 保留损坏数据库，不通过静默清空用户词库来恢复。
            fatalError("词库无法打开：\(error.localizedDescription)")
        }
    }
    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--preview-launch-screen") {
                    LaunchScreenPreview().ignoresSafeArea()
                } else {
                    HomeView(preferences: preferences)
                }
                #else
                HomeView(preferences: preferences)
                #endif
            }
                .tint(Palette.lilac)
                .onPreferenceChange(CameraAppearancePreferenceKey.self) { cameraAppearance = $0 }
                .preferredColorScheme(cameraAppearance ? .dark : AppAppearance(storedValue: appearanceRawValue).colorScheme)
                .defaultAppStorage(preferences)
        }
        .modelContainer(container)
    }
}
