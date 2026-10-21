import SwiftUI
import SwiftData
import PhotosUI

enum SettingsSheet: String, Identifiable {
    case profile, language, reminder, voice, widgets
    var id: String { rawValue }
    var detents: Set<PresentationDetent> {
        switch self {
        case .profile: [.height(360)]
        case .reminder: [.height(510)]
        case .language: [.fraction(0.83), .large]
        case .voice: [.fraction(0.78), .large]
        case .widgets: [.fraction(0.78), .large]
        }
    }
}

enum SettingsDestination: String, Hashable, CaseIterable, Identifiable {
    case health, faq, support, suggestions, about, weather, privacy, terms
    var id: String { rawValue }
}

enum SettingsAppInfo {
    static var name: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Wordrove" }
    static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0" }
    static var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1" }
    @MainActor static var diagnostics: String { "\(name) \(version) (\(build))\niOS \(UIDevice.current.systemVersion)\n\(UIDevice.current.model)" }
}

struct SettingsView: View {
    var embedded = false
    var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @AppStorage("profileNickname") private var nickname = "词语漫游者"
    @AppStorage("profileAvatarData") private var avatar = Data()
    @AppStorage("learningLanguage") private var language = LearningLanguage.english.rawValue
    @AppStorage("dailyReminderEnabled") private var reminderEnabled = false
    @AppStorage("isCloseFlashCardDailyReviewAlert") private var closeDailyReview = false
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]
    @State private var sheet: SettingsSheet?
    @State private var previewDestination: SettingsDestination?
    @State private var cacheBytes: Int64 = 0
    @State private var confirmClearCache = false
    @State private var notice: String?

    var body: some View {
        SettingsNavigationContainer(embedded: embedded) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 28) {
                        if embedded {
                            // Keep the expanded title's layout space while the visible
                            // title moves independently into the navigation bar.
                            Text("个人").font(.system(size: 32, weight: .regular))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 4).padding(.top, 16)
                                .hidden().accessibilityHidden(true)
                                .id("settings-top")
                        }
                        SettingsProfileHeader(nickname: nickname, avatar: avatar,
                                              language: LearningLanguage(rawValue: language) ?? .english,
                                              edit: { sheet = .profile }, chooseLanguage: { sheet = .language })
                        SettingsCardSection("学习设置") {
                            Button { sheet = .reminder } label: {
                                SettingsRow("学习提醒", symbol: "bell.fill",
                                            detail: reminderEnabled ? "开启" : "Off", chevron: false)
                            }.accessibilityIdentifier("studyReminderButton")
                            SettingsDivider()
                            Toggle(isOn: Binding(get: { !closeDailyReview }, set: { closeDailyReview = !$0; Haptics.tap() })) {
                                SettingsRowLabel("复习提醒", symbol: "rectangle.inset.filled")
                            }
                            .tint(.orange).padding(.horizontal, 24).frame(minHeight: 64)
                            .accessibilityIdentifier("reviewReminderToggle")
                            SettingsDivider()
                            Button { sheet = .voice } label: { SettingsRow("发音声音", symbol: "waveform") }
                                .accessibilityIdentifier("pronunciationVoiceButton")
                            SettingsDivider()
                            Button { sheet = .widgets } label: { SettingsRow("主屏幕小组件", symbol: "square.grid.2x2.fill") }
                                .accessibilityIdentifier("homeWidgetButton")
                        }.id("settings-learning")

                        SettingsCardSection("应用与账户") {
                            Menu {
                                ForEach(AppAppearance.allCases) { option in
                                    Button {
                                        appearance = option.rawValue
                                        Haptics.tap()
                                    } label: {
                                        Label(LocalizedStringKey(option.title),
                                              systemImage: AppAppearance(storedValue: appearance) == option ? "checkmark" : option.symbol)
                                    }.accessibilityIdentifier("appearance-\(option.rawValue)")
                                }
                            } label: {
                                SettingsRow("外观", symbol: "sun.max.fill",
                                            detail: AppAppearance(storedValue: appearance).title)
                            }
                            .accessibilityIdentifier("appearanceMenu")
                            .accessibilityValue("\(AppAppearance(storedValue: appearance).title)，当前为\(colorScheme == .dark ? "深色" : "浅色")外观")
                            SettingsDivider()
                            Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                                SettingsRow("界面语言", symbol: "globe", detail: SettingsInterfaceLanguage.currentTitle)
                            }.accessibilityIdentifier("interfaceLanguageButton")
                            SettingsDivider()
                            Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                                SettingsRow("订阅管理", symbol: "sparkles", detail: "管理")
                            }.accessibilityIdentifier("manageSubscriptionsButton")
                            SettingsDivider()
                            NavigationLink(value: SettingsDestination.health) {
                                SettingsRow("Apple 健康", symbol: "heart.fill", symbolColor: .pink)
                            }.accessibilityIdentifier("appleHealthButton")
                            SettingsDivider()
                            Button { confirmClearCache = true } label: {
                                SettingsRow("清理缓存", symbol: "eraser.fill",
                                            detail: ByteCountFormatter.string(fromByteCount: cacheBytes, countStyle: .file))
                            }.accessibilityIdentifier("clearCacheButton")
                            SettingsDivider()
                            NavigationLink { AIRecognitionSettingsView() } label: {
                                SettingsRow("AI 图片识别", symbol: "camera.fill")
                            }
                        }.id("settings-app")

                        SettingsCardSection("帮助与关于") {
                            NavigationLink(value: SettingsDestination.faq) { SettingsRow("FAQs", symbol: "bubble.left.fill") }
                            SettingsDivider()
                            NavigationLink(value: SettingsDestination.support) { SettingsRow("联系与支持", symbol: "envelope.fill") }
                            SettingsDivider()
                            NavigationLink(value: SettingsDestination.suggestions) { SettingsRow("功能建议", symbol: "sparkle") }
                            SettingsDivider()
                            NavigationLink(value: SettingsDestination.about) {
                                SettingsRow("关于 \(SettingsAppInfo.name)", symbol: "camera.aperture")
                            }
                            SettingsDivider()
                            NavigationLink(value: SettingsDestination.weather) {
                                SettingsRow("天气来源", symbol: "cloud.fill", detail: " Weather")
                            }
                            SettingsDivider()
                            NavigationLink(value: SettingsDestination.privacy) { SettingsRow("隐私政策", symbol: "lock.fill") }
                            SettingsDivider()
                            NavigationLink(value: SettingsDestination.terms) { SettingsRow("使用条款", symbol: "list.clipboard.fill") }
                        }.id("settings-help")
                        SettingsBrandFooter().padding(.top, 28)
                        Color.clear.frame(height: 112).id("settings-bottom")
                    }
                    .padding(.horizontal, 26)
                }
                .scrollIndicators(.hidden)
                .accessibilityIdentifier("settingsScroll")
                .modifier(SettingsNavigationTitleModifier(embedded: embedded, topInset: topInset))
                #if DEBUG
                .task {
                    guard LaunchOptions.arguments.contains("--uitesting") else { return }
                    do {
                        try await Task.sleep(for: .seconds(1))
                        let args = LaunchOptions.arguments
                        if args.contains("--preview-settings-general") || args.contains("--preview-theme-cycle") {
                            proxy.scrollTo("settings-app", anchor: .top)
                        }
                        if args.contains("--preview-settings-footer") { proxy.scrollTo("settings-bottom", anchor: .bottom) }
                        if args.contains("--preview-settings-help") { proxy.scrollTo("settings-help", anchor: .top) }
                        for preview in SettingsSheet.allPreviewCases where args.contains("--preview-settings-\(preview.rawValue)") {
                            sheet = preview
                        }
                        for destination in SettingsDestination.allCases where args.contains("--preview-settings-\(destination.rawValue)") {
                            previewDestination = destination
                        }
                        if args.contains("--preview-settings-title-motion") {
                            try await Task.sleep(for: .seconds(5))
                            withAnimation(.easeInOut(duration: 0.8)) { proxy.scrollTo("settings-app", anchor: .top) }
                            try await Task.sleep(for: .seconds(6))
                            withAnimation(.easeInOut(duration: 0.8)) { proxy.scrollTo("settings-top", anchor: .top) }
                        }
                        if args.contains("--preview-theme-cycle") {
                            for mode in [AppAppearance.dark, .light, .system] {
                                try await Task.sleep(for: .seconds(6))
                                appearance = mode.rawValue
                            }
                        }
                    } catch { }
                }
                #endif
            }
            .background(Palette.library.ignoresSafeArea())
            .foregroundStyle(Palette.ink)
            .buttonStyle(.plain)
            .navigationTitle(embedded ? "个人" : "设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(embedded ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                if !embedded { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
            }
            .navigationDestination(for: SettingsDestination.self) { destination in
                if destination == .health { SettingsHealthView() }
                else { SettingsInformationView(destination: destination) }
            }
            .navigationDestination(item: $previewDestination) { destination in
                if destination == .health { SettingsHealthView() }
                else { SettingsInformationView(destination: destination) }
            }
            .sheet(item: $sheet) { selected in
                Group {
                    switch selected {
                    case .profile: SettingsProfileEditor(nickname: $nickname, avatar: $avatar)
                    case .language: SettingsLanguageSheet()
                    case .reminder: SettingsReminderSheet()
                    case .voice: SettingsVoiceSheet()
                    case .widgets: SettingsWidgetGuide(word: words.first)
                    }
                }
                .presentationDetents(selected.detents)
                .presentationCornerRadius(36)
                .presentationDragIndicator(.hidden)
                .presentationBackground(Palette.library)
            }
            .confirmationDialog("清理缓存？", isPresented: $confirmClearCache, titleVisibility: .visible) {
                Button("清理缓存", role: .destructive) {
                    Task {
                        do {
                            URLCache.shared.removeAllCachedResponses()
                            try await Task.detached(priority: .utility) { try SettingsCacheStore.appCache.clear() }.value
                            cacheBytes = 0
                            notice = "缓存已清理。"
                            Haptics.success()
                        } catch { notice = error.localizedDescription }
                    }
                }
                Button("取消", role: .cancel) { }
            } message: { Text("已保存的单词、贴纸和个人资料会保留。") }
            .alert("提示", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("知道了", role: .cancel) { notice = nil }
            } message: { Text(notice ?? "") }
            .task { cacheBytes = (try? await Task.detached(priority: .utility) { try SettingsCacheStore.appCache.byteCount() }.value) ?? 0 }
        }
        .accessibilityIdentifier("settingsScreen")
    }
}

