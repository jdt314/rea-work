import SwiftUI
import UIKit

extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Semantic surfaces follow the window trait collection, including sheets and system changes.
/// Artwork colors stay fixed so white sticker outlines always surround dark lettering.
enum Palette {
    private static func adaptive(_ light: UIColor, _ dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light })
    }

    static let home = adaptive(UIColor(red: 0.958, green: 0.960, blue: 0.964, alpha: 1),
                               UIColor(white: 0.105, alpha: 1))
    static let paper = adaptive(UIColor(red: 0.976, green: 0.969, blue: 0.981, alpha: 1),
                                UIColor(white: 0.105, alpha: 1))
    static let library = adaptive(UIColor(white: 0.965, alpha: 1), UIColor(white: 0.105, alpha: 1))
    static let surface = adaptive(.white, UIColor(white: 0.17, alpha: 1))
    static let ink = adaptive(UIColor(red: 0.12, green: 0.17, blue: 0.21, alpha: 1),
                              UIColor(white: 0.94, alpha: 1))
    static let muted = Color(uiColor: .secondaryLabel)
    static let separator = Color(uiColor: .separator)
    static let orange = adaptive(UIColor(red: 0.72, green: 0.32, blue: 0.02, alpha: 1),
                                 UIColor(red: 1, green: 0.68, blue: 0.28, alpha: 1))
    static let lilac = adaptive(UIColor(red: 0.48, green: 0.35, blue: 0.70, alpha: 1),
                                UIColor(red: 0.77, green: 0.68, blue: 0.95, alpha: 1))
    static let stickerInk = Color(red: 0.12, green: 0.17, blue: 0.21)
    static let stickerOrange = Color(red: 0.72, green: 0.32, blue: 0.02)
    static let stickerLilac = Color(red: 0.70, green: 0.63, blue: 0.86)
    static let cardInk = Color(white: 0.12)
}

struct PaperBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var color: Color = Palette.paper
    var body: some View {
        GeometryReader { proxy in
            color.overlay {
                if colorScheme != .dark {
                    Canvas { context, _ in
                        for x in stride(from: 10.0, to: proxy.size.width, by: 18) {
                            for y in stride(from: 8.0, to: proxy.size.height, by: 18) {
                                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                                             with: .color(.gray.opacity(0.105)))
                            }
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct ApertureShape: Shape {
    let index: Int
    var cameraProgress: CGFloat = 0

    var animatableData: CGFloat {
        get { cameraProgress }
        set { cameraProgress = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = rect.width * (0.46 - 0.012 * cameraProgress)
        let inner = rect.width * 0.365
        let start = Double(index) * 72 - 106 + 58.5 * cameraProgress
        let sweep = 65 - 9 * cameraProgress
        func point(_ radius: Double, _ degrees: Double) -> CGPoint {
            CGPoint(x: center.x + radius * cos(degrees * .pi / 180),
                    y: center.y + radius * sin(degrees * .pi / 180))
        }
        p.move(to: point(outer, start))
        p.addArc(center: center, radius: outer, startAngle: .degrees(start), endAngle: .degrees(start + sweep), clockwise: false)
        p.addLine(to: point(inner, start + 54))
        p.addArc(center: center, radius: inner, startAngle: .degrees(start + 54), endAngle: .degrees(start - 4), clockwise: true)
        p.closeSubpath()
        return p
    }
}

struct ShutterButton: View {
    var action: () -> Void
    var size: CGFloat = 76
    var disabled = false
    var cameraProgress: CGFloat = 0
    private let colors: [Color] = [Color(red: 0.61, green: 0.84, blue: 0.73), Palette.stickerLilac, Color(red: 0.70, green: 0.88, blue: 0.97), Color(red: 0.96, green: 0.76, blue: 0.90), Color(red: 0.87, green: 0.98, blue: 0.12)]
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(.white)
                ForEach(0..<5) { index in
                    ApertureShape(index: index, cameraProgress: cameraProgress).fill(colors[index])
                }
                Circle().fill(.white).frame(width: size * (0.70 + 0.13 * cameraProgress))
            }
            .frame(width: size, height: size)
            .scaleEffect(1 + 0.31 * cameraProgress)
            .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
        }
        .buttonStyle(ShutterPressStyle())
        .disabled(disabled)
        .accessibilityLabel("拍摄单词")
        .accessibilityIdentifier("captureButton")
    }
}

struct CameraUtilityIcon: View {
    let symbol: String
    var body: some View {
        Group {
            if symbol == "photo" {
                CameraPhotoGlyph()
                    .stroke(style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 23, height: 22)
            } else if symbol == "retake" {
                RetakeGlyph().stroke(style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 25, height: 25)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .bold))
            }
        }
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .modifier(CameraGlass())
    }
}

private struct CameraGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.clear.interactive(), in: Circle())
        } else {
            content.background(.ultraThinMaterial, in: Circle())
        }
    }
}

