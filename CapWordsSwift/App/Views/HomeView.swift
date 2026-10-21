import SwiftUI
import SwiftData

private enum HomeTab: String, CaseIterable {
    case capture = "拍摄", conversation = "对话", review = "复习", profile = "个人"

    var symbol: String {
        switch self {
        case .capture: "circle.lefthalf.filled"
        case .conversation: "waveform"
        case .review: "graduationcap"
        case .profile: "person.crop.rectangle"
        }
    }
}

struct HomeView: View {
    var preferences: UserDefaults = .standard
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]
    @State private var tab: HomeTab = .capture
    @State private var byCategory = false
    @State private var library = false
    @State private var startCamera = false
    @State private var error: String?
    @State private var now = Date.now
    @State private var prepared = false
    @Namespace private var cardTransition
    @State private var transitionSource: String?
    @State private var initialDay: Date?
    @State private var initialCategory: String?
    @State private var showsOnboarding = false
    @State private var pendingReview: [Word] = []
    @State private var dailyReview = false
    @State private var captureAfterReview = false
    @State private var didPresentStartupReview = false
    @State private var launch = LaunchCoordinator(skipAnimation: LaunchOptions.skipAnimation)

    private let homeBackground = Palette.home
    private let cardColors: [Color] = [
        Color(red: 0.60, green: 0.50, blue: 0.56), Color(red: 0.49, green: 0.59, blue: 0.68),
        Color(red: 0.62, green: 0.59, blue: 0.70), Color(red: 0.72, green: 0.64, blue: 0.46),
        Color(red: 0.68, green: 0.72, blue: 0.48), Color(red: 0.86, green: 0.64, blue: 0.62)
    ]
    private var days: [Date] {
        HomePresentation.dateDays(from: words.map(\.createdAt), now: now)
    }
    private var categories: [String] {
        let known = ["食物饮品", "人物家庭", "身体健康", "动物自然", "家居家具", "学校学习"]
        return known + Set(words.map { displayCategory($0.category) }).subtracting(known).sorted()
    }
    private var headerMessage: String {
        HomePresentation.headerMessage(wordCount: words.count, hasWordsInFirstDay: days.first.map { first in
            words.contains { Calendar.current.isDate($0.createdAt, inSameDayAs: first) }
        } ?? false)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { screen in
                // 浮动底栏距屏幕底边 21pt；SwiftUI 的窗口安全区可能更高。
                let tabBarBottomInset = min(screen.safeAreaInsets.bottom, 21)
                TabView(selection: $tab) {
                    Tab("拍摄", systemImage: "circle.lefthalf.filled", value: HomeTab.capture) {
                        collection.background(homeBackground)
                            .modifier(ScrollTopEdge(topInset: screen.safeAreaInsets.top))
                            .overlay(alignment: .topTrailing) {
                                displayMenu.padding(.trailing, 18).padding(.top, 8)
                            }
                            .toolbar(.hidden, for: .tabBar)
                    }
                    Tab("对话", systemImage: "waveform", value: HomeTab.conversation) {
                        conversation.background(Palette.home)
                            .toolbar(.hidden, for: .tabBar)
                    }
                    Tab("复习", systemImage: "graduationcap", value: HomeTab.review) {
                        ReviewHomeView(words: words)
                            .toolbar(.hidden, for: .tabBar)
                    }
                    Tab("个人", systemImage: "person.crop.rectangle", value: HomeTab.profile) {
                        SettingsView(embedded: true, topInset: screen.safeAreaInsets.top)
                            .toolbar(.hidden, for: .tabBar)
                    }
                }
                // 仅收窄原生底栏容器，玻璃、选中态和触摸交互仍由系统管理。
                .toolbar(.hidden, for: .tabBar)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    GeometryReader { geometry in
                        HomeNativeTabBar(selection: $tab)
                            .frame(width: min(geometry.size.width, geometry.size.width * (446.0 / 602.0) + 42),
                                   height: 62 + tabBarBottomInset)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 62)
                    .padding(.bottom, tabBarBottomInset - screen.safeAreaInsets.bottom)
                }
                .tint(Palette.orange)
                .onChange(of: tab) { _, _ in Haptics.tap() }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $library) {
                    libraryDestination
                }
                .fullScreenCover(isPresented: $dailyReview, onDismiss: {
                    if captureAfterReview {
                        captureAfterReview = false
                        openLibrary(camera: true)
                    }
                }) {
                    DailyReviewPromptView(words: pendingReview) {
                        captureAfterReview = true
                        dailyReview = false
                    }
                        .onAppear { markReviewShown() }
                }
                .task { prepareStartup() }

                .onChange(of: launch.isVisible) { _, visible in if !visible { presentStartupReview() } }
                .onChange(of: scenePhase) { _, phase in if phase == .active { now = .now } }
                .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { now = $0 }
                .alert("词库暂时无法保存", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("知道了", role: .cancel) { error = nil }
                } message: { Text(error ?? "") }
            }
        }
        #if DEBUG
        .task {
            guard LaunchOptions.arguments.contains("--uitesting"),
                  LaunchOptions.arguments.contains("--preview-home-motion") else { return }
            do {
                try await Task.sleep(for: .seconds(9))
                guard let day = days.first else { return }
                withAnimation { openLibrary(day: day, source: daySource(day)) }
                try await Task.sleep(for: .seconds(8))
                withAnimation { library = false }
            } catch { /* Stop replay when HomeView is removed. */ }
        }
        #endif
        .overlay {
            if launch.needsFirstFrameCover { LaunchFirstFrame() }
        }
        .background { LaunchWindowBridge(coordinator: launch).frame(width: 0, height: 0) }
        .onChange(of: words.count, initial: true) { _, _ in WordWidgetBridge.publish(words: words) }
        .onChange(of: words.first?.name) { _, _ in WordWidgetBridge.publish(words: words) }
        .onChange(of: words.first?.meaning) { _, _ in WordWidgetBridge.publish(words: words) }
        .onChange(of: words.first?.imageData) { _, _ in WordWidgetBridge.publish(words: words) }
        .onOpenURL { url in
            guard url.scheme == "wordrove", url.host == "library" else { return }
            dailyReview = false
            didPresentStartupReview = true
            openLibrary()
        }
        .allowsHitTesting(!launch.isVisible)
        .accessibilityHidden(launch.isVisible)
    }

    @ViewBuilder
    private var libraryDestination: some View {
        if let transitionSource, !reduceMotion {
            libraryContent.navigationTransition(.zoom(sourceID: transitionSource, in: cardTransition))
        } else {
            libraryContent
        }
    }

    private var libraryContent: some View {
        ZStack {
            LibraryView(startsInCamera: startCamera, initiallyByCategory: byCategory,
                        initialDay: initialDay, initialCategory: initialCategory,
                        onReady: { launch.contentReady = true }, onReviewShown: markReviewShown)
                .accessibilityHidden(showsOnboarding)
            if showsOnboarding {
                IntroView {
                    preferences.set(true, forKey: "hasShownOnboarding")
                    preferences.set(true, forKey: "completeOnboarding")
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { showsOnboarding = false }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var collection: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 0) {
                Color.clear.frame(height: 52).id("home-top")

                VStack(spacing: 9) {
                    Text(chineseDate(now))
                        .font(.system(size: 14, design: .serif)).foregroundStyle(.secondary)
                    Text(HomePresentation.greeting(at: now)).font(.system(size: 31, weight: .regular)).foregroundStyle(Palette.ink)
                        .accessibilityIdentifier("homeGreeting")
                    Text(headerMessage)
                        .font(.system(size: 18)).foregroundStyle(Palette.muted)
                        .accessibilityIdentifier("homeWordSummary")
                }.padding(.top, 18)

                ShutterButton(action: { openLibrary(camera: true) }, size: 202)
                    .padding(24)
                    .overlay(Circle().stroke(Palette.ink.opacity(0.10), style: StrokeStyle(lineWidth: 3, dash: [3, 13])))
                    .padding(.vertical, 58)

                if byCategory {
                    Text("分类").font(.system(size: 22)).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24).padding(.bottom, 18)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                            snapshot(title: category, items: words.filter { displayCategory($0.category) == category },
                                     color: cardColors[(index + 1) % cardColors.count], compact: true) {
                                openLibrary(category: category)
                            }
                        }
                    }.padding(.horizontal, 20)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(days.enumerated()), id: \.element) { index, day in
                            if index == 0 || !Calendar.current.isDate(day, equalTo: days[index - 1], toGranularity: .month) {
                                Text(day.formatted(.dateTime.month(.wide).locale(Locale(identifier: "zh_CN"))))
                                    .font(.system(size: 23)).frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 20).padding(.top, index == 0 ? 0 : 14).padding(.bottom, 4)
                            }
                            snapshot(title: cardDate(day),
                                     items: words.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: day) },
                                     color: cardColors[index % cardColors.count], compact: false) {
                                openLibrary(day: day, source: daySource(day))
                            }
                            .id(daySource(day))
                            .matchedTransitionSource(id: daySource(day), in: cardTransition) { source in
                                source.background(cardColors[index % cardColors.count])
                                    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                            }
                        }
                    }.padding(.horizontal, 20)
                }
                // 为浮动底栏和卡片下方间距预留滚动空间。
                Color.clear.frame(height: 112).id("home-bottom")
            }
        }.scrollIndicators(.hidden)
            .accessibilityIdentifier("homeCollectionScroll")
            .onChange(of: byCategory) { _, _ in proxy.scrollTo("home-top", anchor: .top) }
            #if DEBUG
            .task(id: words.count) {
                // Visual replay only: UI tests separately exercise real taps.
                guard LaunchOptions.arguments.contains("--uitesting"),
                      LaunchOptions.arguments.contains("--preview-home-dates") ||
                      LaunchOptions.arguments.contains("--preview-home-bottom") else { return }
                do {
                    try await Task.sleep(for: .seconds(2))
                    if LaunchOptions.arguments.contains("--preview-home-bottom") {
                        proxy.scrollTo("home-bottom", anchor: .bottom)
                        // LazyVStack 实现底部行后，再按实际内容高度定位。
                        try await Task.sleep(for: .milliseconds(500))
                        proxy.scrollTo("home-bottom", anchor: .bottom)
                    } else if let day = days.first {
                        proxy.scrollTo(daySource(day), anchor: .top)
                    }

                } catch { /* Cancel replay when the view disappears. */ }
            }
            #endif
        }
    }

    private var displayMenu: some View {
        Menu {
            Button { changeGrouping(false) } label: {
                Label("按日期展示", systemImage: byCategory ? "calendar" : "checkmark")
            }
            Button { changeGrouping(true) } label: {
                Label("按分类展示", systemImage: byCategory ? "checkmark" : "square.grid.2x2")
            }
            Button("全部单词", systemImage: "rectangle.stack") { openLibrary() }
        } label: {
            Image(systemName: byCategory ? "square.grid.2x2" : "rectangle.split.3x1")
                .rotationEffect(.degrees(byCategory ? 0 : 90))
                .font(.system(size: 20, weight: .regular)).foregroundStyle(Palette.ink)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Palette.separator, lineWidth: 1))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        }.accessibilityLabel("词库展示方式").accessibilityIdentifier("libraryDisplayMenu")
    }

    private func snapshot(title: String, items: [Word], color: Color, compact: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: compact ? 17 : 28, design: compact ? .default : .serif))
                Text("\(items.count)个单词").font(.system(size: compact ? 12 : 16)).opacity(0.7)
                Spacer(minLength: 10)
                if items.isEmpty && !compact {
                    Text(HomePresentation.emptyCardMessage)
                        .font(.system(size: 14)).lineSpacing(4).opacity(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 14)
                } else {
                    HStack(spacing: compact ? 5 : 12) {
                        ForEach(0..<(compact ? 2 : 4), id: \.self) { index in
                            Group {
                                if index < items.count {
                                    StickerArtwork(data: items[index].imageData, asset: items[index].assetName)
                                } else { Color.clear }
                            }
                            .frame(maxWidth: .infinity).frame(height: compact ? 62 : 66)
                        }
                    }
                    .padding(.bottom, compact ? 0 : 5)
                }
            }.padding(compact ? 15 : 24)
                .frame(maxWidth: .infinity, alignment: .leading).frame(height: compact ? 184 : 194)
                .background(color, in: RoundedRectangle(cornerRadius: compact ? 26 : 44, style: .continuous))
                .foregroundStyle(Palette.cardInk)
        }.buttonStyle(.plain).accessibilityLabel("\(title)，\(items.count)个单词")
            .accessibilityIdentifier("snapshot-\(title)")
    }

    // 当前可用的本地词卡例句练习；未接入云端对话服务。
    private var conversation: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("对话").font(.system(size: 30, weight: .medium))
                Text("从身边的单词，开始一句对话。")
                    .font(.system(size: 15)).foregroundStyle(.secondary)
                if words.isEmpty {
                    ContentUnavailableView("先拍下一个单词", systemImage: "waveform", description: Text("收集词卡后，在这里练习发音和例句。"))
                }
                ForEach(words.filter { !$0.example.isEmpty }) { word in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            StickerArtwork(data: word.imageData, asset: word.assetName).frame(width: 52, height: 52)
                            Text(word.name).font(.system(size: 20, weight: .semibold, design: .rounded))
                            Spacer()
                            Button { SpeechService.shared.speak(word.example, language: word.languageCode) } label: {
                                Image(systemName: "speaker.wave.2").frame(width: 44, height: 44)
                            }.accessibilityLabel("朗读\(word.name)的例句")
                        }
                        Text(word.example).font(.system(size: 17))
                        Text(word.exampleMeaning).font(.system(size: 14)).foregroundStyle(.secondary)
                    }.padding(18).background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
                }
            }.padding(24)
        }.onDisappear { SpeechService.shared.stop() }
    }

    private func changeGrouping(_ value: Bool) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { byCategory = value }
    }
    private func chineseDate(_ date: Date) -> String {
        let calendar = Calendar.current
        return "\(calendar.component(.month, from: date))月\(calendar.component(.day, from: date))日"
    }
    private func displayCategory(_ category: String) -> String {
        switch category {
        case "食物": "食物饮品"
        case "自然", "动物": "动物自然"
        default: category
        }
    }
    private func cardDate(_ date: Date) -> String {
        let calendar = Calendar.current
        return "\(calendar.component(.month, from: date))月\(calendar.component(.day, from: date))"
    }
    private func daySource(_ date: Date) -> String {
        "day-\(Calendar.current.startOfDay(for: date).timeIntervalSinceReferenceDate)"
    }
    private func openLibrary(camera: Bool = false, day: Date? = nil, category: String? = nil, source: String? = nil) {
        transitionSource = source
        startCamera = camera
        initialDay = day
        initialCategory = category
        library = true
    }

    private func prepareStartup() {
        guard !prepared else { return }
        prepared = true
        do {
            #if DEBUG
            if LaunchOptions.arguments.contains("--seed-library-history") {
                try SeedLibrary.insert(into: context, daysAgoOffset: 1)
            } else if LaunchOptions.arguments.contains("--seed-library") {
                try SeedLibrary.insert(into: context)
            }
            if LaunchOptions.arguments.contains("--uitesting"), LaunchOptions.arguments.contains("--single-today") {
                let samples = try context.fetch(FetchDescriptor<Word>())
                for word in samples where word.assetName != "sample-monstera" && Calendar.current.isDateInToday(word.createdAt) {
                    word.createdAt = Calendar.current.date(byAdding: .day, value: -1, to: word.createdAt)!
                }
                try context.save()
            }
            #endif
            let storedWords = try context.fetch(FetchDescriptor<Word>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            // 用快照读取完成时的时间判断到期，不能沿用 View 构造时的旧时间。
            // 否则启动准备期间新增/导入的当天词条会被错误排除。
            now = .now
            let storedFlag = preferences.object(forKey: "hasShownOnboarding") as? Bool
            var onboarded = StartupPolicy.hasCompletedOnboarding(stored: storedFlag,
                legacyHasLaunched: preferences.bool(forKey: "hasLaunched"), existingWordCount: storedWords.count)
            #if DEBUG
            if LaunchOptions.arguments.contains("--force-onboarding") { onboarded = false }
            if LaunchOptions.arguments.contains("--onboarding-complete") { onboarded = true }
            if LaunchOptions.arguments.contains("--reviewed-today") { preferences.set(now, forKey: "flashcardPreviewDate") }
            if LaunchOptions.arguments.contains("--disable-daily-review") { preferences.set(true, forKey: "isCloseFlashCardDailyReviewAlert") }
            #endif
            if onboarded { preferences.set(true, forKey: "hasShownOnboarding") }
            let due = ReviewQueue.make(words: storedWords, newLimit: preferences.integer(forKey: "flashcardCount") == 0 ? 5 : preferences.integer(forKey: "flashcardCount"), now: now)
            let route = StartupPolicy.route(hasShownOnboarding: onboarded, wordCount: storedWords.count,
                dueWordCount: due.count, lastReviewDate: preferences.object(forKey: "flashcardPreviewDate") as? Date,
                reviewReminderDisabled: preferences.bool(forKey: "isCloseFlashCardDailyReviewAlert"), now: now)
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                #if DEBUG
                if LaunchOptions.previewsHome {
                    byCategory = LaunchOptions.arguments.contains("--preview-home-category")
                    if LaunchOptions.arguments.contains("--preview-settings") { tab = .profile }
                    if LaunchOptions.arguments.contains("--preview-conversation") { tab = .conversation }
                    if LaunchOptions.arguments.contains("--preview-home-review") { tab = .review }
                    launch.contentReady = true
                    return
                }
                if LaunchOptions.previewsLibrary {
                    library = true
                    return
                }
                #endif
                switch route {
                case .onboarding:
                    showsOnboarding = true
                    library = true
                case .library:
                    library = true
                case .dailyReview:
                    pendingReview = due
                    launch.contentReady = true
                }
            }
            presentStartupReview()
        } catch {
            self.error = error.localizedDescription
            launch.contentReady = true // 出错仍退场并展示可恢复错误，不滞留在开屏。
        }
    }

    private func presentStartupReview() {
        guard !launch.isVisible, !pendingReview.isEmpty, !didPresentStartupReview else { return }
        didPresentStartupReview = true
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { dailyReview = true }
    }

    private func markReviewShown() { preferences.set(Date.now, forKey: "flashcardPreviewDate") }
}

