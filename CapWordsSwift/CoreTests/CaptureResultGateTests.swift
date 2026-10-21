import XCTest
@testable import CapWordsCore

final class CaptureResultGateTests: XCTestCase {
    func test_fastRecognitionWaitsForUserAndSheet() {
        var gate = CaptureResultGate()
        gate.receiveWord()
        XCTAssertFalse(gate.takeReveal())
        gate.confirm()
        XCTAssertFalse(gate.takeReveal())
        gate.finishTransition()
        XCTAssertTrue(gate.takeReveal())
        XCTAssertFalse(gate.takeReveal())
    }

    func test_slowRecognitionRevealsWhenItArrives() {
        var gate = CaptureResultGate()
        gate.confirm()
        gate.finishTransition()
        XCTAssertFalse(gate.takeReveal())
        gate.receiveWord()
        XCTAssertTrue(gate.takeReveal())
        gate.receiveWord()
        XCTAssertFalse(gate.takeReveal())
    }

    func test_allArrivalOrdersRequireAllThreeSignals() {
        for order in [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]] {
            var gate = CaptureResultGate()
            for (index, signal) in order.enumerated() {
                switch signal {
                case 0: gate.receiveWord()
                case 1: gate.confirm()
                default: gate.finishTransition()
                }
                XCTAssertEqual(gate.takeReveal(), index == 2)
            }
        }
    }

    func test_retakeDiscardsPreviousReadiness() {
        var gate = CaptureResultGate()
        gate.receiveWord(); gate.confirm(); gate.finishTransition()
        gate = CaptureResultGate()
        gate.confirm(); gate.finishTransition()
        XCTAssertFalse(gate.takeReveal())
    }
}
