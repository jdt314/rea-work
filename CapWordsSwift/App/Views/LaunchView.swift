import SwiftUI
import UIKit

@MainActor
enum LaunchArtwork {
    // SwiftUI 按图集名查找与 storyboard 的文件资源查找不是同一路径。
    // 显式通过 UIKit 加载同一 bundle PNG，缺资源时立即暴露问题，不能默默变透明。
    static let bands: UIImage = {
        guard let image = UIImage(named: "launch-bands.png", in: .main, compatibleWith: nil) else {
            preconditionFailure("缺少启动背景 launch-bands.png")
        }
        return image
    }()
}

#if DEBUG
/// 直接预览已编译的系统 storyboard；隔离静态资源问题与应用动画问题。
struct LaunchScreenPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIStoryboard(name: "LaunchScreen", bundle: .main).instantiateInitialViewController()!
    }
    func updateUIViewController(_ controller: UIViewController, context: Context) {}
}
#endif

/// 本地复刻的启动协调器。窗口顺序/时序来自 REA；图案路径为可缩放重建。
@MainActor @Observable
final class LaunchCoordinator {
    private(set) var isVisible: Bool
    private(set) var isRevealingContent = false
    var contentReady = false
    @ObservationIgnored private var didInstall = false
    @ObservationIgnored private var overlayWindow: UIWindow?
    @ObservationIgnored private weak var contentWindow: UIWindow?

    init(skipAnimation: Bool = false) { isVisible = !skipAnimation }

    var needsFirstFrameCover: Bool { isVisible && !isRevealingContent }

    func beginContentReveal() {
        guard isVisible, didInstall else { return }
        // SwiftUI 的 task/onAppear 不保证独立窗口已提交到屏幕。
        // 直到不透明条带真正开始退场才撤掉主窗口兜底，不以出现回调为依据。
        isRevealingContent = true
    }

    func attach(to window: UIWindow) {
        guard isVisible, !didInstall, let scene = window.windowScene else { return }
        didInstall = true
        contentWindow = window
        let overlay = UIWindow(windowScene: scene)
        overlay.frame = scene.coordinateSpace.bounds
        overlay.windowLevel = .statusBar + 2
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = false
        let host = UIHostingController(rootView: LaunchAnimationView(coordinator: self))
        host.view.backgroundColor = .clear
        overlay.rootViewController = host
        overlayWindow = overlay
        host.view.frame = overlay.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        overlay.isHidden = false // 不抢走主窗口的 key / 输入焦点。
    }

    func finish() {
        guard isVisible else { return }
        overlayWindow?.isHidden = true
        overlayWindow?.rootViewController = nil
        overlayWindow = nil
        isVisible = false
        if let contentWindow, !contentWindow.isKeyWindow { contentWindow.makeKeyAndVisible() }
    }
}

/// 系统快照消失而独立动画窗口尚未呈现时的兜底遮罩，与两者共用素材。
/// 保持到条带退场开始；此时独立窗口已完整展示，不会在窗口交接期间漏出首页。
struct LaunchFirstFrame: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: LaunchArtwork.bands).renderingMode(.original).resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                LaunchMark().frame(width: 86, height: 86)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct LaunchWindowBridge: UIViewRepresentable {
    let coordinator: LaunchCoordinator
    func makeUIView(context: Context) -> WindowProbe { WindowProbe(coordinator: coordinator) }
    func updateUIView(_ view: WindowProbe, context: Context) {}

    final class WindowProbe: UIView {
        let coordinator: LaunchCoordinator
        init(coordinator: LaunchCoordinator) {
            self.coordinator = coordinator
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            isAccessibilityElement = false
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window else { return }
            // attach 只更新 ObservationIgnored 窗口字段，不改 SwiftUI 可观察状态。
            // 在主窗口首帧前同步挂载，避免下一 Task 才覆盖时先闪出词库。
            coordinator.attach(to: window)
        }
    }
}

