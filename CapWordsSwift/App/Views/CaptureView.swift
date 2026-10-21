import SwiftUI
import PhotosUI
import SwiftData

@MainActor @Observable
final class CaptureFlow {
    enum Phase { case camera, analyzing, dissolving, cutout, lifting, floating, revealing, result, saving }
    var phase: Phase = .camera
    var result: RecognitionResult?
    var original: Data?
    var pixels: [DustPixel] = []
    var dissolveStart = Date.now
    var floatStart = Date.now
    var floatSettled = false
    var error: String?
    var recognitionFailure: String?
    private var preparationTask: Task<Void, Never>?
    private var recognitionTask: Task<Void, Never>?
    private var animationTask: Task<Void, Never>?
    private var generation = UUID()
    private var requestGeneration = UUID()
    private var gate = CaptureResultGate()
    private var pendingWord: AIWordEntry?
    private var retryOperation: (() -> Void)?
    private var requestScene = false
    private var requestDemo = false
    private var reducedMotion = false
    var canRetry: Bool { retryOperation != nil }
    func retry() { retryOperation?() }

    func begin(data: Data, language: LearningLanguage, scene: Bool = false, demo: Bool = false, reduceMotion: Bool = false) {
        cancel()
        let token = generation
        gate = CaptureResultGate()
        error = nil; recognitionFailure = nil; retryOperation = nil; pendingWord = nil
        original = data; result = nil; pixels = []; floatSettled = false
        requestScene = scene; requestDemo = demo; reducedMotion = reduceMotion
        phase = .analyzing
        preparationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let output: RecognitionResult
                if demo, let sticker = UIImage(named: "sample-donut")?.pngData() {
                    output = RecognitionResult(imageData: sticker, originalData: data, name: "", meaning: "", pronunciation: "",
                                               example: "", exampleMeaning: "", category: "日常", languageCode: language.rawValue,
                                               isScene: false, needsNaming: true,
                                               subjectRect: CGRect(x: 0.08, y: 0.38, width: 0.84, height: 0.46))
                } else {
                    output = try await RecognitionService.shared.prepare(data: data, language: language, scene: scene) { [weak self] normalized in
                        await self?.startRecognition(image: normalized, languageCode: language.rawValue, preparationToken: token)
                    }
                }
                try Task.checkCancellation()
                guard generation == token else { return }
                result = output
                if let pendingWord { result?.apply(pendingWord) }
                original = output.originalData
                if demo { startRecognition() }
                let samples = reduceMotion || output.isScene ? [] : await DustSampler.sample(output.originalData, subjectData: output.imageData,
                                                                                            subjectRect: output.subjectRect)
                try Task.checkCancellation()
                guard generation == token else { return }
                pixels = samples
                dissolveStart = .now
                // 冻结照片与纹理碎片直接交接，避免透明度交叉淡入造成双影。
                phase = reduceMotion || output.isScene ? .cutout : .dissolving
                animationTask = Task { [weak self] in
                    do {
                        try await Task.sleep(for: .milliseconds(reduceMotion || output.isScene ? 0 : 1820))
                        guard let self, generation == token, phase == .dissolving else { return }
                        phase = .cutout
                        pixels = []
                    } catch { }
                }
            } catch is CancellationError { }
            catch {
                guard generation == token else { return }
                recognitionTask?.cancel()
                requestGeneration = UUID()
                self.error = error.localizedDescription
                retryOperation = { [weak self] in
                    self?.begin(data: data, language: language, scene: scene, demo: demo, reduceMotion: reduceMotion)
                }
                phase = .camera
            }
            if generation == token { preparationTask = nil }
        }
    }

    func retryRecognition() { startRecognition() }

    private func startRecognition(image: Data? = nil, languageCode: String? = nil, preparationToken: UUID? = nil) {
        if let preparationToken, generation != preparationToken { return }
        guard let image = image ?? result?.originalData, let languageCode = languageCode ?? result?.languageCode else { return }
        recognitionTask?.cancel()
        requestGeneration = UUID()
        let requestToken = requestGeneration
        let token = generation
        recognitionFailure = nil
        recognitionTask = Task { [weak self] in
            guard let self else { return }
            do {
                var word: AIWordEntry
                if requestDemo, let entry = Vocabulary.match("donut") {
                    #if DEBUG
                    let args = ProcessInfo.processInfo.arguments
                    if args.contains("--recognition-slow") { try await Task.sleep(for: .seconds(8)) }
                    if args.contains("--recognition-error") { throw AIRecognitionError.network }
                    #endif
                    let language = LearningLanguage(rawValue: languageCode) ?? .english
                    word = AIWordEntry(name: entry.name(in: language) ?? entry.english, meaning: entry.meaning,
                                       pronunciation: language == .english ? entry.pronunciation : "",
                                       example: language == .english ? entry.example : "",
                                       exampleMeaning: language == .english ? entry.exampleMeaning : "",
                                       category: entry.category, languageCode: languageCode, needsNaming: false)
                } else {
                    word = try await AIRecognitionClient().recognize(image: image, languageCode: languageCode,
                                                                     scene: requestScene, configuration: AIRecognitionSettings.load(),
                                                                     nativeLanguageCode: UserDefaults.standard.string(forKey: "nativeLanguage") ?? "zh-CN")
                }
                #if DEBUG
                if requestDemo {
                    let args = ProcessInfo.processInfo.arguments
                    if args.contains("--result-fixture-key") { word.name = "key"; word.meaning = "钥匙" }
                    if args.contains("--result-fixture-long") {
                        word.name = "wireless game controller"; word.meaning = "无线游戏手柄"
                    }
                    if args.contains("--result-fixture-missing") { word.meaning = "" }
                }
                #endif
                try Task.checkCancellation()
                guard generation == token, requestGeneration == requestToken else { return }
                pendingWord = word
                result?.apply(word)
                gate.receiveWord()
                revealIfReady()
            } catch is CancellationError { }
            catch {
                guard generation == token, requestGeneration == requestToken else { return }
                recognitionFailure = error.localizedDescription
            }
            if generation == token, requestGeneration == requestToken { recognitionTask = nil }
        }
    }

    func confirmSubject(reduceMotion: Bool = false) {
        guard result != nil, phase == .cutout || phase == .dissolving else { return }
        animationTask?.cancel()
        gate.confirm()
        let token = generation
        reducedMotion = reduceMotion
        phase = .lifting
        pixels = []
        animationTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 70))
                guard let self, generation == token else { return }
                floatStart = .now
                withAnimation(reduceMotion ? .easeOut(duration: 0.18) : .spring(response: 0.50, dampingFraction: 0.86)) { phase = .floating }
                try await Task.sleep(for: .milliseconds(reduceMotion ? 180 : 550))
                guard generation == token else { return }
                floatStart = .now
                floatSettled = true
                gate.finishTransition()
                revealIfReady()
            } catch { }
        }
    }

    func useManualNaming() {
        recognitionTask?.cancel()
        requestGeneration = UUID()
        recognitionFailure = nil
        gate.receiveWord()
        revealIfReady()
    }

    private func revealIfReady() {
        guard gate.takeReveal() else { return }
        let token = generation
        withAnimation(reducedMotion ? .easeOut(duration: 0.18) : .spring(response: 0.50, dampingFraction: 0.64)) { phase = .revealing }
        animationTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(self?.reducedMotion == true ? 120 : 260))
                guard let self, generation == token else { return }
                withAnimation(reducedMotion ? .easeOut(duration: 0.18) : .spring(response: 0.42, dampingFraction: 0.72)) { phase = .result }
                Haptics.success()
            } catch { }
        }
    }

    func cancel() {
        generation = UUID(); requestGeneration = UUID()
        preparationTask?.cancel(); recognitionTask?.cancel(); animationTask?.cancel()
        preparationTask = nil; recognitionTask = nil; animationTask = nil
    }
    func reset() {
        cancel()
        gate = CaptureResultGate()
        result = nil; pendingWord = nil; error = nil; recognitionFailure = nil; retryOperation = nil
        original = nil; pixels = []
        withAnimation { phase = .camera }
    }
}

