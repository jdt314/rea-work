import SwiftUI

struct LibraryScrollBehavior: ScrollTargetBehavior, Sendable {
    var emptyPageHeight: CGFloat?
    var onPageSnap: @MainActor @Sendable (Bool) -> Void = { _ in }

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        target.rect.origin.y = LibraryScrollPolicy.targetOffset(
            start: context.originalTarget.rect.minY, proposed: target.rect.minY,
            velocity: context.velocity.dy, emptyPageHeight: emptyPageHeight.map(Double.init),
            maximumOffset: max(0, context.contentSize.height - context.containerSize.height))
        if let height = emptyPageHeight {
            let startsOnEmptyPage = context.originalTarget.rect.minY < height / 2
            let endsOnEmptyPage = target.rect.minY < height / 2
            if startsOnEmptyPage != endsOnEmptyPage {
                // A target is committed at release, before the settling animation.
                // Delivery on MainActor also keeps haptic state out of layout evaluation.
                Task { @MainActor in onPageSnap(endsOnEmptyPage) }
            }
        }
    }
}

struct LibraryDateHeading: View {
    let date: Date
    let count: Int
    var animated = false
    var foreground: Color = .primary
    var countOpacity: Double = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let components = Calendar.current.dateComponents([.month, .day], from: date)
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(components.month ?? 1)")
                    .contentTransition(.numericText(countsDown: true))
                Text("月")
                Text("\(components.day ?? 1)")
                    .contentTransition(.numericText(countsDown: true))
            }
            .font(.system(size: 26, design: .serif))
            .foregroundStyle(foreground)
            Text("\(count)个单词")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(countsDown: true))
                .opacity(countOpacity)
        }
        .animation(animated && !reduceMotion ? .easeInOut(duration: 0.18) : nil, value: date)
        .animation(animated && !reduceMotion ? .easeInOut(duration: 0.18) : nil, value: count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(components.month ?? 1)月\(components.day ?? 1)日，\(count)个单词")
        .accessibilityIdentifier(animated ? "libraryPinnedDate" : "libraryDateHeading")
    }
}

struct EmptyDayEyes: View {
    var active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var startedAt = Date.now

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30,
                                paused: !active || reduceMotion || scenePhase != .active)) { timeline in
            let time = reduceMotion ? 0 : max(0, timeline.date.timeIntervalSince(startedAt))
            let blink = time.truncatingRemainder(dividingBy: 4.6)
            let openness = blink > 3.9 && blink < 4.14
                ? max(0.08, abs(blink - 4.02) / 0.12) : 1
            let gaze = sin(time * 0.85) * 4 - 2
            HStack(spacing: 9) {
                ForEach(0..<2) { _ in
                    Circle().fill(.white)
                        .overlay { Circle().stroke(.black.opacity(0.06), lineWidth: 1) }
                        .overlay {
                            Circle().fill(Palette.stickerInk).frame(width: 12, height: 12)
                                .offset(x: gaze, y: 3 + sin(time * 0.55))
                        }
                        .frame(width: 28, height: 28)
                        .scaleEffect(x: 1, y: openness)
                        .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
                }
            }
        }
        .frame(height: 32)
        .accessibilityHidden(true)
    }
}

struct LibraryGroupFramesKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}
