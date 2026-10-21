import Foundation
import UserNotifications
import HealthKit
import Observation

enum StudyReminderService {
    static let identifier = "wordrove.daily-study"

    static func schedule(minutes: Int, requestPermission: Bool) async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        var allowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        if settings.authorizationStatus == .notDetermined, requestPermission {
            allowed = try await center.requestAuthorization(options: [.alert, .sound])
        }
        guard allowed else { throw ReminderError.permission }
        let safeMinutes = min(max(minutes, 0), 1439)
        let content = UNMutableNotificationContent()
        content.title = String(localized: "和今天的新单词见个面")
        content.body = String(localized: "拍下身边的事物，或者复习几张单词卡片吧。")
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: safeMinutes / 60, minute: safeMinutes % 60), repeats: true)
        try Task.checkCancellation()
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func cancel() { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier]) }

    private enum ReminderError: LocalizedError {
        case permission
        var errorDescription: String? { String(localized: "通知权限未开启，请在系统设置中允许通知。") }
    }
}

@MainActor @Observable
final class SettingsHealthStore {
    struct Source: Identifiable {
        let id: String
        let title: String
        let type: HKSampleType
    }
    static let sources: [Source] = [
        .init(id: "steps", title: "步数", type: HKQuantityType(.stepCount)),
        .init(id: "exercise", title: "运动", type: HKQuantityType(.appleExerciseTime)),
        .init(id: "sleep", title: "睡眠", type: HKCategoryType(.sleepAnalysis)),
        .init(id: "energy", title: "活动能量", type: HKQuantityType(.activeEnergyBurned)),
        .init(id: "hrv", title: "心率变异性", type: HKQuantityType(.heartRateVariabilitySDNN))
    ]
    private let store = HKHealthStore()
    private(set) var readableSources: Set<String> = []
    private(set) var requested = false
    private(set) var busy = false
    var error: String?
    var available: Bool { HKHealthStore.isHealthDataAvailable() }

    func connect() async {
        guard available, !busy else { return }
        busy = true
        defer { busy = false }
        do {
            try await store.requestAuthorization(toShare: [], read: Set(Self.sources.map { $0.type as HKObjectType }))
            requested = true
            // HealthKit deliberately hides read-denial status. A checkmark means an actual sample was read.
            for source in Self.sources {
                let hasData = try await hasReadableSample(source.type)
                if hasData { readableSources.insert(source.id) } else { readableSources.remove(source.id) }
            }
        } catch { self.error = error.localizedDescription }
    }

    private func hasReadableSample(_ type: HKSampleType) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: nil) { _, samples, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: !(samples?.isEmpty ?? true)) }
            }
            store.execute(query)
        }
    }
}