struct ScrollTopEdge: ViewModifier {
    let topInset: CGFloat
    var isEnabled = true

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Palette.home.mask {
                        LinearGradient(stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.30),
                            .init(color: .clear, location: 0.68)
                        ], startPoint: .top, endPoint: .bottom)
                    }
                }
                .mask {
                    LinearGradient(stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.50),
                        .init(color: .black.opacity(0.72), location: 0.72),
                        .init(color: .clear, location: 1)
                    ], startPoint: .top, endPoint: .bottom)
                }
                .frame(height: topInset + 48)
                .offset(y: -topInset)
                .opacity(isEnabled ? 1 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// 参考图底栏可见宽度为屏宽的 446 / 602；内容页面仍占满整个窗口。
private struct HomeNativeTabBar: UIViewRepresentable {
    @Binding var selection: HomeTab

    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection) }

    func makeUIView(context: Context) -> UITabBar {
        let bar = UITabBar()
        bar.delegate = context.coordinator
        bar.items = HomeTab.allCases.enumerated().map { index, tab in
            UITabBarItem(title: NSLocalizedString(tab.rawValue, comment: "Main tab label"), image: UIImage(systemName: tab.symbol), tag: index)
        }
        bar.accessibilityIdentifier = "homeTabBar"
        return bar
    }

    func updateUIView(_ bar: UITabBar, context: Context) {
        context.coordinator.selection = $selection
        bar.tintColor = UIColor(Palette.orange)
        if let index = HomeTab.allCases.firstIndex(of: selection) {
            bar.selectedItem = bar.items?[index]
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITabBar, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 340, height: proposal.height ?? 62)
    }

    final class Coordinator: NSObject, UITabBarDelegate {
        var selection: Binding<HomeTab>
        init(selection: Binding<HomeTab>) { self.selection = selection }

        func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            guard HomeTab.allCases.indices.contains(item.tag) else { return }
            selection.wrappedValue = HomeTab.allCases[item.tag]
        }
    }
}

enum LaunchOptions {
    static var arguments: [String] {
        #if DEBUG
        ProcessInfo.processInfo.arguments
        #else
        []
        #endif
    }
    static var previewsHome: Bool {
        arguments.contains { ["--preview-home", "--preview-home-category", "--preview-settings",
                              "--preview-conversation", "--preview-home-review"].contains($0) }
    }
    static var previewsLibrary: Bool {
        arguments.contains { ["--preview-library", "--preview-camera", "--preview-result", "--preview-dust",
                              "--preview-floating", "--preview-detail", "--preview-category", "--preview-review"].contains($0) }
    }
    static var skipAnimation: Bool {
        !arguments.contains("--exercise-startup") && (previewsHome || previewsLibrary || arguments.contains("--uitesting"))
    }
}