/// Observe only the short collapse range; scrolling the rest of the settings
/// does not invalidate the title or rebuild the settings sections.
private struct SettingsNavigationTitleModifier: ViewModifier {
    let embedded: Bool
    let topInset: CGFloat
    @State private var collapseOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                embedded ? min(max(geometry.contentOffset.y + geometry.contentInsets.top, 0), 56) : 0
            } action: { _, offset in
                collapseOffset = offset
            }
            .modifier(ScrollTopEdge(topInset: topInset, isEnabled: embedded))
            .overlay(alignment: .topLeading) {
                if embedded {
                    GeometryReader { geometry in
                        SettingsCollapsingTitle(progress: collapseOffset / 56, availableWidth: geometry.size.width)
                    }
                    .allowsHitTesting(false)
                }
            }
    }
}

private struct SettingsCollapsingTitle: View {
    let progress: CGFloat
    let availableWidth: CGFloat
    @State private var textSize = CGSize(width: 64, height: 39)

    var body: some View {
        let scale = 1 - progress * (15.0 / 32.0)
        let leading = 30 + ((availableWidth - textSize.width * scale) / 2 - 30) * progress
        let top = 16 + ((44 - textSize.height * scale) / 2 - 16) * progress
        Text("个人").font(.system(size: 32, weight: .regular)).foregroundStyle(Palette.ink)
            .fixedSize()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { textSize = $0 }
            .scaleEffect(scale, anchor: .topLeading)
            .offset(x: leading, y: top)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("profileNavigationTitle")
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

/// Embedded settings use the home navigation stack, so titles and pushed pages
/// participate in the same navigation hierarchy as the floating tab bar.
struct SettingsNavigationContainer<Content: View>: View {
    let embedded: Bool
    let content: Content
    init(embedded: Bool, @ViewBuilder content: () -> Content) {
        self.embedded = embedded
        self.content = content()
    }
    var body: some View {
        if embedded { content }
        else { NavigationStack { content } }
    }
}

extension SettingsSheet {
    static var allPreviewCases: [Self] { [.profile, .language, .reminder, .voice, .widgets] }
}

struct SettingsRowLabel: View {
    let title: LocalizedStringKey
    let symbol: String
    var symbolColor: Color = Palette.ink
    init(_ title: LocalizedStringKey, symbol: String, symbolColor: Color = Palette.ink) {
        self.title = title; self.symbol = symbol; self.symbolColor = symbolColor
    }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold)).foregroundStyle(symbolColor).frame(width: 20)
            Text(title).font(.system(size: 16)).foregroundStyle(Palette.ink)
        }
    }
}

