import Foundation
import Testing
@testable import CapWordsCore

struct LibraryScrollPolicyTests {
    @Test func emptyCoverCommitsOneVerticalPullButIgnoresSmallOrSidewaysDrags() {
        #expect(!LibraryScrollPolicy.advancesEmptyPage(horizontal: 0, vertical: 45))
        #expect(LibraryScrollPolicy.advancesEmptyPage(horizontal: 4, vertical: -45))
        #expect(!LibraryScrollPolicy.advancesEmptyPage(horizontal: 0, vertical: 20))
        #expect(!LibraryScrollPolicy.advancesEmptyPage(horizontal: 100, vertical: 45))
    }

    @Test func returningFromHistoryUsesOnlyDownwardPageGesture() {
        #expect(LibraryScrollPolicy.returnsToEmptyPage(horizontal: 2, vertical: 45))
        #expect(!LibraryScrollPolicy.returnsToEmptyPage(horizontal: 0, vertical: -45))
        #expect(!LibraryScrollPolicy.returnsToEmptyPage(horizontal: 0, vertical: 20))
        #expect(!LibraryScrollPolicy.returnsToEmptyPage(horizontal: 100, vertical: 45))
        #expect(!LibraryScrollPolicy.returnsToEmptyPage(horizontal: 0, vertical: 201, distanceToBoundary: 200))
        #expect(LibraryScrollPolicy.returnsToEmptyPage(horizontal: 0, vertical: 245, distanceToBoundary: 200))
    }

    @Test func emptyTodayAdvancesExactlyOnePageEvenWithFastFling() {
        #expect(LibraryScrollPolicy.targetOffset(start: 0, proposed: 1900, velocity: 3,
                    emptyPageHeight: 700, maximumOffset: 2400) == 700)
        #expect(LibraryScrollPolicy.targetOffset(start: 0, proposed: 90, velocity: 0,
                    emptyPageHeight: 700, maximumOffset: 2400) == 700)
    }

    @Test func smallDragAndTopBounceStayOnToday() {
        for proposed in [-90.0, 0, 30] {
            #expect(LibraryScrollPolicy.targetOffset(start: 0, proposed: proposed, velocity: 0,
                        emptyPageHeight: 700, maximumOffset: 2400) == 0)
        }
        #expect(LibraryScrollPolicy.targetOffset(start: 0, proposed: 25, velocity: 12,
                    emptyPageHeight: 700, maximumOffset: 2400) == 0)
        #expect(LibraryScrollPolicy.targetOffset(start: 0, proposed: 25, velocity: 200,
                    emptyPageHeight: 700, maximumOffset: 2400) == 700)
    }

    @Test func roundingAtShortFinalDayStillAllowsSnapping() {
        #expect(LibraryScrollPolicy.targetOffset(start: 0, proposed: 120, velocity: 200,
                    emptyPageHeight: 700, maximumOffset: 699.5) == 699.5)
    }

    @Test func historyScrollsFreelyUntilItEntersEmptyPage() {
        #expect(LibraryScrollPolicy.targetOffset(start: 700, proposed: 810, velocity: 0.2,
                    emptyPageHeight: 700, maximumOffset: 2400) == 810)
        #expect(LibraryScrollPolicy.targetOffset(start: 1400, proposed: 1023, velocity: -0.5,
                    emptyPageHeight: 700, maximumOffset: 2400) == 1023)
        #expect(LibraryScrollPolicy.targetOffset(start: 700, proposed: 670, velocity: 0,
                    emptyPageHeight: 700, maximumOffset: 2400) == 700)
        #expect(LibraryScrollPolicy.targetOffset(start: 700, proposed: 600, velocity: -0.4,
                    emptyPageHeight: 700, maximumOffset: 2400) == 0)
    }

    @Test func populatedTodayAndAbsentHistoryDoNotInventPages() {
        #expect(LibraryScrollPolicy.targetOffset(start: 0, proposed: 170, velocity: 1,
                    emptyPageHeight: nil, maximumOffset: 2400) == 170)
        #expect(LibraryScrollPolicy.targetOffset(start: 0, proposed: 0, velocity: 1,
                    emptyPageHeight: 700, maximumOffset: 0) == 0)
    }

    @Test func pinnedDateTracksCrossedHeadersInBothDirectionsAndFastScrolls() {
        let ids = ["today", "yesterday", "older"]
        #expect(LibraryScrollPolicy.activeGroupID(orderedIDs: ids,
                    headerOffsets: ["today": -30, "yesterday": 90, "older": 900]) == "today")
        #expect(LibraryScrollPolicy.activeGroupID(orderedIDs: ids,
                    headerOffsets: ["today": -30, "yesterday": 45, "older": 900]) == "yesterday")
        #expect(LibraryScrollPolicy.activeGroupID(orderedIDs: ids,
                    headerOffsets: ["today": -30, "yesterday": 45, "older": 900], emptyFirstPage: true) == "today")
        #expect(LibraryScrollPolicy.activeGroupID(orderedIDs: ids,
                    headerOffsets: ["today": -330, "yesterday": -255, "older": 0]) == "older")
        #expect(LibraryScrollPolicy.activeGroupID(orderedIDs: ids,
                    headerOffsets: ["today": -130, "yesterday": 0, "older": 250]) == "yesterday")
        #expect(LibraryScrollPolicy.activeGroupID(orderedIDs: ids,
                    headerOffsets: ["today": 40]) == "today")
        #expect(LibraryScrollPolicy.activeGroupID(orderedIDs: [], headerOffsets: [:]) == nil)
    }
}
