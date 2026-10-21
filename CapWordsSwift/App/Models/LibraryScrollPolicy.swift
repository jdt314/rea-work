import Foundation

/// Only the empty today page snaps. Historical days keep the system's free scrolling.
enum LibraryScrollPolicy {
    static func advancesEmptyPage(horizontal: Double, vertical: Double) -> Bool {
        vertical <= -36 && abs(vertical) > abs(horizontal) * 1.25
    }

    static func returnsToEmptyPage(horizontal: Double, vertical: Double, distanceToBoundary: Double = 0) -> Bool {
        let pullAtBoundary = vertical - max(0, distanceToBoundary)
        return pullAtBoundary >= 36 && vertical > abs(horizontal) * 1.25
    }

    static func targetOffset(start: Double, proposed: Double, velocity: Double,
                             emptyPageHeight: Double?, maximumOffset: Double) -> Double {
        guard let height = emptyPageHeight, height > 0, maximumOffset > 0 else {
            return proposed
        }
        let boundary = min(height, maximumOffset)
        let threshold = min(64, boundary * 0.12)
        if start < boundary - 1 {
            if velocity > 180 || proposed - start > threshold { return boundary }
            if velocity < -180 || start - proposed > threshold { return 0 }
            return start < boundary / 2 ? 0 : boundary
        }
        if proposed < boundary {
            return proposed < boundary - threshold ? 0 : boundary
        }
        return proposed
    }

    static func activeGroupID(orderedIDs: [String], headerOffsets: [String: Double],
                              activationOffset: Double = 72, emptyFirstPage: Bool = false) -> String? {
        // Video 2 changes historical dates shortly before the next heading reaches the top.
        // The empty cover holds today's date until the first historical page settles.
        Array(orderedIDs.enumerated()).last { index, id in
            let threshold = emptyFirstPage && index == 1 ? 1 : activationOffset
            return (headerOffsets[id] ?? .infinity) <= threshold
        }?.element ?? orderedIDs.first
    }
}