struct SettingsRow: View {
    let title: LocalizedStringKey
    let symbol: String
    var detail: String?
    var chevron = true
    var symbolColor: Color = Palette.ink
    init(_ title: LocalizedStringKey, symbol: String, detail: String? = nil, chevron: Bool = true, symbolColor: Color = Palette.ink) {
        self.title = title; self.symbol = symbol; self.detail = detail; self.chevron = chevron; self.symbolColor = symbolColor
    }
    var body: some View {
        HStack(spacing: 10) {
            SettingsRowLabel(title, symbol: symbol, symbolColor: symbolColor)
            Spacer(minLength: 10)
            if let detail { Text(LocalizedStringKey(detail)).font(.system(size: 13)).foregroundStyle(.tertiary).lineLimit(1) }
            if chevron { Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(.quaternary) }
        }
        .frame(minHeight: 64).padding(.horizontal, 24).contentShape(Rectangle())
    }
}

struct SettingsDivider: View {
    var body: some View { Divider().overlay(Palette.separator.opacity(0.25)).opacity(0.30).padding(.horizontal, 24) }
}

struct SettingsCardSection<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content
    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary).padding(.leading, 24)
            VStack(spacing: 0) { content }
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

struct SettingsProfileHeader: View {
    let nickname: String
    let avatar: Data
    let language: LearningLanguage
    let edit: () -> Void
    let chooseLanguage: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            Button(action: edit) {
                VStack(spacing: 20) {
                    SettingsAvatar(data: avatar, size: 152)
                    Text(verbatim: nickname).font(.system(size: 20, weight: .semibold)).foregroundStyle(Palette.ink)
                }
            }.accessibilityIdentifier("editProfileButton").accessibilityLabel("编辑个人资料")
            Button(action: chooseLanguage) {
                HStack(spacing: 9) {
                    Text(verbatim: language.flag).font(.system(size: 18))
                    Text(LocalizedStringKey(language.title)).font(.system(size: 14)).foregroundStyle(.secondary)
                }
                .frame(minWidth: 120, minHeight: 46)
                .background(Palette.surface, in: Capsule())
            }.padding(.top, 28).accessibilityIdentifier("learningLanguageButton")
            Divider().padding(.horizontal, 14).padding(.top, 40)
        }
        .frame(maxWidth: .infinity).padding(.top, 42).padding(.bottom, 12)
    }
}

