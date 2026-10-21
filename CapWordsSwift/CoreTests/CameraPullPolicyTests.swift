import Testing
@testable import CapWordsCore

struct CameraPullPolicyTests {
    @Test func cameraOnlyStartsWithAGestureAtTodaysTop() {
        #expect(CameraPullPolicy.canBegin(startOffset: 0, dateMode: true, startsOnToday: true))
        #expect(CameraPullPolicy.canBegin(startOffset: -12, dateMode: true, startsOnToday: true))
        #expect(!CameraPullPolicy.canBegin(startOffset: 140, dateMode: true, startsOnToday: true))
        #expect(!CameraPullPolicy.canBegin(startOffset: 0, dateMode: false, startsOnToday: true))
        #expect(!CameraPullPolicy.canBegin(startOffset: 0, dateMode: true, startsOnToday: false))
    }

    @Test func pullFollowsVerticalDistanceWithoutOpeningForOtherDirections() {
        #expect(CameraPullPolicy.progress(horizontal: 0, vertical: 200, height: 800) == 0.25)
        #expect(CameraPullPolicy.progress(horizontal: 0, vertical: -200, height: 800) == 0)
        #expect(CameraPullPolicy.progress(horizontal: 200, vertical: 40, height: 800) == 0)
        #expect(CameraPullPolicy.progress(horizontal: 0, vertical: 900, height: 800) == 0.9)
        #expect(CameraPullPolicy.progress(horizontal: 0, vertical: 200, height: 0) == 0)
    }

    @Test func shortPullReturnsToLibraryWhileDeliberatePullOrFlingOpensCamera() {
        #expect(!CameraPullPolicy.commits(distance: 20, predictedDistance: 300, height: 800))
        #expect(!CameraPullPolicy.commits(distance: 60, predictedDistance: 70, height: 800))
        #expect(CameraPullPolicy.commits(distance: 120, predictedDistance: 120, height: 800))
        #expect(CameraPullPolicy.commits(distance: 50, predictedDistance: 250, height: 800))
        #expect(!CameraPullPolicy.commits(distance: -80, predictedDistance: -200, height: 800))
        #expect(!CameraPullPolicy.commits(distance: 100, predictedDistance: 200, height: 0))
    }
}
