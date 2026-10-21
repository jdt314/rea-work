import SwiftUI

/// 启动复习先展示预览，点击开始后才进入已固定队列的翻卡会话。
struct DailyReviewPromptView: View {
    let words: [Word]
    var onCapture: () -> Void
    @State private var started = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if started {
                ReviewView(words: words)
            } else {
                DailyReviewInvitation(words: words, onClose: { dismiss() }, onStart: {
                    Haptics.tap()
                    started = true
                }, onCapture: onCapture)
            }
        }
    }
}

private struct DailyReviewInvitation: View {
    let words: [Word]
    let onClose: () -> Void
    let onStart: () -> Void
    let onCapture: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            Color(red: 251 / 255, green: 243 / 255, blue: 220 / 255)
                .ignoresSafeArea()
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let layout = ReviewInvitationLayout(size: geometry.size)
                if dynamicTypeSize.isAccessibilitySize || width > height || height < 600 {
                    ScrollView {
                        VStack(spacing: 30) {
                            ReviewPreviewCollage(words: Array(words.prefix(5)))
                                .frame(width: 300, height: 236)
                                .scaleEffect(min(width / 393, 1))
                            ReviewInvitationHeading(count: words.count)
                            ReviewInvitationStartButton(action: onStart)
                                .frame(maxWidth: 340)
                            ReviewInvitationCameraButton(size: 82, action: onCapture)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 28)
                        .padding(.top, 110)
                        .padding(.bottom, 48)
                    }
                } else {
                    // 602 × 1308 参考图：位置使用完整屏幕，尺寸按卡组所在区域缩放。
                    ReviewPreviewCollage(words: Array(words.prefix(5)))
                        .frame(width: 300, height: 236)
                        .scaleEffect(layout.scale)
                        .position(layout.collageCenter)
                    ReviewInvitationHeading(count: words.count)
                        .frame(width: width - 40)
                        .position(layout.headingCenter)
                    ReviewInvitationStartButton(height: 58 * layout.scale, action: onStart)
                        .frame(width: layout.buttonWidth)
                        .position(layout.startCenter)
                    ReviewInvitationCameraButton(size: 82 * layout.scale, action: onCapture)
                        .position(layout.cameraCenter)
                }
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .topLeading) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Palette.stickerInk)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.15), in: Circle())
                    .overlay { Circle().strokeBorder(.black.opacity(0.1), lineWidth: 0.5) }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 14)
            .accessibilityLabel("关闭复习提醒")
            .accessibilityIdentifier("closeReviewPromptButton")
        }
        .preferredColorScheme(.light)
        .accessibilityIdentifier("dailyReviewPrompt")
    }
}

/// 锚点来自用户提供的启动提示截图；保留少量词卡及辅助功能字号的独立布局。
private struct ReviewInvitationLayout {
    let size: CGSize

    var scale: CGFloat { min(size.width / 393, size.height / 854, 1.2) }
    var collageCenter: CGPoint { point(y: 537) }
    var headingCenter: CGPoint { point(y: 835) }
    var startCenter: CGPoint { point(y: 987) }
    var cameraCenter: CGPoint { point(y: 1184) }
    var buttonWidth: CGFloat { min(size.width * (400 / 602.0), 340) }

    private func point(y: CGFloat) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height * y / 1308)
    }
}

