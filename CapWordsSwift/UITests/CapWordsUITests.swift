import XCTest

final class CapWordsUITests: XCTestCase {
    @MainActor
    func testCameraPullBlocksWordDetailsAndRestoresTap() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-library", "--single-today", "--preview-library", "--preview-camera-motion", "--hold-camera-pull"]
        app.launch()
        let word = app.buttons["word-Monstera"]
        XCTAssertTrue(word.waitForExistence(timeout: 10))
        let originalFrame = word.frame
        screenshot("camera-pull-before", app: app)

        // The DEBUG sampler supplies the pull state. The tap itself is a real
        // XCTest touch at the visible sticker's translated center, not an action call.
        let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: word)
        XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 8), .completed)
        Thread.sleep(forTimeInterval: 0.15)
        let translatedCenter = CGPoint(x: originalFrame.midX, y: originalFrame.midY + app.frame.height * 0.38)
        screenshot("camera-pull-before-sticker-tap", app: app)
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: translatedCenter.x, dy: translatedCenter.y)).tap()
        screenshot("camera-pull-after-sticker-tap", app: app)
        XCTAssertFalse(app.buttons["编辑单词"].waitForExistence(timeout: 1), "A sticker tap while revealing the camera must not open word details")

        // Relaunch without sampling to check that an ordinary sticker tap works.
        app.terminate()
        app.launchArguments.removeAll { $0 == "--preview-camera-motion" }
        app.launch()
        XCTAssertTrue(word.waitForExistence(timeout: 10))
        word.tap()
        XCTAssertTrue(app.buttons["编辑单词"].waitForExistence(timeout: 5))
        screenshot("camera-pull-normal-sticker-detail", app: app)
    }

    @MainActor
    func testCaptureEditSaveReviewAndDelete() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-library", "--preview-library"]
        app.launch()
        XCTAssertTrue(app.buttons["word-Monstera"].waitForExistence(timeout: 10))
        screenshot("01-library", app: app)

        app.buttons["captureButton"].tap()
        XCTAssertTrue(app.buttons["从相册选图"].waitForExistence(timeout: 5))
        screenshot("02-camera", app: app)
        app.buttons["captureButton"].tap()
        XCTAssertTrue(app.buttons["confirmSubjectButton"].waitForExistence(timeout: 10))
        screenshot("02b-cutout", app: app)
        app.buttons["confirmSubjectButton"].tap()
        XCTAssertTrue(app.buttons["saveWordButton"].waitForExistence(timeout: 10))
        screenshot("03-result", app: app)
        app.buttons["editResultButton"].tap()
        let name = app.textFields["wordNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        // 使用全选快捷键清空原词，适用于模拟器软键盘。
        let existing = name.value as? String ?? ""
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + "Pink donut")
        app.buttons["confirmEditButton"].tap()
        app.buttons["saveWordButton"].tap()
        XCTAssertTrue(app.buttons["word-Pink donut"].waitForExistence(timeout: 5))
        app.buttons["word-Pink donut"].tap()
        XCTAssertTrue(app.buttons["编辑单词"].waitForExistence(timeout: 5))
        screenshot("04-detail", app: app)
        app.buttons["完成"].tap()

        app.buttons["词库菜单"].tap()
        app.buttons["复习单词"].tap()
        XCTAssertTrue(app.buttons["startReviewSessionButton"].waitForExistence(timeout: 5))
        app.buttons["startReviewSessionButton"].tap()
        XCTAssertTrue(app.buttons["flashcard"].waitForExistence(timeout: 5))
        app.buttons["flashcard"].tap()
        screenshot("05-review", app: app)
        XCTAssertTrue(app.buttons["flashcard"].waitForExistence(timeout: 5))
        app.buttons["flashcard"].swipeRight()
        app.buttons["closeReviewSessionButton"].tap()
        XCTAssertTrue(app.buttons["startReviewSessionButton"].waitForExistence(timeout: 5))
        app.swipeDown()

        XCTAssertTrue(app.buttons["word-Pink donut"].waitForExistence(timeout: 5))
        app.buttons["word-Pink donut"].tap()
        app.buttons["删除单词"].tap()
        app.alerts.buttons["删除单词"].tap()
        XCTAssertTrue(app.buttons["captureButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["word-Pink donut"].exists)
    }

    @MainActor
    func testSearchCategoryAndEmptyLibrary() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--preview-library"]
        app.launch()
        XCTAssertTrue(app.staticTexts["emptyTodayMessage"].waitForExistence(timeout: 10))
        screenshot("00-empty", app: app)
        app.buttons["词库菜单"].tap()
        app.buttons["loadSamplesButton"].tap()
        XCTAssertTrue(app.buttons["word-Monstera"].waitForExistence(timeout: 5))
        app.buttons["词库菜单"].tap()
        app.buttons["搜索单词"].tap()
        let search = app.textFields["wordSearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap(); search.typeText("Tape")
        XCTAssertTrue(app.buttons["word-Tape"].exists)
        XCTAssertFalse(app.buttons["word-Monstera"].exists)
    }

    @MainActor
    func testAppearanceChangesImmediatelyAndSurvivesRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--preview-settings", "--preview-settings-general", "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        let menu = app.buttons["appearanceMenu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        XCTAssertTrue((menu.value as? String)?.contains("跟随系统") == true)
        menu.tap()
        app.buttons["appearance-dark"].tap()
        let isDark = NSPredicate(format: "value CONTAINS %@", "当前为深色")
        expectation(for: isDark, evaluatedWith: menu)
        waitForExpectations(timeout: 5)
        app.terminate()
        app.launchArguments.append("--preserve-test-preferences")
        app.launch()
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        expectation(for: isDark, evaluatedWith: menu)
        waitForExpectations(timeout: 5)
        menu.tap()
        app.buttons["appearance-light"].tap()
        expectation(for: NSPredicate(format: "value CONTAINS %@", "当前为浅色"), evaluatedWith: menu)
        waitForExpectations(timeout: 5)
        menu.tap()
        app.buttons["appearance-system"].tap()
        XCTAssertTrue((menu.value as? String)?.contains("跟随系统") == true)
    }

    @MainActor
    func testDateCardZoomReturnsToSameScrolledCard() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-library", "--preview-home"]
        app.launch()
        let scroll = app.scrollViews["homeCollectionScroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        let date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let title = "\(Calendar.current.component(.month, from: date))月\(Calendar.current.component(.day, from: date))"
        let card = app.buttons["snapshot-\(title)"]
        for _ in 0..<4 {
            if card.exists && card.frame.midY < app.frame.height * 0.7 { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(card.isHittable)
        XCTAssertEqual(card.frame.height, 194, accuracy: 1)
        XCTAssertEqual(card.frame.minX, 20, accuracy: 1)
        XCTAssertEqual(card.frame.width, app.frame.width - 40, accuracy: 1)
        XCTAssertFalse(card.label.contains("日"))
        let originalY = card.frame.minY
        screenshot("home-date-cards", app: app)
        for iteration in 0..<2 {
            card.tap()
            let back = app.buttons["返回主页"]
            XCTAssertTrue(back.waitForExistence(timeout: 5))
            let pinned = app.otherElements["libraryPinnedDate"]
            XCTAssertTrue(pinned.waitForExistence(timeout: 5))
            XCTAssertTrue(pinned.label.contains(title + "日"))
            XCTAssertFalse(app.tabBars.firstMatch.exists)
            screenshot("home-date-expanded-\(iteration)", app: app)
            back.tap()
            XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
            XCTAssertTrue(card.isHittable)
            XCTAssertEqual(card.frame.minY, originalY, accuracy: 2)
            screenshot("home-date-returned-\(iteration)", app: app)
        }
    }

    @MainActor
    func testNativeTabBarAndLibraryNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-library", "--preview-home"]
        app.launch()
        let bar = app.tabBars.firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 10))
        XCTAssertEqual(bar.buttons.count, 4)
        XCTAssertTrue(bar.buttons["拍摄"].isSelected)
        screenshot("06-native-tabbar", app: app)
        bar.buttons["对话"].tap()
        XCTAssertTrue(bar.buttons["对话"].isSelected)
        bar.buttons["复习"].tap()
        XCTAssertTrue(app.buttons["startReviewSessionButton"].waitForExistence(timeout: 5))
        app.buttons["startReviewSessionButton"].tap()
        XCTAssertTrue(app.buttons["flashcard"].waitForExistence(timeout: 5))
        app.buttons["flashcard"].tap()
        app.buttons["flashcard"].swipeRight()
        XCTAssertEqual(app.staticTexts["reviewProgress"].label, "1 / 5")
        app.buttons["flashcard"].tap()
        app.buttons["flashcard"].swipeRight()
        XCTAssertEqual(app.staticTexts["reviewProgress"].label, "2 / 5")
        app.buttons["closeReviewSessionButton"].tap()
        bar.buttons["个人"].tap()
        XCTAssertTrue(app.staticTexts["学习语言"].waitForExistence(timeout: 5))
        bar.buttons["拍摄"].tap()
        app.buttons["libraryDisplayMenu"].tap()
        app.buttons["按分类展示"].tap()
        screenshot("07-category-home", app: app)
        app.buttons["libraryDisplayMenu"].tap()
        app.buttons["全部单词"].tap()
        XCTAssertTrue(app.buttons["返回主页"].waitForExistence(timeout: 5))
        XCTAssertFalse(bar.exists)
        XCTAssertTrue(app.buttons["captureButton"].exists)
        app.buttons["返回主页"].tap()
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
    }

    @MainActor
    func testFreshStartupIntroEmptyLibraryAndHome() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--exercise-startup", "--force-onboarding"]
        app.launch()
        let start = app.buttons["completeOnboardingButton"]
        XCTAssertTrue(start.waitForExistence(timeout: 12))
        screenshot("08-startup-onboarding", app: app)
        start.tap()
        XCTAssertTrue(app.buttons["返回主页"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["word-Monstera"].exists)
        app.buttons["返回主页"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["homeWordSummary"].label, "用一个新单词，开启美好的一天")
        XCTAssertFalse(app.buttons["loadSamplesButton"].exists)
        screenshot("09-empty-home-today", app: app)
        app.buttons["libraryDisplayMenu"].tap()
        app.buttons["按分类展示"].tap()
        XCTAssertTrue(app.buttons["snapshot-食物饮品"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["snapshot-人物家庭"].exists)
    }

    @MainActor
    func testReturningUserOpensLibraryOnlyOnce() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--exercise-startup", "--seed-library", "--onboarding-complete", "--disable-daily-review"]
        app.launch()
        XCTAssertTrue(app.buttons["word-Monstera"].waitForExistence(timeout: 12))
        XCTAssertFalse(app.buttons["completeOnboardingButton"].exists)
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        screenshot("10-startup-library", app: app)
        app.buttons["返回主页"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["返回主页"].exists)
        XCTAssertEqual(app.staticTexts["homeWordSummary"].label, "真棒！已经收集了9个单词")
    }

    @MainActor
    func testDailyReviewWaitsForLaunchAndDismissesToHome() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--exercise-startup", "--seed-library", "--onboarding-complete"]
        app.launch()
        XCTAssertTrue(app.buttons["startDailyReviewButton"].waitForExistence(timeout: 12))
        XCTAssertEqual(app.staticTexts["reviewDueCount"].label, "今天有 5 个单词需要复习")
        XCTAssertFalse(app.buttons["flashcard"].exists)
        XCTAssertFalse(app.otherElements["launchOverlay"].exists)
        screenshot("11-startup-daily-review", app: app)
        app.buttons["closeReviewPromptButton"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["flashcard"].exists)
    }

    @MainActor
    func testDailyReviewStartsFixedQueue() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-library", "--onboarding-complete"]
        app.launch()
        XCTAssertTrue(app.buttons["startDailyReviewButton"].waitForExistence(timeout: 12))
        app.buttons["startDailyReviewButton"].tap()
        XCTAssertTrue(app.buttons["flashcard"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reviewProgress"].label, "0 / 5")
        screenshot("review-session-start", app: app)
        app.buttons["flashcard"].tap()
        XCTAssertTrue(app.staticTexts["flashcardBackMeaning"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reviewProgress"].label, "0 / 5")
        screenshot("review-session-back", app: app)
        app.buttons["flashcard"].tap()
        XCTAssertFalse(app.staticTexts["flashcardBackMeaning"].exists)
        app.buttons["flashcard"].swipeRight()
        XCTAssertEqual(app.staticTexts["reviewProgress"].label, "1 / 5")
        app.buttons["closeReviewSessionButton"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testDailyReviewCameraOpensAfterDismissal() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-library", "--onboarding-complete"]
        app.launch()
        XCTAssertTrue(app.buttons["reviewCaptureButton"].waitForExistence(timeout: 12))
        app.buttons["reviewCaptureButton"].tap()
        XCTAssertTrue(app.buttons["从相册选图"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["startDailyReviewButton"].exists)
    }

    @MainActor
    func testReviewRoundWritesDailyStatisticsAndChangesNewWordLimit() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-library", "--preview-home-review"]
        app.launch()
        XCTAssertTrue(app.buttons["startReviewSessionButton"].waitForExistence(timeout: 10))
        app.buttons["startReviewSessionButton"].tap()
        XCTAssertTrue(app.buttons["flashcard"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reviewProgress"].label, "0 / 5")
        for step in 0..<5 {
            if step < 3 { app.buttons["flashcard"].swipeRight() }
            else { app.buttons["flashcard"].swipeLeft() }
        }
        XCTAssertTrue(app.buttons["finishReviewButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reviewStatistic-认识"].label, "3")
        XCTAssertEqual(app.staticTexts["reviewStatistic-未掌握"].label, "2")
        screenshot("review-completion", app: app)
        app.buttons["finishReviewButton"].tap()
        XCTAssertTrue(app.staticTexts["今天已完成复习"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertEqual(app.staticTexts["reviewStatistic-已复习"].label, "5")
        screenshot("review-home-recorded", app: app)
        app.buttons["reviewDailyLimitButton"].tap()
        XCTAssertTrue(app.buttons["40"].waitForExistence(timeout: 5))
        app.buttons["10"].tap()
        app.buttons["保存"].tap()
        XCTAssertFalse(app.buttons["40"].exists)
        app.buttons["reviewDailyLimitButton"].tap()
        screenshot("review-daily-limit", app: app)
        app.buttons["取消"].tap()
    }

    @MainActor
    func testTodaysReviewIsNotPresentedAgain() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed-library", "--onboarding-complete", "--reviewed-today"]
        app.launch()
        XCTAssertTrue(app.buttons["返回主页"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["word-Monstera"].exists)
        XCTAssertFalse(app.buttons["flashcard"].exists)
    }

    @MainActor
    private func screenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "\(name)-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }
}