struct CaptureView: View {
    var onSaved: ((Word) -> Void)? = nil
    var onClose: (() -> Void)? = nil
    var usesLibraryPresentation = false
    var cameraReveal: Double = 1
    var cameraVisible = true
    var showsCameraGuides = true
    var onCameraModeChanged: ((Bool) -> Void)? = nil
    @Environment(StickerFlightState.self) private var flight
    @State private var viewportOrigin: CGPoint = .zero
    @State private var sourceArtworkFrame: CGRect = .zero
    @State private var flightSourceFrame: CGRect = .zero
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("learningLanguage") private var languageCode = LearningLanguage.english.rawValue
    @State private var camera = CameraModel()
    @State private var flow = CaptureFlow()
    @State private var photo: PhotosPickerItem?
    @State private var editing = false
    @State private var cropping = false
    @State private var shutterBusy = false
    @State private var cameraTask: Task<Void, Never>?
    @State private var saveTask: Task<Void, Never>?
    @State private var previewDustTime: Double?

    private var language: LearningLanguage { LearningLanguage(rawValue: languageCode) ?? .english }
    private var isCamera: Bool { flow.phase == .camera }
    private var presentedResult: Bool { flow.phase == .result }
    private var demoMode: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    private var previewAsset: String {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--camera-layout-reference") { return "camera-reference-surface" }
        #endif
        return "demo-camera"
    }

