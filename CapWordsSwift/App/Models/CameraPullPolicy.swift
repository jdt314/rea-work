import Foundation

enum CameraPullPolicy {
    static func canBegin(startOffset: Double, dateMode: Bool, startsOnToday: Bool) -> Bool {
        dateMode && startsOnToday && startOffset <= 1
    }

    static func progress(horizontal: Double, vertical: Double, height: Double) -> Double {
        guard height > 0, vertical > 0, vertical > abs(horizontal) * 1.25 else { return 0 }
        return min(0.9, vertical / height)
    }

    static func commits(distance: Double, predictedDistance: Double, height: Double) -> Bool {
        guard height > 0 else { return false }
        let threshold = min(110, height * 0.14)
        return distance >= threshold || (distance >= 32 && predictedDistance >= threshold * 1.7)
    }
}