private struct LaunchAnimationView: View {
    let coordinator: LaunchCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var logoLift: CGFloat = 0
    @State private var titleOpacity = 0.0
    @State private var titleLift: CGFloat = 0
    @State private var wheatGrowth: CGFloat = 0
    @State private var artworkOpacity = 1.0
    @State private var exitProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LaunchBands(progress: reduceMotion ? 0 : exitProgress)
                    .opacity(reduceMotion ? 1 - exitProgress : 1)
                ZStack {
                    LaunchMark().frame(width: 86, height: 86).offset(y: logoLift)
                    Text("Wordrove")
                        .font(.custom("TimesNewRomanPS-BoldMT", size: 32))
                        .foregroundStyle(.black)
                        .offset(y: 62 + titleLift)
                        .opacity(titleOpacity)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .opacity(artworkOpacity)
                VStack {
                    Spacer()
                    HStack(spacing: 18) {
                        Image(systemName: "laurel.leading")
                        Text("Your world, in words.")
                            .font(.system(size: 15, weight: .medium, design: .serif))
                        Image(systemName: "laurel.trailing")
                    }
                    .font(.system(size: 37, weight: .light))
                    .foregroundStyle(.black.opacity(0.8))
                    .scaleEffect(x: 1, y: max(0.01, wheatGrowth), anchor: .bottom)
                    .opacity(Double(wheatGrowth))
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 55)
                }.opacity(artworkOpacity)
            }
            .ignoresSafeArea()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Wordrove 正在打开")
            .accessibilityIdentifier("launchOverlay")
            .task {
                await animate(height: geometry.size.height)
            }
            .modifier(LaunchProgressObserver(progress: exitProgress) { coordinator.finish() })
        }.ignoresSafeArea()
    }

    @MainActor private func animate(height: CGFloat) async {
        do {
            // 首屏在覆盖层下完成布局；不等待网络，也不在动画之后才创建首页。
            while !coordinator.contentReady {
                try await Task.sleep(for: .milliseconds(16))
            }
            if reduceMotion {
                titleOpacity = 1
                wheatGrowth = 1
                try await Task.sleep(for: .milliseconds(200))
                coordinator.beginContentReveal()
                withAnimation(.easeOut(duration: 0.16)) { exitProgress = 1 }
                try await Task.sleep(for: .milliseconds(200))
                coordinator.finish()
                return
            }
            withAnimation(.spring(response: 0.62, dampingFraction: 0.84).delay(0.2)) {
                logoLift = -min(max(height * 0.027, 12), 32)
            }
            withAnimation(.easeOut(duration: 0.42).delay(0.4)) {
                titleOpacity = 1
                titleLift = 20
            }
            withAnimation(.spring(response: 0.78, dampingFraction: 0.72).delay(0.4)) { wheatGrowth = 1 }
            try await Task.sleep(for: .seconds(2))
            coordinator.beginContentReveal()
            withAnimation(.easeOut(duration: 0.16)) { artworkOpacity = 0 }
            withAnimation(.spring(response: 1, dampingFraction: 1)) { exitProgress = 1 }
            // 0.76 的逐帧进度观察为主；3.2 秒的调度作为未回调时的兜底。
            try await Task.sleep(for: .milliseconds(1200))
            coordinator.finish()
        } catch {
            // 视图移除取消任务，不在取消路径重复触发导航。
        }
    }
}

private struct LaunchProgressObserver: AnimatableModifier {
    nonisolated var progress: CGFloat
    nonisolated let completion: @MainActor @Sendable () -> Void
    nonisolated var animatableData: CGFloat {
        get { progress }
        set {
            progress = newValue
            if newValue >= 0.76 {
                let callback = completion
                Task { @MainActor in callback() }
            }
        }
    }
    func body(content: Content) -> some View { content }
}

/// 与 LaunchScreen 共用同一张原色背景，按相同的 aspect-fill 几何裁切。
/// 只移动带状切片，不重新绘制另一套近似颜色，保证系统页到动画首帧连续。
private struct LaunchBands: View, Animatable {
    nonisolated var progress: CGFloat
    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    var body: some View {
        let background = Image(uiImage: LaunchArtwork.bands).renderingMode(.original)
        Canvas { context, size in
            let reference = CGSize(width: 393, height: 852)
            let scale = max(size.width / reference.width, size.height / reference.height)
            context.translateBy(x: (size.width - reference.width * scale) / 2,
                                y: (size.height - reference.height * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            let artwork = context.resolve(background)
            let slope: CGFloat = 0.58
            let bandHeight = reference.height / 4.4
            for index in -1..<7 {
                let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
                let local = min(max((progress - CGFloat(index + 1) * 0.022) / 0.68, 0), 1)
                let shift = direction * local * reference.width * 1.65
                let top = CGFloat(index) * bandHeight
                var path = Path()
                path.move(to: CGPoint(x: 0, y: top))
                path.addLine(to: CGPoint(x: reference.width, y: top - slope * reference.width))
                path.addLine(to: CGPoint(x: reference.width, y: top + bandHeight + 1 - slope * reference.width))
                path.addLine(to: CGPoint(x: 0, y: top + bandHeight + 1))
                path.closeSubpath()
                var band = context
                band.translateBy(x: shift, y: -slope * shift)
                band.clip(to: path)
                band.draw(artwork, in: CGRect(origin: .zero, size: reference))
            }
        }.clipped()
    }
}

/// 可缩放的 C 形光圈轮廓；未把复刻 App 标记为原版的获奖产品。
struct LaunchMark: View {
    var body: some View {
        Image("launch-mark").resizable().scaledToFit().accessibilityHidden(true)
    }
}

/// REA 已确认 C 引导覆盖词库；后续屏幕未完整恢复，这里提供明确可用的本地入口。
struct IntroView: View {
    var onComplete: () -> Void
    @AppStorage("learningLanguage") private var language = LearningLanguage.english.rawValue
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            LaunchMark().frame(width: 86, height: 86)
            Text("把生活，变成单词")
                .font(.system(size: 30, weight: .medium, design: .serif))
            Text("拍下身边的事物，收集你的单词贴纸。\n再用每天的复习，记住它们。")
                .font(.system(size: 16)).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Picker("想学习的语言", selection: $language) {
                ForEach(LearningLanguage.allCases) { Text($0.title).tag($0.rawValue) }
            }.pickerStyle(.menu).accessibilityIdentifier("onboardingLanguage")
            Spacer()
            Button("开始收集") { onComplete() }
                .font(.system(size: 18, weight: .semibold)).foregroundStyle(Palette.stickerInk)
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(Color(red: 1, green: 0.83, blue: 0.34), in: Capsule())
                .accessibilityIdentifier("completeOnboardingButton")
            Text("随时可以在设置里更换学习语言")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.home.ignoresSafeArea())
        .accessibilityIdentifier("onboardingScreen")
    }
}