    var body: some View {
        GeometryReader { geometry in
            let insets = geometry.safeAreaInsets
            let fullSize = CGSize(width: geometry.size.width, height: geometry.size.height + insets.top + insets.bottom)
            ZStack {
                PaperBackground()
                Group {
                    if isCamera {
                        ZStack {
                            Color.black
                            cameraLayer(size: fullSize).opacity(cameraVisible ? 1 : 0)
                        }
                    }
                    else { composition(size: fullSize) }
                }
                .frame(width: fullSize.width, height: fullSize.height)
                .offset(y: (insets.bottom - insets.top) / 2)
                .frame(width: geometry.size.width, height: geometry.size.height)
                VStack {
                    if !usesLibraryPresentation || !isCamera { topBar }
                    Spacer()
                    if isCamera { cameraControls }
                    else if flow.phase == .analyzing {
                        VStack(spacing: 14) {
                            ProgressView().tint(.white)
                            Text("正在提取主体…").font(.system(size: 13)).foregroundStyle(.white)
                            Button("取消") { flow.reset() }.font(.system(size: 13)).padding(12)
                        }.foregroundStyle(.white).padding(.bottom, 34)
                    } else if flow.phase == .dissolving || flow.phase == .cutout {
                        Color.clear.frame(height: 1)
                    } else if flow.phase == .floating {
                        VStack(spacing: 14) {
                            if let failure = flow.recognitionFailure {
                                Text(failure).font(.system(size: 13)).multilineTextAlignment(.center)
                                HStack(spacing: 24) {
                                    Button("重试识别") { flow.retryRecognition() }
                                    Button("手动填写") { flow.useManualNaming() }
                                }.font(.system(size: 14, weight: .medium))
                            }
                            Button("取消") { flow.reset() }
                                .font(.system(size: 12)).foregroundStyle(Palette.muted)
                                .padding(.horizontal, 24).padding(.vertical, 8).background(.gray.opacity(0.06), in: Capsule())
                        }.padding(.horizontal, 30).padding(.bottom, 45)
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel(flow.recognitionFailure == nil ? "正在识别图片" : "识别失败")
                    }
                }
                if flow.phase == .dissolving || flow.phase == .cutout {
                    subjectControls(size: fullSize, topInset: insets.top)
                }
                if presentedResult {
                    resultControls(size: fullSize, topInset: insets.top)
                        .transition(.scale(scale: 0.65, anchor: .center).combined(with: .opacity))
                        .disabled(saveTask != nil)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .opacity(flow.phase == .saving ? 0 : 1)
            .overlay {
                if flow.phase == .saving, let result = flow.result {
                    flyingSticker(result: result, size: geometry.size)
                }
            }
            .onAppear { viewportOrigin = geometry.frame(in: .global).origin }
            .onChange(of: geometry.frame(in: .global)) { _, frame in viewportOrigin = frame.origin }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: isCamera)
        }
        .statusBarHidden(false)
        .onChange(of: isCamera) { _, value in onCameraModeChanged?(value) }
        .task {
            await camera.start()
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if (args.contains("--preview-result") || args.contains("--preview-cutout") || args.contains("--preview-dust") || args.contains("--preview-floating") || args.contains("--exercise-recognition")),
               let data = UIImage(named: "demo-camera")?.jpegData(compressionQuality: 0.95) {
                flow.begin(data: data, language: language, demo: true, reduceMotion: reduceMotion)
                while (flow.phase == .analyzing || flow.phase == .camera) && flow.error == nil {
                    do { try await Task.sleep(for: .milliseconds(20)) } catch { return }
                }
                guard flow.result != nil else { return }
                if args.contains("--exercise-recognition") {
                    try? await Task.sleep(for: .milliseconds(1900))
                    guard !Task.isCancelled else { return }
                    flow.confirmSubject(reduceMotion: reduceMotion)
                    if args.contains("--recognition-cancel") {
                        try? await Task.sleep(for: .seconds(1))
                        guard !Task.isCancelled else { return }
                        flow.reset()
                    }
                } else if args.contains("--preview-cutout") {
                    flow.cancel()
                    flow.phase = .cutout
                } else if args.contains("--preview-dust") {
                    flow.cancel()
                    previewDustTime = 0.35
                    flow.phase = .dissolving
                } else if args.contains("--preview-floating") {
                    flow.cancel()
                    flow.phase = .floating
                } else { flow.confirmSubject(reduceMotion: reduceMotion) }
            }
            #endif
        }
        .task(id: photo) {
            guard let photo else { return }
            do {
                guard let data = try await photo.loadTransferable(type: Data.self) else { throw RecognitionError.invalidImage }
                try Task.checkCancellation()
                flow.begin(data: data, language: language, reduceMotion: reduceMotion)
            } catch is CancellationError { }
            catch { flow.error = error.localizedDescription }
            self.photo = nil
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, isCamera {
                cameraTask?.cancel()
                cameraTask = Task { await camera.start() }
            } else if phase == .background { camera.engine.stop() }
        }
        .onDisappear { flow.cancel(); cameraTask?.cancel(); saveTask?.cancel(); camera.engine.stop() }
        .sheet(isPresented: $editing) {
            if let result = flow.result {
                WordEditor(name: result.name, meaning: result.meaning, pronunciation: result.pronunciation) { name, meaning, pronunciation in
                    flow.result?.name = name
                    flow.result?.meaning = meaning
                    flow.result?.pronunciation = pronunciation
                    // 改词后旧例句不再与新语义一致。
                    if name != result.name { flow.result?.example = ""; flow.result?.exampleMeaning = "" }
                    flow.result?.needsNaming = false
                }
            }
        }
        .sheet(isPresented: $cropping) {
            if let data = flow.original {
                ImageCropView(data: data) { cropped in flow.begin(data: cropped, language: language, reduceMotion: reduceMotion) }
            }
        }
        .alert("暂时没能完成", isPresented: Binding(get: { flow.error != nil || camera.error != nil }, set: { if !$0 { flow.error = nil; camera.error = nil } })) {
            if flow.canRetry { Button("重试识别") { flow.retry() } }
            Button("知道了", role: .cancel) { flow.error = nil; camera.error = nil }
        } message: { Text(flow.error ?? camera.error ?? "") }
    }

    private func cameraLayer(size: CGSize) -> some View {
        ZStack {
            if demoMode {
                Image(previewAsset).resizable().scaledToFill().frame(width: size.width, height: size.height).clipped()
            } else if camera.authorized {
                CameraPreview(engine: camera.engine).frame(width: size.width, height: size.height)
            } else {
                Color.black.ignoresSafeArea()
                VStack(spacing: 14) {
                    Image(systemName: "camera").font(.system(size: 34))
                    Text(camera.denied ? "允许相机权限，发现身边的单词" : "正在打开相机…").font(.system(size: 15))
                    if camera.denied {
                        Button("打开设置") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                    }
                }.foregroundStyle(.white).padding(.bottom, 120)
            }
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    FocusCorners(cameraStyle: true).stroke(.white.opacity(0.95), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    Text("请将物体置于框内").font(.system(size: 18)).foregroundStyle(.white.opacity(0.95)).padding(.bottom, 6)
                }
                .frame(width: geometry.size.width * 0.86, height: geometry.size.height * 0.49)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.467)
            }
            .allowsHitTesting(false)
            .opacity(!usesLibraryPresentation || showsCameraGuides ? 1 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: showsCameraGuides)
        }
        .frame(width: size.width, height: size.height)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                if isCamera || flow.phase == .floating || flow.phase == .revealing || presentedResult {
                    Button {
                        flow.cancel(); close()
                    } label: {
                        Image(systemName: "chevron.left").font(.system(size: 20, weight: .medium))
                            .foregroundStyle(isCamera ? .white : Palette.muted)
                            .frame(width: 44, height: 44, alignment: .leading)
                    }.accessibilityLabel("返回词库")
                }
                Text("\(Calendar.current.component(.month, from: .now))月\(Calendar.current.component(.day, from: .now))")
                    .font(.system(size: 26, design: .serif))
                if isCamera {
                    Text("Place the object within the frame")
                        .font(.system(size: 12))
                    if demoMode { Text("示例取景 · 可从相册选择真实照片").font(.system(size: 10)).opacity(0.8) }
                }
            }
            Spacer()
            if flow.phase == .analyzing || flow.phase == .dissolving || flow.phase == .cutout {
                Button {
                    if let data = flow.original { flow.begin(data: data, language: language, scene: true, reduceMotion: reduceMotion) }
                } label: {
                    Label("识别完整图片", systemImage: "photo")
                        .font(.system(size: 11)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(.white.opacity(0.18), in: Capsule())
                }.disabled(flow.phase == .analyzing)
            }
            if isCamera {
                Button { camera.flash.toggle() } label: {
                    Image(systemName: camera.flash ? "bolt.fill" : "bolt.slash")
                        .font(.system(size: 17)).frame(width: 36, height: 36)
                        .background(.black.opacity(0.1), in: Circle())
                }.accessibilityLabel(camera.flash ? "关闭闪光灯" : "开启闪光灯")
            }
        }
        .foregroundStyle(isCamera || flow.phase == .analyzing || flow.phase == .dissolving || flow.phase == .cutout ? .white : Palette.ink)
        .padding(.horizontal, 24).padding(.top, 4)
    }

    private func captureUtility(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            CameraUtilityIcon(symbol: symbol)
        }.buttonStyle(.plain).accessibilityLabel(label)
    }

    private var cameraControls: some View {
            HStack(spacing: usesLibraryPresentation ? 64 : 42) {
                Button { close() } label: {
                    CameraUtilityIcon(symbol: "xmark")
                }.buttonStyle(.plain).accessibilityLabel("取消拍摄")
                ShutterButton(action: shoot, size: usesLibraryPresentation ? 76 : 82,
                              disabled: shutterBusy || (!demoMode && !camera.ready),
                              cameraProgress: usesLibraryPresentation ? cameraReveal : 0)
                PhotosPicker(selection: $photo, matching: .images, photoLibrary: .shared()) {
                    CameraUtilityIcon(symbol: "photo")
                }.buttonStyle(.plain).accessibilityLabel("从相册选图")
            }.padding(.bottom, usesLibraryPresentation ? 10 : 26)
            .frame(maxWidth: .infinity)
            .opacity(usesLibraryPresentation ? cameraReveal : 1)
    }

    private func composition(size: CGSize) -> some View {
        let early = flow.phase == .analyzing || flow.phase == .dissolving || flow.phase == .cutout
        let saving = flow.phase == .saving
        let sourceSize = flow.original.flatMap { UIImage(data: $0)?.size } ?? size
        return ZStack {
            Color(white: early ? 0.61 : 0).ignoresSafeArea()
            PaperBackground()
                .clipShape(RoundedRectangle(cornerRadius: early || flow.phase == .lifting ? 28 : 0))
                .offset(y: early ? size.height + 100 : (flow.phase == .lifting ? size.height - 18 : 0))
            if early, let original = flow.original, let image = UIImage(data: original) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: size.width, height: size.height).clipped()
                    .opacity(flow.phase == .analyzing ? 1 : 0)
            }
            if flow.phase == .dissolving {
                PhotoDustView(pixels: flow.pixels, start: flow.dissolveStart, sourceSize: sourceSize, elapsedOverride: previewDustTime)
            }
            if let result = flow.result {
                let projected = ImagePlacement.aspectFill(source: sourceSize, viewport: size, normalizedRect: result.subjectRect)
                let initialWidth = projected.width
                let artworkWidth: CGFloat = early || flow.phase == .lifting ? initialWidth : (saving ? 112 : size.width * (flow.phase == .revealing || presentedResult ? 0.46 : 0.58))
                let image = UIImage(data: result.imageData)
                let aspect = (image?.size.height ?? 1) / max(image?.size.width ?? 1, 1)
                let artworkHeight = early || flow.phase == .lifting ? projected.height : min(artworkWidth * aspect, size.height * 0.25)
                let centerX = early || flow.phase == .lifting ? projected.midX : (saving ? size.width * 0.25 : size.width * 0.5)
                let centerY = early || flow.phase == .lifting ? projected.midY : (saving ? 180 : size.height * (flow.phase == .revealing || presentedResult ? 0.33 : 0.46))
                ZStack {
                    if !early && flow.phase != .lifting {
                        SubjectEnergyView(data: result.imageData, start: flow.floatStart, result: flow.phase == .revealing || presentedResult, dotSpacing: size.width * 0.043)
                            .frame(width: 300, height: 320)
                    }
                    StickerArtwork(data: result.imageData, outlined: !early && flow.phase != .lifting)
                        .frame(width: artworkWidth, height: artworkHeight)
                        .background {
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear { sourceArtworkFrame = proxy.frame(in: .global) }
                                    .onChange(of: proxy.frame(in: .global)) { _, frame in
                                        if flow.phase != .saving { sourceArtworkFrame = frame }
                                    }
                            }
                        }
                        .overlay(alignment: .top) {
                            if presentedResult {
                                resultCaption(result, width: size.width)
                                    .offset(y: artworkHeight * 0.72)
                            }
                        }
                }
                .modifier(SubjectFloatModifier(active: flow.phase == .floating && flow.floatSettled && flow.recognitionFailure == nil, reduceMotion: reduceMotion, start: flow.floatStart))
                .position(x: centerX, y: centerY)
                .accessibilityIdentifier("recognitionResult")
            }
        }
    }

    private func resultCaption(_ result: RecognitionResult, width: CGFloat) -> some View {
        let name = result.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let meaning = result.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = name.isEmpty ? "为它命名" : name
        let subtitle = meaning.isEmpty ? "补充中文名称" : meaning
        let rounded = UIFont.systemFont(ofSize: 26, weight: .black).fontDescriptor.withDesign(.rounded)!
        let nameWidth = (title as NSString).size(withAttributes: [.font: UIFont(descriptor: rounded, size: 26)]).width
        let meaningWidth = (subtitle as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .bold)]).width
        let columnWidth = min(max(nameWidth, meaningWidth) + 2, width * 0.68)
        return VStack(spacing: 0) {
            Text(name.isEmpty ? "为它命名" : name)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .tracking(-0.7)
                .lineSpacing(-3)
                .accessibilityIdentifier("recognizedName")
            // 中文独立占行，不再与英文共用负间距，长词换行也不压缩中文。
            Text(meaning.isEmpty ? "补充中文名称" : meaning)
                .font(.system(size: 16, weight: .bold))
                .accessibilityIdentifier("recognizedMeaning")
        }
        .foregroundStyle(.black)
        .multilineTextAlignment(.center)
        .frame(width: columnWidth)
        .fixedSize(horizontal: false, vertical: true)
        .modifier(StickerTextOutline(width: 6))
        .contentShape(Rectangle())
        .onTapGesture { editing = true }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("轻点修改单词和中文名称")
        .overlay(alignment: .topTrailing) {
            if !name.isEmpty {
                Button { SpeechService.shared.speak(result.name, language: result.languageCode) } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Palette.stickerOrange)
                        .modifier(StickerTextOutline(width: 4))
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("朗读单词")
                .offset(x: 40, y: -4)
            }
        }
        .frame(width: width * 0.9)
    }

    private func subjectControls(size: CGSize, topInset: CGFloat) -> some View {
        let scale = min(size.width / 402, 1.15)
        return ZStack {
            captureUtility(symbol: "retake", label: "重新拍摄") { flow.reset() }
                .position(x: size.width * 0.19, y: size.height * 0.902 - topInset)
            RoundButton(symbol: "checkmark", label: "确认主体", size: 100 * scale, prominent: true,
                        symbolSize: 30 * scale) { flow.confirmSubject(reduceMotion: reduceMotion) }
                .accessibilityIdentifier("confirmSubjectButton")
                .position(x: size.width / 2, y: size.height * 0.902 - topInset)
            captureUtility(symbol: "crop", label: "裁剪") { cropping = true }
                .position(x: size.width * 0.81, y: size.height * 0.902 - topInset)
        }
    }

    private func resultControls(size: CGSize, topInset: CGFloat) -> some View {
        let scale = min(size.width / 402, 1.15)
        return ZStack {
            RoundButton(symbol: "retake", label: "重新拍摄", size: 60 * scale,
                        symbolSize: 24 * scale) { flow.reset() }
                .position(x: size.width * 0.226, y: size.height * 0.537 - topInset)
            RoundButton(symbol: "checkmark", label: "保存单词", size: 80 * scale, prominent: true,
                        symbolSize: 28 * scale, action: save)
                .accessibilityIdentifier("saveWordButton")
                .position(x: size.width / 2, y: size.height * 0.537 - topInset)
            RoundButton(symbol: "xmark", label: "放弃结果", size: 60 * scale, symbolSize: 24 * scale) { flow.reset() }
                .position(x: size.width * 0.774, y: size.height * 0.537 - topInset)
            Button { editing = true } label: {
                Label(flow.result?.needsNaming == true ? "填写单词和中文名称" : "和你知道的物品名称不一样？点击调整", systemImage: "pencil")
                    .font(.system(size: 13 * scale)).foregroundStyle(Palette.muted)
                    .frame(width: size.width * 0.75, height: 40 * scale)
                    .background(.gray.opacity(0.06), in: Capsule())
            }
            .accessibilityIdentifier("editResultButton")
            .contextMenu {
                Button("重新裁剪", systemImage: "crop") { cropping = true }
                Button("识别完整场景", systemImage: "photo") {
                    if let data = flow.original { flow.begin(data: data, language: language, scene: true, reduceMotion: reduceMotion) }
                }
            }
            .position(x: size.width / 2, y: size.height * 0.672 - topInset)
        }
    }

    private func shoot() {
        Haptics.tap()
        guard !shutterBusy else { return }
        shutterBusy = true
        cameraTask = Task {
            defer { shutterBusy = false }
            do {
                if demoMode {
                    guard let data = UIImage(named: "demo-camera")?.jpegData(compressionQuality: 0.95) else { throw RecognitionError.invalidImage }
                    flow.begin(data: data, language: language, demo: true, reduceMotion: reduceMotion)
                } else {
                    let data = try await camera.engine.capture(flash: camera.flash)
                    try Task.checkCancellation()
                    flow.begin(data: data, language: language, reduceMotion: reduceMotion)
                }
            } catch is CancellationError { }
            catch { flow.error = error.localizedDescription }
        }
    }

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    private func flyingSticker(result: RecognitionResult, size: CGSize) -> some View {
        let target = flight.targetFrame ?? .zero
        let flying = flight.isFlying
        let source = flightSourceFrame
        return StickerArtwork(data: result.imageData)
            .frame(width: flying ? target.width : source.width, height: flying ? target.height : source.height)
            .position(x: (flying ? target.midX : source.midX) - viewportOrigin.x,
                      y: (flying ? target.midY : source.midY) - viewportOrigin.y)
            .allowsHitTesting(false)
    }

    private func save() {
        guard saveTask == nil, flow.phase == .result, let result = flow.result else { return }
        guard !result.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !result.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { editing = true; return }
        let word = Word(name: result.name, meaning: result.meaning, pronunciation: result.pronunciation,
                        example: result.example, exampleMeaning: result.exampleMeaning, category: result.category,
                        languageCode: result.languageCode, imageData: result.imageData, isScene: result.isScene)
        context.insert(word)
        do { try context.save() }
        catch { context.rollback(); flow.error = error.localizedDescription; return }
        Haptics.success()
        flightSourceFrame = sourceArtworkFrame
        flight.targetFrame = nil
        flight.targetID = word.id
        flight.isFlying = false
        onSaved?(word)
        saveTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(250))
                // 等待 LazyVGrid 滚动并提交真实布局；超时直接交回列表，绝不使用猜测落点。
                for _ in 0..<60 {
                    if flight.targetFrame != nil { break }
                    try await Task.sleep(for: .milliseconds(16))
                }
                guard flight.targetFrame != nil, !reduceMotion else {
                    flight.targetID = nil; close(); return
                }
                flow.phase = .saving
                try await Task.sleep(for: .milliseconds(16))
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) { flight.isFlying = true }
                try await Task.sleep(for: .milliseconds(650))
                flight.targetID = nil
                flight.isFlying = false
                close()
            } catch { flight.targetID = nil; flight.isFlying = false }
        }
    }
}

private struct SubjectFloatModifier: ViewModifier {
    let active: Bool
    let reduceMotion: Bool
    let start: Date
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !active || reduceMotion)) { timeline in
            let time = max(0, timeline.date.timeIntervalSince(start))
            content.offset(y: active && !reduceMotion ? sin(time * .pi * 2 / 2.8) * 26 : 0)
        }
    }
}

struct FocusCorners: Shape {
    var cameraStyle = false
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let l = rect.width * (cameraStyle ? 0.11 : 0.23)
        let radius = cameraStyle ? l * 0.85 : 4
        for (x, y, dx, dy) in [(rect.minX, rect.minY, 1.0, 1.0), (rect.maxX, rect.minY, -1.0, 1.0),
                              (rect.minX, rect.maxY, 1.0, -1.0), (rect.maxX, rect.maxY, -1.0, -1.0)] {
            path.move(to: CGPoint(x: x + l * dx, y: y))
            path.addLine(to: CGPoint(x: x + radius * dx, y: y))
            path.addQuadCurve(to: CGPoint(x: x, y: y + radius * dy), control: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x, y: y + l * dy))
        }
        return path
    }
}