struct SettingsAvatar: View {
    let data: Data
    var size: CGFloat = 80
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(red: 0.49, green: 0.81, blue: 0.90), Color(red: 0.16, green: 0.61, blue: 0.80)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            if let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill().frame(width: size, height: size).clipShape(Circle())
            } else {
                Image(systemName: "person.fill").font(.system(size: size * 0.48, weight: .light)).foregroundStyle(.white.opacity(0.90))
            }
        }
        .frame(width: size, height: size).clipShape(Circle())
        .overlay(Circle().strokeBorder(.white, lineWidth: size > 100 ? 5 : 3))
    }
}

struct SettingsBrandFooter: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("launch-mark").resizable().scaledToFit().frame(width: 62, height: 62).opacity(0.85)
            Text("Made with ♥ from\n\(SettingsAppInfo.name)").font(.system(size: 11)).multilineTextAlignment(.center)
            Text("Version \(SettingsAppInfo.version) (\(SettingsAppInfo.build))").font(.system(size: 10))
            Text("Copyright © \(Calendar.current.component(.year, from: .now)) \(SettingsAppInfo.name)").font(.system(size: 10))
        }.foregroundStyle(.tertiary).frame(maxWidth: .infinity)
    }
}

private struct AIRecognitionSettingsView: View {
    @State private var baseURL = "https://api.deepseek.com"
    @State private var model = "deepseek-flash"
    @State private var apiKey = ""
    @State private var notice: String?

    var body: some View {
        Form {
            Section {
                TextField("接口地址", text: $baseURL).keyboardType(.URL)
                TextField("模型 ID", text: $model)
                SecureField("API Key", text: $apiKey)
            } header: {
                Text("识别服务")
            } footer: {
                Text("DeepSeek 官方当前通过 deepseek-flash 提供 V4.1-Flash-1017。该别名会随官方升级。密钥仅存储在本机钥匙串。")
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            Section {
                Button("保存配置") {
                    do {
                        try AIRecognitionSettings.save(.init(baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
                                                             model: model.trimmingCharacters(in: .whitespacesAndNewlines),
                                                             apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines)))
                        notice = "配置已保存，可返回拍摄页拍照或选择照片识别。"
                    } catch { notice = error.localizedDescription }
                }
                Button("移除 API Key", role: .destructive) {
                    do { try AIRecognitionSettings.removeKey(); apiKey = ""; notice = "API Key 已移除。" }
                    catch { notice = error.localizedDescription }
                }
            } footer: {
                Text("拍照及相册识别会上传经过方向校正和缩小的图片。请仅使用你信任的服务地址。")
            }
        }
        .scrollContentBackground(.hidden).background(Palette.paper)
        .navigationTitle("AI 图片识别")
        .task {
            do {
                let configuration = try AIRecognitionSettings.load()
                baseURL = configuration.baseURL; model = configuration.model; apiKey = configuration.apiKey
            } catch { notice = error.localizedDescription }
        }
        .alert("提示", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Button("知道了", role: .cancel) { notice = nil }
        } message: { Text(notice ?? "") }
    }
}
