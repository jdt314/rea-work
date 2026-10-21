import SwiftUI
import SwiftData

struct LibraryView: View {
    var startsInCamera = false
    var initiallyByCategory = false
    var initialDay: Date? = nil
    var initialCategory: String? = nil
    var onReady: () -> Void = {}
    var onReviewShown: () -> Void = {}
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]
    @State private var didInitialize = false
    @State private var didScrollToInitialGroup = false
    @State private var laidOutGroupIDs: Set<String> = []
    @State private var activeGroupID: String?
    @State private var headerOffsets: [String: Double] = [:]
    @State private var groupHeights: [String: CGFloat] = [:]
    @State private var scrollOffset = 0.0
    @State private var userScrollStarted = false
    @State private var didFirePageHaptic = false
    @State private var emptyCoverReleased = false
    @State private var isFlippingCover = false
    @State private var pendingCoverReturn = false
    @State private var gestureStartScrollOffset = 0.0
    @State private var gestureStartedOnEmptyPage = true
    @State private var capture = false
    @State private var cameraReveal = 0.0
    @State private var cameraPulling = false
    @State private var cameraTransitioning = false
    @State private var cameraClosing = false
    @State private var cameraMode = true
    @State private var captureSavedWord = false
    @State private var cameraGestureStart: Double?
    @State private var screenHeight = 1.0
    @GestureState private var verticalGestureActive = false
    @State private var flight = StickerFlightState()
    @State private var savedWordID: UUID?
    @State private var settings = false
    @State private var review = false
    @State private var search = ""
    @State private var searching = false
    @State private var byCategory = false
    @State private var selected: Word?
    @State private var error: String?

    private var filtered: [Word] {
        guard !search.isEmpty else { return words }
        return words.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.meaning.localizedCaseInsensitiveContains(search) }
    }
    private struct WordGroup: Identifiable {
        let id: String
        let title: String
        let words: [Word]
        let date: Date?
    }

    private let knownCategories = ["食物饮品", "人物家庭", "身体健康", "动物自然", "家居家具", "学校学习"]

    private var groups: [WordGroup] {
        if byCategory {
            let grouped = Dictionary(grouping: filtered) { displayCategory($0.category) }
            let categories = search.isEmpty
                ? knownCategories + grouped.keys.filter { !knownCategories.contains($0) }.sorted()
                : grouped.keys.sorted()
            return categories.map {
                WordGroup(id: categoryGroupID($0), title: $0,
                          words: (grouped[$0] ?? []).sorted { $0.createdAt > $1.createdAt }, date: nil)
            }
        }
        let grouped = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.createdAt) }
        let dates = search.isEmpty ? HomePresentation.dateDays(from: filtered.map(\.createdAt)) : grouped.keys.sorted(by: >)
        return dates.map {
            WordGroup(id: dateGroupID($0), title: dateTitle($0),
                      words: (grouped[$0] ?? []).sorted { $0.createdAt > $1.createdAt }, date: $0)
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { screen in
                let fullHeight = screen.size.height + screen.safeAreaInsets.top + screen.safeAreaInsets.bottom
                let chrome = min(1, cameraReveal * 4)
                ZStack(alignment: .top) {
                    Color.black.ignoresSafeArea()
                    if capture {
                        CaptureView(onSaved: { word in
                            search = ""
                            searching = false
                            byCategory = false
                            savedWordID = word.id
                            captureSavedWord = true
                            // Reveal the destination before CaptureView measures its save flight.
                            cameraReveal = 0
                        }, onClose: closeCamera,
                           usesLibraryPresentation: true, cameraReveal: cameraClosing ? 0 : min(1, cameraReveal * 2),
                           cameraVisible: !cameraClosing,
                           showsCameraGuides: !cameraPulling && !cameraTransitioning && !cameraClosing,
                           onCameraModeChanged: { cameraMode = $0 })
                        .environment(flight)
                        .allowsHitTesting(!cameraPulling && !cameraTransitioning)
                        .accessibilityHidden(cameraPulling || cameraTransitioning)
                        .zIndex(cameraMode ? 0 : 3)
                    }
                    VStack(spacing: 0) {
                        header.hidden()
                        if searching { searchBar }
                        GeometryReader { viewport in
                            timeline(viewportHeight: viewport.size.height)
                        }
                    }
                    .padding(.top, screen.safeAreaInsets.top)
                    .padding(.bottom, screen.safeAreaInsets.bottom)
                    .frame(width: screen.size.width, height: fullHeight)
                    .background {
                        if colorScheme == .dark { libraryPaper.ignoresSafeArea() }
                        else { PaperBackground(color: libraryPaper) }
                    }
                    // Resolve the sheet's geometry together so lazy cell content
                    // follows the container rather than interpolating independently.
                    .geometryGroup()
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 48 * min(1, cameraReveal * 8),
                                                     topTrailingRadius: 48 * min(1, cameraReveal * 8)))
                    .offset(y: cameraReveal * fullHeight - screen.safeAreaInsets.top)
                    // Keep the sheet's safe-area bleed from enlarging the ZStack proposal.
                    .frame(height: screen.size.height, alignment: .top)
                    .accessibilityHidden(capture)
                    .allowsHitTesting(!capture || cameraPulling)

                    VStack(spacing: 0) {
                        header.opacity(1 - chrome)
                        if searching { searchBar.hidden() }
                        if !byCategory, let group = pinnedGroup, let date = group.date {
                            LibraryDateHeading(date: date, count: group.words.count, animated: true,
                                               foreground: colorScheme == .dark ? .white : Color(white: chrome), countOpacity: 1 - chrome)
                                .offset(y: -24 * chrome)
                                .padding(.horizontal, 24)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 12)
                               .background {
                                    LinearGradient(stops: [.init(color: libraryPaper.opacity(1 - chrome), location: 0),
                                                          .init(color: libraryPaper.opacity(1 - chrome), location: 0.85),
                                                          .init(color: libraryPaper.opacity(0), location: 1)],
                                                   startPoint: .top, endPoint: .bottom)
                                    .opacity(capture ? 0 : 1)
                                    .transaction { $0.animation = nil }
                                }
                                .allowsHitTesting(false)
                        }
                        Spacer(minLength: 0)
                    }
                    .opacity(!capture || cameraMode || captureSavedWord ? 1 : 0)
                    .allowsHitTesting(!capture)
                    bottomBar
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .allowsHitTesting(!capture)
                        .accessibilityHidden(capture)
                }
                .frame(width: screen.size.width, height: screen.size.height)
                .onAppear { screenHeight = fullHeight }
                .onChange(of: fullHeight) { _, height in screenHeight = height }
            }
            .environment(flight)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $settings) { SettingsView() }
            .sheet(isPresented: $review) {
                ReviewHomeView(words: words)
                    .onAppear { if words.contains(where: { $0.nextReviewAt <= .now }) { onReviewShown() } }
            }
            .sheet(item: $selected) { word in WordDetailView(word: word) }
            .alert("词库暂时无法保存", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("知道了", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
        }
        .preference(key: CameraAppearancePreferenceKey.self, value: capture && cameraMode && !cameraClosing)
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 20, weight: .medium))
                    .foregroundStyle(libraryInk).frame(width: 44, height: 44)
            }.accessibilityLabel("返回主页")
            Spacer()
            if byCategory {
                Menu {
                    Button { byCategory = false } label: { Label("按日期查看", systemImage: "calendar") }
                    Button { byCategory = true } label: { Label("按分类查看", systemImage: "square.grid.2x2") }
                    Button { searching = true } label: { Label("搜索单词", systemImage: "magnifyingglass") }
                    Button { review = true } label: { Label("复习单词", systemImage: "rectangle.on.rectangle.angled") }
                    Button { settings = true } label: { Label("设置", systemImage: "gearshape") }
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--uitesting") {
                        Button("试试示例词库") {
                            do { try SeedLibrary.insert(into: context) } catch { self.error = error.localizedDescription }
                        }.accessibilityIdentifier("loadSamplesButton")
                    }
                    #endif
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 20, weight: .medium))
                        .foregroundStyle(libraryInk).frame(width: 44, height: 44)
                }.accessibilityLabel("词库菜单")
            }
        }.padding(.horizontal, 12).padding(.bottom, 4)
    }

    private var libraryPaper: Color { Palette.library }
    private var libraryInk: Color { Palette.ink }

    private var fullScreenEmptyID: String? {
        guard !byCategory, !searching, search.isEmpty,
              let first = groups.first, first.words.isEmpty else { return nil }
        return first.id
    }

    private var pinnedGroup: WordGroup? {
        groups.first { $0.id == activeGroupID } ?? groups.first
    }

    private var holdsEmptyCover: Bool {
        fullScreenEmptyID != nil && !emptyCoverReleased
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("搜索你的单词", text: $search).accessibilityIdentifier("wordSearch")
            Button { search = ""; searching = false } label: { Image(systemName: "xmark.circle.fill") }
        }
        .foregroundStyle(.secondary).padding(14).background(Palette.surface, in: Capsule())
        .padding(.horizontal, 24).padding(.bottom, 16)
    }

    private func timeline(viewportHeight: CGFloat) -> some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if filtered.isEmpty && !search.isEmpty {
                        ContentUnavailableView.search(text: search).padding(.top, 120)
                    } else {
                        ForEach(groups) { group in
                            groupContent(group, viewportHeight: viewportHeight)
                                .id(group.id)
                               .background {
                                    GeometryReader { geometry in
                                        Color.clear.preference(key: LibraryGroupFramesKey.self,
                                            value: [group.id: geometry.frame(in: .named("libraryTimeline"))])
                                    }
                                }
                        }
                    }
                }
                .padding(.bottom, bottomScrollSpace(viewportHeight: viewportHeight))
            }
            .coordinateSpace(name: "libraryTimeline")
            .accessibilityIdentifier("libraryTimeline")
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .scrollDisabled(holdsEmptyCover || isFlippingCover || cameraTransitioning || (capture && !cameraPulling))
            .simultaneousGesture(coverGesture(using: scrollProxy, viewportHeight: viewportHeight))
            .onChange(of: verticalGestureActive) { _, active in
                guard !active else { return }
                // GestureState may reset before onEnded is delivered. Let the normal
                // commit callback run first, then handle recognizer cancellation.
                Task { @MainActor in
                    await Task.yield()
                    guard !verticalGestureActive else { return }
                    cameraGestureStart = nil
                    if cameraPulling { closeCamera() }
                }
            }
            .onChange(of: pendingCoverReturn) { _, pending in
                guard pending else { return }
                pendingCoverReturn = false
                flipEmptyCover(showing: true, using: scrollProxy)
            }
            .scrollTargetBehavior(LibraryScrollBehavior(
                emptyPageHeight: fullScreenEmptyID != nil && groups.count > 1 ? viewportHeight : nil,
                onPageSnap: { endsOnEmptyPage in
                    guard userScrollStarted, !didFirePageHaptic, !isFlippingCover,
                          gestureStartedOnEmptyPage != endsOnEmptyPage else { return }
                    didFirePageHaptic = true
                    if endsOnEmptyPage {
                        // A fling reaching the boundary uses the same one-page return animation.
                        userScrollStarted = false
                        pendingCoverReturn = true
                    } else {
                        Haptics.tap()
                    }
                }))
            .onScrollGeometryChange(for: Double.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, offset in
                scrollOffset = offset
                if cameraPulling, abs(offset) > 0.5, let first = groups.first {
                    // Prevent the inner list's rubber band from adding a second translation.
                    scrollProxy.scrollTo(first.id, anchor: .top)
                }
                if !isFlippingCover {
                    if offset > 1 { emptyCoverReleased = true }
                    else if !userScrollStarted { emptyCoverReleased = false }
                }
            }
            .onScrollPhaseChange { _, phase in
                if phase == .tracking {
                    userScrollStarted = true
                    didFirePageHaptic = false
                    gestureStartScrollOffset = scrollOffset
                    gestureStartedOnEmptyPage = scrollOffset < viewportHeight / 2
                }
                if phase == .idle {
                    if userScrollStarted, !didFirePageHaptic, fullScreenEmptyID != nil, groups.count > 1,
                       gestureStartedOnEmptyPage != (scrollOffset < viewportHeight / 2) {
                        Haptics.tap()
                    }
                    userScrollStarted = false
                    if scrollOffset <= 1, !isFlippingCover { emptyCoverReleased = false }
                }
            }
            .onPreferenceChange(LibraryGroupFramesKey.self) { frames in
                let offsets = frames.mapValues { Double($0.minY) }
                headerOffsets = offsets
                groupHeights = frames.mapValues(\.height)
                activeGroupID = LibraryScrollPolicy.activeGroupID(orderedIDs: groups.map(\.id), headerOffsets: offsets,
                                                                 emptyFirstPage: fullScreenEmptyID != nil)
                laidOutGroupIDs = Set(offsets.keys)
                scrollToInitialGroup(using: scrollProxy, laidOut: laidOutGroupIDs)
            }
            .clipped()
            .task {
                guard !didInitialize else { return }
                didInitialize = true
                byCategory = initialCategory != nil || (initialDay == nil && initiallyByCategory)
                if startsInCamera { openCamera(animated: false) }
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if args.contains("--preview-camera") || args.contains("--preview-result") || args.contains("--preview-dust") || args.contains("--preview-floating") { openCamera(animated: false) }
                if args.contains("--preview-category") { byCategory = true }
                if args.contains("--preview-review") { review = true }
                if args.contains("--preview-detail") { selected = words.first }
                #endif
                onReady()
                scrollToInitialGroup(using: scrollProxy, laidOut: laidOutGroupIDs)
            }
            .onChange(of: byCategory) { _, _ in resetTimeline(using: scrollProxy) }
            .onChange(of: search) { _, _ in resetTimeline(using: scrollProxy) }
            .onChange(of: searching) { _, _ in resetTimeline(using: scrollProxy) }
            .onChange(of: fullScreenEmptyID) { _, _ in
                emptyCoverReleased = false
                resetTimeline(using: scrollProxy)
            }
            .onChange(of: savedWordID) { _, id in
                guard id != nil else { return }
                // Saving the first word removes the empty-page spacer; return to today's header.
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(100))
                    resetTimeline(using: scrollProxy)
                }
            }
            #if DEBUG
            .task {
                // Headless visual sampling only; this does not simulate a finger gesture.
                let arguments = ProcessInfo.processInfo.arguments
                guard arguments.contains("--uitesting"), arguments.contains("--preview-timeline-motion") else { return }
                do {
                    try await Task.sleep(for: .seconds(2))
                    let stops = Array(groups.dropFirst().prefix(2)) + Array(groups.prefix(1))
                    for group in stops {
                        withAnimation(.easeInOut(duration: 0.7)) { scrollProxy.scrollTo(group.id, anchor: .top) }
                        try await Task.sleep(for: .seconds(2))
                    }
                } catch { /* View dismissed; stop sampling. */ }
            }
            .task {
                // Programmatic rendering sample, not touch/gesture verification.
                let arguments = ProcessInfo.processInfo.arguments
                guard arguments.contains("--uitesting"), arguments.contains("--preview-camera-motion") else { return }
                do {
                    try await Task.sleep(for: .seconds(3))
                    cameraPulling = true
                    capture = true
                    withAnimation(.linear(duration: 0.6)) { cameraReveal = 0.38 }
                    // Keep this checkpoint stable for a real XCTest tap when requested.
                    try await Task.sleep(for: .seconds(arguments.contains("--hold-camera-pull") ? 8 : 1.5))
                    openCamera()
                    try await Task.sleep(for: .seconds(2))
                    closeCamera()
                } catch { /* View dismissed; stop sampling. */ }
            }
            #endif
        }
    }

    private func groupContent(_ group: WordGroup, viewportHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if let date = group.date {
                    LibraryDateHeading(date: date, count: group.words.count)
                        .opacity(group.id == pinnedGroup?.id || (headerOffsets[group.id] ?? 0) < 0 ? 0 : 1)
                        .accessibilityHidden(group.id == pinnedGroup?.id || (headerOffsets[group.id] ?? 0) < 0)
                } else {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(group.title).font(.system(size: 22, design: .serif)).foregroundStyle(libraryInk)
                        Text("\(group.words.count)个单词").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            if group.id == fullScreenEmptyID {
                Spacer(minLength: 30)
                VStack(spacing: 22) {
                    EmptyDayEyes(active: !capture && (scrollOffset < viewportHeight / 2))
                    Text(HomePresentation.emptyCardMessage)
                        .font(.system(size: 18, weight: .medium))
                        .multilineTextAlignment(.center).foregroundStyle(libraryInk)
                        .accessibilityIdentifier("emptyTodayMessage")
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 108)
            } else if group.words.isEmpty {
                Button("拍摄单词") { openCamera() }
                    .font(.system(size: 14)).foregroundStyle(Palette.muted)
                    .padding(.horizontal, 24).padding(.top, 25).padding(.bottom, 24)
            } else {
                wordGrid(group.words).padding(.top, 32)
            }
        }
        .padding(.bottom, group.id == fullScreenEmptyID ? 0 : (byCategory ? 38 : 54))
        .frame(height: group.id == fullScreenEmptyID ? viewportHeight : nil, alignment: .top)
    }

    private func coverGesture(using proxy: ScrollViewProxy, viewportHeight: CGFloat) -> some Gesture {
        // The sheet itself moves, so measure the finger in the stationary screen space.
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .updating($verticalGestureActive) { _, active, _ in active = true }
            .onChanged { gesture in
                guard !cameraTransitioning, !isFlippingCover else { return }
                if cameraGestureStart == nil {
                    cameraGestureStart = holdsEmptyCover ? 0 : (userScrollStarted ? gestureStartScrollOffset : scrollOffset)
                }
                let progress = CameraPullPolicy.progress(horizontal: gesture.translation.width,
                                                          vertical: gesture.translation.height, height: screenHeight)
                if (cameraPulling || (!capture && canPullCamera(from: cameraGestureStart ?? scrollOffset))), progress > 0 {
                    if !cameraPulling {
                        cameraPulling = true
                        cameraMode = true
                        cameraClosing = false
                        captureSavedWord = false
                        capture = true
                        // Keep list content at its origin; only the whole paper sheet follows the pull.
                        if let first = groups.first { proxy.scrollTo(first.id, anchor: .top) }
                    }
                    cameraReveal = progress
                    return
                }
                if cameraPulling { cameraReveal = 0; return }
                guard fullScreenEmptyID != nil, groups.count > 1, !holdsEmptyCover,
                      !isFlippingCover, userScrollStarted, !gestureStartedOnEmptyPage,
                      scrollOffset <= viewportHeight + 1,
                      LibraryScrollPolicy.returnsToEmptyPage(horizontal: gesture.translation.width,
                          vertical: gesture.translation.height,
                          distanceToBoundary: gestureStartScrollOffset - viewportHeight) else { return }
                // Commit while the drag is still alive; cancel native scrolling only AFTER
                // this decision. The page flip does not depend on a cancelled onEnded callback.
                flipEmptyCover(showing: true, using: proxy)
            }
            .onEnded { gesture in
                cameraGestureStart = nil
                if cameraPulling {
                    let committed = cameraReveal > 0 && CameraPullPolicy.commits(distance: gesture.translation.height,
                                                             predictedDistance: gesture.predictedEndTranslation.height,
                                                             height: screenHeight)
                    cameraPulling = false
                    if committed { openCamera(); Haptics.tap() }
                    else { closeCamera() }
                    return
                }
                if holdsEmptyCover, !isFlippingCover, !capture, !cameraTransitioning,
                   LibraryScrollPolicy.advancesEmptyPage(horizontal: gesture.translation.width,
                                                        vertical: gesture.translation.height) {
                    flipEmptyCover(showing: false, using: proxy)
                }
            }
    }

    private func canPullCamera(from offset: Double) -> Bool {
        CameraPullPolicy.canBegin(startOffset: offset, dateMode: !byCategory && !searching,
                                   startsOnToday: groups.first?.date.map { Calendar.current.isDateInToday($0) } ?? false)
    }

    private func openCamera(animated: Bool = true) {
        guard !cameraTransitioning else { return }
        captureSavedWord = false
        cameraClosing = false
        cameraMode = true
        capture = true
        cameraPulling = false
        userScrollStarted = false
        cameraTransitioning = animated && !reduceMotion
        withAnimation(animated && !reduceMotion ? .spring(response: 0.42, dampingFraction: 0.9) : nil) {
            cameraReveal = 1
        } completion: {
            cameraTransitioning = false
        }
    }

    private func closeCamera() {
        guard !cameraTransitioning else { return }
        cameraPulling = false
        cameraGestureStart = nil
        userScrollStarted = false
        if captureSavedWord || !cameraMode || cameraReveal == 0 {
            cameraReveal = 0
            capture = false
            captureSavedWord = false
            cameraClosing = false
            return
        }
        cameraTransitioning = true
        cameraClosing = true
        withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.88)) {
            cameraReveal = 0
        } completion: {
            capture = false
            cameraTransitioning = false
            captureSavedWord = false
            cameraClosing = false
        }
    }

    private func flipEmptyCover(showing: Bool, using proxy: ScrollViewProxy) {
        guard !isFlippingCover, let emptyID = fullScreenEmptyID,
              let firstHistory = groups.dropFirst().first(where: { !$0.words.isEmpty }) else { return }
        userScrollStarted = false
        didFirePageHaptic = true
        emptyCoverReleased = true
        isFlippingCover = true
        Haptics.tap()
        withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.9)) {
            proxy.scrollTo(showing ? emptyID : firstHistory.id, anchor: .top)
        } completion: {
            emptyCoverReleased = !showing
            isFlippingCover = false
        }
    }

    private func wordGrid(_ groupWords: [Word]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                  alignment: .center, spacing: byCategory ? 28 : 30) {
            ForEach(groupWords) { word in
                Button { selected = word; Haptics.tap() } label: {
                    VStack(spacing: -2) {
                        StickerArtwork(data: word.imageData, asset: word.assetName)
                            .frame(width: 132, height: 142)
                           .background {
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear { reportTarget(word, frame: geometry.frame(in: .global)) }
                                        .onChange(of: geometry.frame(in: .global)) { _, frame in reportTarget(word, frame: frame) }
                                        .onChange(of: flight.targetID) { _, _ in reportTarget(word, frame: geometry.frame(in: .global)) }
                                }
                            }
                            .opacity(flight.isFlying && flight.targetID == word.id ? 0 : 1)
                        StickerLabel(text: word.name)
                    }
                    .frame(maxWidth: .infinity).frame(height: 196)
                    .rotationEffect(.degrees(rotation(for: word)))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(word.name)，\(word.meaning)")
                .accessibilityIdentifier("word-\(word.name)")
                .id(word.id)
            }
        }
    }

    private func bottomScrollSpace(viewportHeight: CGFloat) -> CGFloat {
        guard let last = groups.last else { return 115 }
        if last.id == fullScreenEmptyID { return 0 }
        // Even a final one-word day can reach the fixed header without being covered by the shutter.
        return max(115, viewportHeight - (groupHeights[last.id] ?? 0))
    }

    private func resetTimeline(using proxy: ScrollViewProxy) {
        userScrollStarted = false
        pendingCoverReturn = false
        isFlippingCover = false
        activeGroupID = groups.first?.id
        if let first = groups.first { proxy.scrollTo(first.id, anchor: .top) }
    }

    private var bottomBar: some View {
        ZStack {
            LinearGradient(colors: [libraryPaper.opacity(0), libraryPaper, libraryPaper], startPoint: .top, endPoint: .bottom)
                .frame(height: 118).opacity(1 - min(1, cameraReveal * 2)).allowsHitTesting(false)
            // Noninteractive copies keep the camera controls above the paper while
            // it is still moving. CaptureView owns the real buttons after settling.
            HStack(spacing: 64) {
                CameraUtilityIcon(symbol: "xmark")
                Color.clear.frame(width: 76, height: 76)
                CameraUtilityIcon(symbol: "photo")
            }
            .padding(.top, 22)
            .opacity(!cameraClosing && (cameraPulling || cameraTransitioning)
                     ? min(1, max(0, (cameraReveal - 0.28) / 0.10)) : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            ShutterButton(action: { openCamera(); Haptics.tap() }, size: 76,
                          cameraProgress: min(1, cameraReveal * 2))
            // Keep this copy above the moving paper until the camera's identical
            // shutter can take over. Cross-fading underneath the sheet hides it.
            .opacity(!capture || cameraPulling || cameraTransitioning ? 1 : 0)
            .padding(.top, 22)
        }.frame(height: 118)
    }

    private func reportTarget(_ word: Word, frame: CGRect) {
        guard flight.targetID == word.id, frame.width > 0, frame.height > 0 else { return }
        flight.targetFrame = frame
    }

    private func displayCategory(_ category: String) -> String {
        switch category {
        case "食物": "食物饮品"
        case "自然", "动物": "动物自然"
        default: category
        }
    }

    private func categoryGroupID(_ category: String) -> String {
        "category:\(displayCategory(category))"
    }

    private func dateGroupID(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.era, .year, .month, .day], from: date)
        return "date:\(components.era ?? 0):\(components.year ?? 0):\(components.month ?? 0):\(components.day ?? 0)"
    }

    private func dateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func scrollToInitialGroup(using proxy: ScrollViewProxy, laidOut ids: Set<String>) {
        guard didInitialize, !didScrollToInitialGroup else { return }
        var target = byCategory ? initialCategory.map(categoryGroupID) : initialDay.map(dateGroupID)
        #if DEBUG
        if !byCategory, target == nil, ProcessInfo.processInfo.arguments.contains("--preview-first-history") {
            target = groups.dropFirst().first?.id
        }
        #endif
        guard let target else {
            didScrollToInitialGroup = true
            return
        }
        guard ids.contains(target) else { return }
        didScrollToInitialGroup = true
        proxy.scrollTo(target, anchor: .top)
    }

    private func rotation(for word: Word) -> Double {
        let values: [Double] = [-3, 2, -1, 3, -2, 1]
        return values[Int(word.id.uuid.0) % values.count]
    }
}

