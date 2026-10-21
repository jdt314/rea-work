import Foundation

enum StartupRoute: Equatable, Sendable {
    case onboarding
    case library
    case dailyReview
}

enum StartupPolicy {
    static func route(
        hasShownOnboarding: Bool,
        wordCount: Int,
        dueWordCount: Int,
        lastReviewDate: Date?,
        reviewReminderDisabled: Bool,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> StartupRoute {
        // IPA Home 首轮布局先检查 hasShownOnboarding，再决定普通词库或每日复习。
        // 证据：home-defaults/findings.json HOME-07 / HOME-08；这里仅返回路由，不写偏好。
        guard hasShownOnboarding else { return .onboarding }
        guard wordCount > 0, dueWordCount > 0, !reviewReminderDisabled else { return .library }
        // 原版比较 Calendar.isDate(_:inSameDayAs:)，不是距上次经过 24 小时。
        if let lastReviewDate, calendar.isDate(lastReviewDate, inSameDayAs: now) {
            return .library
        }
        return .dailyReview
    }

    static func hasCompletedOnboarding(
        stored: Bool?,
        legacyHasLaunched: Bool,
        existingWordCount: Int
    ) -> Bool {
        // 本地重建版的兼容策略，并非声称 IPA 也使用 legacyHasLaunched：
        // 新标志一旦存在（包括 false）就遵从它，仅缺失时保留旧用户的使用进度。
        stored ?? (legacyHasLaunched || existingWordCount > 0)
    }
}

enum HomePresentation {
    // IPA zh-Hans.lproj/Localizable.strings 的第一条空卡文案（HOME-04）。
    static let emptyCardMessage = "还没有拍摄任何单词呢～\n快看看身边有什么好玩的东西？"

    static func greeting(at date: Date, calendar: Calendar = .current) -> String {
        // IPA 0x100060ba4 的本地小时分支；凌晨 00–03 仍使用晚上问候（HOME-06）。
        switch calendar.component(.hour, from: date) {
        case 4..<12: "早上好 :)"
        case 12..<18: "下午好 :-)"
        default: "晚上好 (^▽^)"
        }
    }

    static func dateDays(
        from dates: [Date],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Date] {
        // 按本地自然日分组；即使当天无词也保留今天的空卡（HOME-03），不制造词条。
        var days = Set(dates.map { calendar.startOfDay(for: $0) })
        days.insert(calendar.startOfDay(for: now))
        return days.sorted(by: >)
    }

    static func headerMessage(wordCount: Int, hasWordsInFirstDay: Bool) -> String {
        // IPA 0x100a36c94 先检查首日期项非空，再显示词库总数；不是无条件显示总数。
        // 两条中文均来自原包 zh-Hans 本地化，负计数按空数据防御处理（HOME-05）。
        guard wordCount > 0, hasWordsInFirstDay else { return "用一个新单词，开启美好的一天" }
        return "真棒！已经收集了\(wordCount)个单词"
    }
}
