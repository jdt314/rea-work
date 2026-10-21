import XCTest

final class LibraryTimelineUITests: XCTestCase {
    @MainActor
    func testDownwardPullOnEmptyTodayOpensCameraAndReturnsToSameDay() {
        let app = launch(["--seed-library-history"])
        let message = app.staticTexts["emptyTodayMessage"]
        XCTAssertTrue(message.waitForExistence(timeout: 10))
        drag(app, from: 0.42, to: 0.60)
        XCTAssertTrue(app.buttons["从相册选图"].waitForExistence(timeout: 5))
        app.buttons["取消拍摄"].tap()
        XCTAssertTrue(waitForLabel(app.otherElements["libraryPinnedDate"], containing: "0个单词"))
        XCTAssertTrue(waitForHittable(message))
        XCTAssertFalse(app.buttons["word-Monstera"].isHittable)
    }

    @MainActor
    func testDownwardPullOnPopulatedTodayOpensCameraAndReturnsToSameDay() {
        let app = launch(["--seed-library", "--single-today"])
        XCTAssertTrue(app.buttons["word-Monstera"].waitForExistence(timeout: 10))
        drag(app, from: 0.42, to: 0.66)
        XCTAssertTrue(app.buttons["从相册选图"].waitForExistence(timeout: 5))
        app.buttons["取消拍摄"].tap()
        XCTAssertTrue(waitForLabel(app.otherElements["libraryPinnedDate"], containing: "1个单词"))
        XCTAssertTrue(waitForHittable(app.buttons["word-Monstera"]))
    }

    @MainActor
    func testShortDownwardPullReturnsWithoutOpeningCamera() {
        let app = launch(["--seed-library-history"])
        let message = app.staticTexts["emptyTodayMessage"]
        XCTAssertTrue(message.waitForExistence(timeout: 10))
        let position = message.frame.minY
        drag(app, from: 0.42, to: 0.46)
        XCTAssertTrue(waitForHittable(message))
        XCTAssertEqual(message.frame.minY, position, accuracy: 2)
        XCTAssertFalse(app.buttons["从相册选图"].isHittable)
    }

    @MainActor
    func testEmptyTodayFillsPageAndSnapsToHistoryAndBack() {
        let app = launch(["--seed-library-history"])
        let message = app.staticTexts["emptyTodayMessage"]
        XCTAssertTrue(message.waitForExistence(timeout: 10))
        let pinned = app.otherElements["libraryPinnedDate"]
        XCTAssertTrue(pinned.waitForExistence(timeout: 5))
        let originalLabel = pinned.label
        let originalY = pinned.frame.minY
        XCTAssertTrue(originalLabel.contains("0个单词"))
        XCTAssertFalse(app.buttons["word-Monstera"].isHittable)
        attach("empty-today", app)

        drag(app, from: 0.72, to: 0.35)
        XCTAssertTrue(app.buttons["word-Monstera"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(pinned, containing: "4个单词"))
        XCTAssertEqual(pinned.frame.minY, originalY, accuracy: 1)
        XCTAssertFalse(message.isHittable)
        attach("first-history", app)

        drag(app, from: 0.35, to: 0.78)
        XCTAssertTrue(waitForLabel(pinned, containing: "0个单词"))
        XCTAssertEqual(pinned.label, originalLabel)
        XCTAssertTrue(message.isHittable)
        attach("returned-to-today", app)
    }

    @MainActor
    func testPopulatedTodayScrollsContinuouslyAndKeepsDateFixed() {
        let app = launch(["--seed-library", "--single-today"])
        XCTAssertTrue(app.buttons["word-Monstera"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["emptyTodayMessage"].exists)
        let pinned = app.otherElements["libraryPinnedDate"]
        let initialY = pinned.frame.minY
        let before = app.buttons["word-Monstera"].frame.minY
        attach("populated-today", app)
        drag(app, from: 0.60, to: 0.51)
        let after = app.buttons["word-Monstera"].frame.minY
        XCTAssertLessThan(after, before - 15)
        XCTAssertGreaterThan(after, before - 250)
        XCTAssertEqual(pinned.frame.minY, initialY, accuracy: 1)
        drag(app, from: 0.75, to: 0.32)
        XCTAssertTrue(waitForLabel(pinned, containing: "5个单词"))
        XCTAssertEqual(pinned.frame.minY, initialY, accuracy: 1)
        attach("pinned-history-date", app)
    }

    @MainActor
    func testCompletelyEmptyLibraryHasNoPhantomSecondPage() {
        let app = launch([])
        let message = app.staticTexts["emptyTodayMessage"]
        XCTAssertTrue(message.waitForExistence(timeout: 10))
        let position = message.frame.minY
        drag(app, from: 0.75, to: 0.3)
        XCTAssertEqual(message.frame.minY, position, accuracy: 2)
        XCTAssertTrue(app.buttons["captureButton"].isHittable)
    }

    @MainActor
    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--preview-library"] + arguments
        app.launch()
        return app
    }

    @MainActor
    private func drag(_ app: XCUIApplication, from: CGFloat, to: CGFloat) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: from))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: to)),
                   withVelocity: .slow, thenHoldForDuration: 0.1)
    }

    @MainActor
    private func waitForLabel(_ element: XCUIElement, containing value: String) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", value), object: element)
        return XCTWaiter.wait(for: [expectation], timeout: 5) == .completed
    }

    @MainActor
    private func waitForHittable(_ element: XCUIElement) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: element)
        return XCTWaiter.wait(for: [expectation], timeout: 5) == .completed
    }

    @MainActor
    private func attach(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