private struct ReviewInvitationHeading: View {
    let count: Int
    @ScaledMetric(relativeTo: .title2) private var titleSize = 22
    @ScaledMetric(relativeTo: .subheadline) private var subtitleSize = 17

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            VStack(spacing: 8) {
                Text(HomePresentation.greeting(at: timeline.date))
                    .font(.system(size: titleSize))
                    .foregroundStyle(Palette.stickerInk)
                    .accessibilityIdentifier("reviewGreeting")
                Text("今天有 \(count) 个单词需要复习")
                    .font(.system(size: subtitleSize))
                    .foregroundStyle(Color(red: 0.60, green: 0.60, blue: 0.56))
                    .accessibilityIdentifier("reviewDueCount")
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ReviewInvitationStartButton: View {
    var height: CGFloat = 58
    let action: () -> Void
    @ScaledMetric(relativeTo: .subheadline) private var textSize = 15

    var body: some View {
        Button(action: action) {
            Text("开始复习")
                .font(.system(size: textSize, weight: .semibold))
                .foregroundStyle(Color(red: 251 / 255, green: 243 / 255, blue: 220 / 255))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .frame(minHeight: height)
                .background(.black, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("startDailyReviewButton")
    }
}

private struct ReviewInvitationCameraButton: View {
    let size: CGFloat
    let action: () -> Void
    private let colors: [Color] = [
        Color(red: 0.61, green: 0.84, blue: 0.73),
        Palette.stickerLilac,
        Color(red: 0.70, green: 0.88, blue: 0.97),
        Color(red: 0.96, green: 0.76, blue: 0.90),
        Color(red: 0.87, green: 0.98, blue: 0.12)
    ]

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(.white)
                ForEach(0..<5) { index in
                    ReviewInvitationBlade()
                        .fill(colors[index])
                        .rotationEffect(.degrees(Double(index) * 72))
                }
            }
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.09), radius: 20, y: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("拍摄单词")
        .accessibilityIdentifier("reviewCaptureButton")
    }
}

/// 五片旋转光圈；参考图的内缘为叶片交错轮廓，不是等宽圆环。
private struct ReviewInvitationBlade: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width * 0.45
        func point(_ fraction: CGFloat, _ angle: Double) -> CGPoint {
            CGPoint(x: center.x + radius * fraction * cos(angle * .pi / 180),
                    y: center.y + radius * fraction * sin(angle * .pi / 180))
        }
        var path = Path()
        path.move(to: point(1, -90))
        path.addArc(center: center, radius: radius, startAngle: .degrees(-90),
                    endAngle: .degrees(-22), clockwise: false)
        path.addLine(to: point(0.55, 28))
        path.addQuadCurve(to: point(0.48, -48), control: point(0.48, -6))
        path.closeSubpath()
        return path
    }
}

private struct ReviewPreviewCollage: View {
    let words: [Word]

    var body: some View {
        ZStack {
            ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                let placement = ReviewPreviewPlacement.at(index, count: words.count)
                ReviewPreviewCard(data: word.imageData, asset: word.assetName, color: placement.color)
                    .frame(width: 100, height: 118)
                    .rotationEffect(.degrees(placement.angle))
                    .position(x: placement.x, y: placement.y)
                    .zIndex(placement.depth)
            }
        }
        .shadow(color: Color(red: 0.45, green: 0.37, blue: 0.24).opacity(0.13), radius: 28, y: 14)
        .accessibilityHidden(true)
    }
}

private struct ReviewPreviewPlacement {
    let x: CGFloat
    let y: CGFloat
    let angle: Double
    let color: Color
    let depth: Double

    static func at(_ index: Int, count: Int) -> Self {
        let colors = [
            Color(red: 0.75, green: 0.73, blue: 0.67),
            Color(red: 0.76, green: 0.80, blue: 0.77),
            Color(red: 0.61, green: 0.56, blue: 0.46),
            Color(red: 0.71, green: 0.68, blue: 0.61),
            Color(red: 0.65, green: 0.62, blue: 0.55)
        ]
        let positions: [(CGFloat, CGFloat, Double)]
        switch count {
        case 1: positions = [(150, 118, -7)]
        case 2: positions = [(101, 112, -10), (199, 124, 9)]
        case 3: positions = [(53, 124, -10), (150, 107, 8), (247, 124, -5)]
        case 4: positions = [(101, 70, -10), (199, 70, 8), (101, 170, 9), (199, 170, -9)]
        default: positions = [(57, 69, -10), (152, 69, 9), (247, 69, -5),
                              (105, 169, 10), (201, 169, -9)]
        }
        let point = positions[index]
        // 五卡构图中上排盖住下排，中间的卡片再盖住两侧。
        let depth: Double = count == 5 || count == 3
            ? (index == 1 ? 2 : (index < 3 ? 1 : 0)) : 0
        return Self(x: point.0, y: point.1, angle: point.2, color: colors[index], depth: depth)
    }
}

private struct ReviewPreviewCard: View {
    let data: Data?
    let asset: String?
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(color)
            Canvas { context, size in
                // 固定纸张颗粒，重绘时不随机闪烁。
                for index in 0..<180 {
                    let x = CGFloat((index * 37 + 11) % 97) / 97 * size.width
                    let y = CGFloat((index * 53 + 7) % 127) / 127 * size.height
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 0.7, height: 0.7)),
                                 with: .color(.black.opacity(0.1)))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
            StickerArtwork(data: data, asset: asset)
                .frame(width: 44, height: 68)
        }
    }
}
