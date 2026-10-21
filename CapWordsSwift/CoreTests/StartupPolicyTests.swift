import Foundation
import Testing
@testable import CapWordsCore

struct StartupPolicyTests {
    private func calendar(_ zone: String = "UTC") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    private func date(_ year: Int = 2026, _ month: Int = 10, _ day: Int = 18,
                      _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0,
                      in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day,
                                           hour: hour, minute: minute, second: second))!
    }

    @Test(arguments: [
        (0, "晚上好 (^▽^)"), (3, "晚上好 (^▽^)"),
        (4, "早上好 :)"), (11, "早上好 :)"),
        (12, "下午好 :-)"), (17, "下午好 :-)"),
        (18, "晚上好 (^▽^)"), (23, "晚上好 (^▽^)")
    ])
    func greetingHourBoundaries(hour: Int, expected: String) {
        let calendar = calendar()
        #expect(HomePresentation.greeting(at: date(2026, 10, 18, hour, in: calendar), calendar: calendar) == expected)
        #expect(HomePresentation.greeting(at: date(2026, 10, 18, hour, 59, 59, in: calendar), calendar: calendar) == expected)
    }

    @Test func greetingUsesInjectedTimeZone() {
        let utc = calendar()
        let instant = date(2026, 10, 18, 21, in: utc)
        #expect(HomePresentation.greeting(at: instant, calendar: utc) == "晚上好 (^▽^)")
        #expect(HomePresentation.greeting(at: instant, calendar: calendar("Asia/Shanghai")) == "早上好 :)")
        #expect(HomePresentation.greeting(at: instant, calendar: calendar("America/Los_Angeles")) == "下午好 :-)")
    }

    @Test func emptyLibraryStillHasToday() {
        let calendar = calendar("Asia/Shanghai")
        let now = date(2026, 10, 18, 23, 59, in: calendar)
        #expect(HomePresentation.dateDays(from: [], now: now, calendar: calendar) == [calendar.startOfDay(for: now)])
    }

    @Test func dateGroupsDeduplicateAndSortAcrossYearBoundary() {
        let calendar = calendar("Asia/Shanghai")
        let today = date(2026, 1, 1, 12, in: calendar)
        let yesterday = date(2025, 12, 31, 23, 59, in: calendar)
        let older = date(2025, 12, 30, 14, in: calendar)
        let groups = HomePresentation.dateDays(
            from: [older, yesterday, date(2025, 12, 31, 0, in: calendar), today],
            now: today, calendar: calendar
        )
        #expect(groups == [today, yesterday, older].map { calendar.startOfDay(for: $0) })
    }

    @Test func dateGroupsUseLocalDayNotUTCDate() {
        let utc = calendar()
        let beforeLocalMidnight = date(2025, 12, 31, 15, 59, in: utc)
        let afterLocalMidnight = date(2025, 12, 31, 16, 1, in: utc)
        let shanghai = calendar("Asia/Shanghai")
        #expect(HomePresentation.dateDays(from: [beforeLocalMidnight], now: afterLocalMidnight, calendar: shanghai) == [
            date(2026, 1, 1, 0, in: shanghai), date(2025, 12, 31, 0, in: shanghai)
        ])
        #expect(HomePresentation.dateDays(from: [beforeLocalMidnight], now: afterLocalMidnight, calendar: utc).count == 1)
    }

    @Test func dateGroupsRespectDaylightSavingAndKeepSourceDates() {
        let calendar = calendar("America/Los_Angeles")
        let today = date(2026, 3, 8, 23, in: calendar)
        let tomorrow = date(2026, 3, 9, 12, in: calendar)
        let yesterday = date(2026, 3, 7, 23, in: calendar)
        let days = HomePresentation.dateDays(from: [tomorrow, yesterday, today], now: today, calendar: calendar)
        #expect(days == [tomorrow, today, yesterday].map { calendar.startOfDay(for: $0) })
        #expect(days[0].timeIntervalSince(days[1]) == 23 * 60 * 60)
    }

    @Test func headerKeepsEmptyFirstDayMessageDespiteHistoricalWords() {
        let prompt = "用一个新单词，开启美好的一天"
        #expect(HomePresentation.headerMessage(wordCount: 12, hasWordsInFirstDay: false) == prompt)
        #expect(HomePresentation.headerMessage(wordCount: 0, hasWordsInFirstDay: true) == prompt)
        #expect(HomePresentation.headerMessage(wordCount: -1, hasWordsInFirstDay: true) == prompt)
        #expect(HomePresentation.headerMessage(wordCount: 12, hasWordsInFirstDay: true) == "真棒！已经收集了12个单词")
        #expect(HomePresentation.emptyCardMessage == "还没有拍摄任何单词呢～\n快看看身边有什么好玩的东西？")
    }

    @Test func newUserTakesOnboardingBeforeOtherRoutes() {
        let calendar = calendar()
        let now = date(in: calendar)
        #expect(StartupPolicy.route(hasShownOnboarding: false, wordCount: 0, dueWordCount: 0,
                                    lastReviewDate: nil, reviewReminderDisabled: false,
                                    now: now, calendar: calendar) == .onboarding)
        #expect(StartupPolicy.route(hasShownOnboarding: false, wordCount: 10, dueWordCount: 10,
                                    lastReviewDate: nil, reviewReminderDisabled: false,
                                    now: now, calendar: calendar) == .onboarding)
    }

    @Test(arguments: [(0, 0, false), (0, 2, false), (3, 0, false), (3, 2, true), (-1, 2, false), (3, -1, false)])
    func libraryWhenReviewIsUnavailable(words: Int, due: Int, disabled: Bool) {
        let calendar = calendar()
        #expect(StartupPolicy.route(hasShownOnboarding: true, wordCount: words, dueWordCount: due,
                                    lastReviewDate: nil, reviewReminderDisabled: disabled,
                                    now: date(in: calendar), calendar: calendar) == .library)
    }

    @Test func dailyReviewWhenNotPreviewedToday() {
        let calendar = calendar()
        let now = date(2026, 1, 1, 0, 1, in: calendar)
        let yesterday = date(2025, 12, 31, 23, 59, in: calendar)
        for lastReviewDate in [nil, yesterday] as [Date?] {
            #expect(StartupPolicy.route(hasShownOnboarding: true, wordCount: 10, dueWordCount: 3,
                                        lastReviewDate: lastReviewDate, reviewReminderDisabled: false,
                                        now: now, calendar: calendar) == .dailyReview)
        }
    }

    @Test func sameDayReviewIsSuppressedEvenAtDifferentHours() {
        let calendar = calendar("Asia/Shanghai")
        let morning = date(2026, 10, 18, 0, 1, in: calendar)
        let evening = date(2026, 10, 18, 23, 59, in: calendar)
        #expect(StartupPolicy.route(hasShownOnboarding: true, wordCount: 10, dueWordCount: 3,
                                    lastReviewDate: morning, reviewReminderDisabled: false,
                                    now: evening, calendar: calendar) == .library)
    }

    @Test func reviewComparisonUsesLocalCalendarBoundary() {
        let utc = calendar()
        let previous = date(2025, 12, 31, 15, 59, in: utc)
        let now = date(2025, 12, 31, 16, 1, in: utc)
        #expect(StartupPolicy.route(hasShownOnboarding: true, wordCount: 4, dueWordCount: 2,
                                    lastReviewDate: previous, reviewReminderDisabled: false,
                                    now: now, calendar: utc) == .library)
        #expect(StartupPolicy.route(hasShownOnboarding: true, wordCount: 4, dueWordCount: 2,
                                    lastReviewDate: previous, reviewReminderDisabled: false,
                                    now: now, calendar: calendar("Asia/Shanghai")) == .dailyReview)
    }

    @Test func explicitOnboardingValueAlwaysOverridesLegacyState() {
        #expect(StartupPolicy.hasCompletedOnboarding(stored: false, legacyHasLaunched: true, existingWordCount: 8) == false)
        #expect(StartupPolicy.hasCompletedOnboarding(stored: true, legacyHasLaunched: false, existingWordCount: 0) == true)
    }

    @Test func legacyMigrationOnlyAppliesWhenValueIsMissing() {
        #expect(StartupPolicy.hasCompletedOnboarding(stored: nil, legacyHasLaunched: false, existingWordCount: 0) == false)
        #expect(StartupPolicy.hasCompletedOnboarding(stored: nil, legacyHasLaunched: true, existingWordCount: 0) == true)
        #expect(StartupPolicy.hasCompletedOnboarding(stored: nil, legacyHasLaunched: false, existingWordCount: 8) == true)
        #expect(StartupPolicy.hasCompletedOnboarding(stored: nil, legacyHasLaunched: false, existingWordCount: -1) == false)
    }
}