private struct CameraPhotoGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: 5)
        path.move(to: CGPoint(x: rect.width * 0.23, y: rect.height * 0.72))
        path.addLine(to: CGPoint(x: rect.width * 0.40, y: rect.height * 0.43))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.53, y: rect.height * 0.43),
                          control: CGPoint(x: rect.width * 0.465, y: rect.height * 0.32))
        path.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.height * 0.73))
        path.addEllipse(in: CGRect(x: rect.width * 0.65, y: rect.height * 0.25, width: 1.5, height: 1.5))
        return path
    }
}

struct CameraAppearancePreferenceKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

private struct ShutterPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .rotationEffect(.degrees(configuration.isPressed && !reduceMotion ? 12 : 0))
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct RoundButton: View {
    let symbol: String
    let label: String
    var size: CGFloat = 48
    var prominent = false
    var symbolSize: CGFloat? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Group {
                if symbol == "retake" {
                    RetakeGlyph().stroke(style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                        .frame(width: symbolSize ?? 24, height: symbolSize ?? 24)
                } else {
                    Image(systemName: symbol)
                }
            }
                .font(.system(size: symbolSize ?? (prominent ? 24 : 19), weight: .bold))
                .foregroundStyle(prominent ? Palette.orange : Palette.muted)
                .frame(width: size, height: size)
                .background(Palette.surface, in: Circle())
                .shadow(color: .black.opacity(0.035), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct RetakeGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height) }
        var path = Path()
        path.move(to: point(0.19, 0.65))
        path.addCurve(to: point(0.76, 0.72), control1: point(-0.13, 0.05), control2: point(1.23, 0.09))
        path.move(to: point(0.76, 0.72))
        path.addLine(to: point(0.60, 0.63))
        path.move(to: point(0.76, 0.72))
        path.addLine(to: point(0.83, 0.53))
        return path
    }
}

struct StickerArtwork: View {
    var data: Data?
    var asset: String?
    var outlined = true
    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFit()
            } else if let asset {
                Image(asset).resizable().scaledToFit()
            } else {
                Image(systemName: "photo").resizable().scaledToFit().padding(28).foregroundStyle(Palette.lilac)
            }
        }
        // UIImage 解码对象变化不参与隐式交叉淡化；外层 frame / position 仍正常插值。
        .transaction { $0.animation = nil }
        .shadow(color: outlined ? .white : .clear, radius: 0, x: 3, y: 0)
        .shadow(color: outlined ? .white : .clear, radius: 0, x: -3, y: 0)
        .shadow(color: outlined ? .white : .clear, radius: 0, x: 0, y: 3)
        .shadow(color: outlined ? .white : .clear, radius: 0, x: 0, y: -3)
        .shadow(color: .black.opacity(outlined ? 0.12 : 0), radius: 7, x: 0, y: 7)
    }
}

struct StickerLabel: View {
    let text: String
    var size: CGFloat = 22
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .tracking(-0.7)
            .foregroundStyle(Palette.stickerInk)
            .multilineTextAlignment(.center)
            .lineSpacing(-2)
            .modifier(StickerTextOutline(width: 4))
            .shadow(color: .black.opacity(0.06), radius: 7, y: 5)
    }
}

/// 从实际排版后的文字 alpha 扩出连续白边，随字形、中文和换行变化。
/// 背景单独合成，避免描边覆盖字面或吞掉第二行文字。
struct StickerTextOutline: ViewModifier {
    var width: CGFloat = 5

    func body(content: Content) -> some View {
        content.padding(width)
            .background {
                Canvas { context, size in
                    guard let text = context.resolveSymbol(id: 0) else { return }
                    context.addFilter(.alphaThreshold(min: 0.015, color: .white))
                    context.addFilter(.blur(radius: width / 2))
                    context.drawLayer { layer in
                        layer.draw(text, at: CGPoint(x: size.width / 2, y: size.height / 2))
                    }
                } symbols: {
                    content.padding(width).tag(0)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }
}

enum Haptics {
    @MainActor static func tap() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    @MainActor static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}
