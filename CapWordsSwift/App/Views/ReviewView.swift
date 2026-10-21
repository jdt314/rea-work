import SwiftUI
import SwiftData

struct ReviewHomeView: View {
    let words: [Word]
    @Query(sort: \ReviewRecord.day, order: .reverse) private var records: [ReviewRecord]
    @AppStorage("flashcardCount") private var newLimit = 5
    @State private var selectedDate = Date.now
    @State private var month = Date.now
    @State private var session: ReviewSelection?
    @State private var settings = false
    @State private var draftLimit = 5
    private var todayRecord: ReviewRecord? { records.first { Calendar.current.isDateInToday($0.day) } }
    private var selectedRecord: ReviewRecord? { records.first { Calendar.current.isDate($0.day, inSameDayAs: selectedDate) } }
    private var queue: [Word] { ReviewQueue.make(words: words, newLimit: newLimit) }
    private var streak: Int {
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: .now)
        if todayRecord == nil { date = calendar.date(byAdding: .day, value: -1, to: date)! }
        var result = 0
        let days = Set(records.map(\.day))
        while days.contains(date) {
            result += 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                ReviewHomePreview(words: Array((queue.isEmpty ? words : queue).prefix(5)))
                    .frame(height: 235).padding(.top, 20)
                VStack(spacing: 10) {
                    Label("STREAK", systemImage: "flame.fill")
                        .font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(Palette.orange)
                    Text(todayRecord == nil ? "今天还未复习" : "今天已完成复习")
                        .font(.system(size: 23, weight: .medium))
                    Text("已经连续复习 \(streak) 天了，继续保持！")
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                }
                Button {
                    let chosen = todayRecord.map { record in
                        let lookup = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })
                        return record.wordIDs.compactMap { lookup[$0] }
                    } ?? queue
                    session = ReviewSelection(words: chosen)
                } label: {
                    Text(todayRecord == nil ? (queue.isEmpty ? "今天无复习内容" : "开始复习") : "再次复习")
                        .font(.system(size: 17, weight: .semibold)).foregroundStyle(Color(red: 251/255, green: 243/255, blue: 220/255))
                        .frame(width: 160, height: 58).background(.black, in: Capsule())
                }
                .disabled(queue.isEmpty && todayRecord == nil)
                .accessibilityIdentifier("startReviewSessionButton")
                ReviewCalendar(month: $month, selectedDate: $selectedDate, recordedDays: Set(records.map(\.day)))
                if let record = selectedRecord {
                    HStack {
                        ReviewStatistic(value: record.wordIDs.count, title: "已复习")
                        ReviewStatistic(value: record.knownIDs.count, title: "认识")
                        ReviewStatistic(value: record.unknownIDs.count, title: "未掌握")
                    }.padding(20).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 24))
                }
                Button("设置每日复习数量") { draftLimit = newLimit; settings = true }
                    .font(.system(size: 16, weight: .medium)).foregroundStyle(.secondary.opacity(0.65))
                    .padding(.horizontal, 30).frame(height: 48)
                    .background(Color.black.opacity(0.035), in: Capsule()).padding(.bottom, 25)
                    .accessibilityIdentifier("reviewDailyLimitButton")
            }.padding(.horizontal, 20).padding(.top, 10)
        }
        .background(reviewBackground)
        .safeAreaInset(edge: .top, spacing: 0) {
            Text("复习").font(.system(size: 21, weight: .medium))
                .frame(maxWidth: .infinity).padding(.vertical, 8).background(reviewBackground)
        }
        .fullScreenCover(item: $session) { selection in ReviewView(words: selection.words) }
        #if DEBUG
        .onAppear {
            if LaunchOptions.arguments.contains("--uitesting"), LaunchOptions.arguments.contains("--preview-flashcard") {
                session = ReviewSelection(words: queue)
            }
        }
        #endif
        .sheet(isPresented: $settings) {
            NavigationStack {
                VStack(spacing: 28) {
                    Text("每日学习的新单词数量，到期单词会全部加入复习。")
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(Array(stride(from: 5, through: 40, by: 5)), id: \.self) { value in
                            Button { draftLimit = value } label: {
                                Text("\(value)").frame(maxWidth: .infinity).frame(height: 48)
                                    .background(draftLimit == value ? Color.black : Color.gray.opacity(0.1), in: Capsule())
                                    .foregroundStyle(draftLimit == value ? .white : .primary)
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(28).navigationTitle("设置每日复习数量").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("取消") { settings = false } }
                        ToolbarItem(placement: .confirmationAction) { Button("保存") { newLimit = draftLimit; settings = false } }
                    }
            }.presentationDetents([.medium])
        }
    }
}

private struct ReviewSelection: Identifiable {
    let id = UUID()
    let words: [Word]
}

private struct ReviewHomePreview: View {
    let words: [Word]
    var body: some View {
        ZStack {
            ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                let offsets: [CGSize] = [CGSize(width: -85, height: -38), CGSize(width: 0, height: -42), CGSize(width: 85, height: -38), CGSize(width: -43, height: 48), CGSize(width: 43, height: 48)]
                ReviewCardPaper(color: reviewCardColor(index), cornerRadius: 16) {
                    StickerArtwork(data: word.imageData, asset: word.assetName).frame(width: 48, height: 65)
                }
                .frame(width: 95, height: 115)
                .rotationEffect(.degrees(index.isMultiple(of: 2) ? -9 : 9))
                .offset(offsets[index]).zIndex(index < 3 ? 1 : 0)
            }
        }.accessibilityHidden(true)
    }
}

private struct ReviewCalendar: View {
    @Binding var month: Date
    @Binding var selectedDate: Date
    let recordedDays: Set<Date>
    private let calendar = Calendar.current
    private var dates: [Date] {
        let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let padding = calendar.component(.weekday, from: first) - 1
        let count = calendar.range(of: .day, in: .month, for: first)!.count
        return (0..<(padding + count)).map { calendar.date(byAdding: .day, value: $0 - padding, to: first)! }
    }
    private var heading: String {
        let monthName = month.formatted(.dateTime.month(.wide).locale(Locale(identifier: "zh_CN")))
        let day = calendar.isDate(month, equalTo: selectedDate, toGranularity: .month)
            ? calendar.component(.day, from: selectedDate) : 1
        return "\(monthName) \(day), \(calendar.component(.year, from: month))"
    }
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 30, height: 30).background(.black.opacity(0.025), in: Circle()) }.accessibilityLabel("上个月")
                Spacer()
                Text(heading).font(.system(size: 21, weight: .regular)).foregroundStyle(Color(red: 0.12, green: 0.19, blue: 0.20))
                Spacer()
                Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 30, height: 30).background(.black.opacity(0.025), in: Circle()) }.accessibilityLabel("下个月")
            }.foregroundStyle(Color(red: 0.62, green: 0.67, blue: 0.66))
            Rectangle().fill(Color.black.opacity(0.045)).frame(height: 1)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(Array(["日", "一", "二", "三", "四", "五", "六"].enumerated()), id: \.offset) { _, title in
                    Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.orange).padding(.bottom, 12)
                }
                ForEach(dates, id: \.self) { date in
                    let inMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
                    let recorded = recordedDays.contains(calendar.startOfDay(for: date))
                    let selected = calendar.isDate(date, inSameDayAs: selectedDate)
                    Button { selectedDate = date } label: {
                        VStack(spacing: 2) {
                            Circle().fill(recorded ? Palette.orange : Color.black.opacity(0.035))
                                .overlay { if selected { Circle().stroke(Palette.orange, lineWidth: 1.8) } }
                                .frame(width: 29, height: 29)
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(recorded ? Palette.orange : Color(red: 0.65, green: 0.69, blue: 0.68))
                        }.frame(maxWidth: .infinity)
                    }.buttonStyle(.plain).opacity(inMonth ? 1 : 0).disabled(!inMonth)
                        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
                }
            }
        }.padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 36)
            .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 28))
    }
    private func move(_ offset: Int) { month = calendar.date(byAdding: .month, value: offset, to: month)! }
}

private enum ReviewTextMode: String, CaseIterable {
    case target = "仅学习语言", bilingual = "显示双语", hidden = "隐藏双语"
}

struct ReviewView: View {
    let words: [Word]
    var embedded = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Query private var records: [ReviewRecord]
    @State private var queue: [Word] = []
    @State private var index = 0
    @State private var known: [UUID] = []
    @State private var unknown: [UUID] = []
    @State private var flipped = false
    @State private var mode = ReviewTextMode.target
    @State private var drag: CGSize = .zero
    @State private var notice: String?
    @State private var loaded = false
    @State private var finished = false
    @State private var showsSpeechNotice = false
    @State private var isAdvancing = false

    var body: some View {
        NavigationStack {
            ZStack {
                (colorScheme == .dark ? Color(white: 0.10) : reviewBackground).ignoresSafeArea()
                if !finished, index < queue.count {
                    GeometryReader { geometry in
                        let cardWidth = min(geometry.size.width * 0.64, 360)
                        let cardHeight = min(cardWidth * (flipped ? 1.59 : 1.39), geometry.size.height * 0.67)
                        let dragProgress = max(-1, min(1, drag.width / (cardWidth * 0.7)))
                        ZStack {
                            ForEach(0..<3, id: \.self) { layer in
                                if index + layer < queue.count {
                                    let word = queue[index + layer]
                                    ReviewFlashcard(word: word, mode: mode, flipped: layer == 0 && flipped, color: reviewCardColor(index + layer), dragProgress: layer == 0 ? dragProgress : 0)
                                        .frame(width: cardWidth, height: cardHeight)
                                        .rotationEffect(.degrees(layer == 0 ? 0 : (layer == 1 ? 4 : 9) * (1 - abs(dragProgress) * 0.3)))
                                        .rotation3DEffect(.degrees(layer == 0 && !reduceMotion ? Double(dragProgress) * 32 : 0), axis: (x: 0, y: 1, z: 0), perspective: 1.0)
                                        .offset(x: layer == 0 ? drag.width : 0, y: layer == 0 ? drag.height * 0.12 : 0)
                                        .opacity(flipped && layer > 0 ? 0 : 1)
                                        .zIndex(Double(3 - layer))
                                        .allowsHitTesting(layer == 0)
                                }
                            }
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .contentShape(Rectangle())
                        .onTapGesture { flipCard() }
                        .gesture(DragGesture(minimumDistance: 18).onChanged { value in
                            guard !isAdvancing else { return }
                            drag = value.translation
                        }.onEnded { value in
                            if abs(value.translation.width) > cardWidth * 0.32 { grade(remembered: value.translation.width > 0) }
                            else { withAnimation(.spring) { drag = .zero } }
                        })
                        .accessibilityIdentifier("flashcard")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("左滑未掌握，右滑已掌握，轻点翻面")
                        .accessibilityAction(named: "翻面") { flipCard() }
                        .accessibilityAction(named: "记住了") { grade(remembered: true) }
                        .accessibilityAction(named: "再学一次") { grade(remembered: false) }
                        .allowsHitTesting(!isAdvancing)
                        .position(x: geometry.size.width / 2, y: geometry.size.height * 0.40)
                        VStack(spacing: 20) {
                            Text("点击以启用语音模式").font(.system(size: 14)).foregroundStyle(colorScheme == .dark ? Color(white: 0.7) : .gray.opacity(0.7))
                            Button { showsSpeechNotice = true } label: {
                                ZStack {
                                    Image(systemName: "mic").font(.system(size: 25, weight: .light)).offset(x: -2)
                                    Image(systemName: "sparkle").font(.system(size: 9)).offset(x: -12, y: -14)
                                    Image(systemName: "sparkles").font(.system(size: 15)).offset(x: 13, y: 8)
                                }
                                    .foregroundStyle(colorScheme == .dark ? Color(white: 0.7) : .gray.opacity(0.65)).frame(width: 68, height: 68)
                                    .background(colorScheme == .dark ? Color(white: 0.19) : .clear, in: Circle())
                                    .overlay { Circle().stroke(.gray.opacity(0.25), style: StrokeStyle(lineWidth: 1.3, dash: colorScheme == .dark ? [] : [2, 2])) }
                            }.accessibilityLabel("语音模式，尚未接入识别")
                                .accessibilityIdentifier("reviewVoiceModeButton")
                        }.position(x: geometry.size.width / 2, y: geometry.size.height * 0.85)
                    }
                } else if loaded {
                    ReviewCompletion(total: queue.count, known: known.count, unknown: unknown.count, onDone: { dismiss() }, onRetry: retry)
                }
            }
            .navigationTitle(finished ? "复习完成" : "\(index) / \(queue.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { SpeechService.shared.stop(); dismiss() } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel("返回复习首页").accessibilityIdentifier("closeReviewSessionButton")
                }
                ToolbarItem(placement: .principal) {
                    Group {
                        if finished { Text("复习完成") }
                        else { Text("\(index)").foregroundStyle(colorScheme == .dark ? .white : .black) + Text(" / \(queue.count)").foregroundStyle(colorScheme == .dark ? Color(white: 0.7) : .gray.opacity(0.7)) }
                    }.font(.system(size: 18, weight: .medium))
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.primary.opacity(0.035), in: Capsule())
                        .accessibilityIdentifier("reviewProgress")
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("文字显示", selection: $mode) { ForEach(ReviewTextMode.allCases, id: \.self) { Label($0.rawValue, systemImage: $0 == .target ? "a" : ($0 == .bilingual ? "translate" : "line.diagonal")).tag($0) } }
                    } label: { Image(systemName: "ellipsis") }.accessibilityLabel("文字显示模式")
                }
            }
            .tint(.gray)
            .alert("语音模式暂不可用", isPresented: $showsSpeechNotice) {
                Button("知道了", role: .cancel) { }
            } message: { Text("麦克风识别尚未接入。你可以点击音标旁的按钮听发音，或滑动卡片继续复习。") }
            .alert("复习进度未保存", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("知道了", role: .cancel) { notice = nil }
            } message: { Text(notice ?? "") }
            .onAppear {
                if !loaded {
                    queue = words; loaded = true; finished = queue.isEmpty
                    #if DEBUG
                    flipped = LaunchOptions.arguments.contains("--uitesting") && LaunchOptions.arguments.contains("--preview-flashcard-back")
                    if LaunchOptions.arguments.contains("--uitesting") {
                        if let option = LaunchOptions.arguments.first(where: { $0.hasPrefix("--preview-flashcard-index=") }),
                           let previewIndex = Int(option.split(separator: "=").last ?? ""), queue.indices.contains(previewIndex) {
                            index = previewIndex
                        }
                        if LaunchOptions.arguments.contains("--preview-drag-right") { drag = CGSize(width: 75, height: 0) }
                        if LaunchOptions.arguments.contains("--preview-drag-left") { drag = CGSize(width: -75, height: 0) }
                    }
                    #endif
                }
            }
            .onDisappear { SpeechService.shared.stop() }
        }
    }

    private func flipCard() {
        guard !isAdvancing else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) { flipped.toggle() }
        Haptics.tap()
    }

    private func grade(remembered: Bool) {
        guard !finished, !isAdvancing, index < queue.count else { return }
        let word = queue[index]
        let now = Date.now
        let next = ReviewSchedule.next(stage: word.reviewStage, remembered: remembered, now: now)
        word.reviewStage = next.stage
        word.nextReviewAt = next.date
        if next.stage == 4 { word.isMastered = true }
        word.lastReviewAt = now
        word.reviewCount += 1
        let nextKnown = known + (remembered ? [word.id] : [])
        let nextUnknown = unknown + (remembered ? [] : [word.id])
        if index + 1 == queue.count {
            let day = Calendar.current.startOfDay(for: now)
            if let record = records.first(where: { $0.day == day }) {
                record.wordIDs = queue.map(\.id); record.knownIDs = nextKnown; record.unknownIDs = nextUnknown
            } else {
                context.insert(ReviewRecord(date: now, wordIDs: queue.map(\.id), knownIDs: nextKnown, unknownIDs: nextUnknown))
            }
        }
        do { try context.save() } catch { context.rollback(); drag = .zero; notice = error.localizedDescription; return }
        SpeechService.shared.stop()
        Haptics.tap()
        isAdvancing = true
        let completeAdvance = {
            known = nextKnown; unknown = nextUnknown; index += 1; flipped = false; drag = .zero
            finished = index == queue.count
            isAdvancing = false
        }
        if reduceMotion {
            completeAdvance()
        } else {
            withAnimation(.easeOut(duration: 0.22)) {
                drag = CGSize(width: remembered ? 650 : -650, height: 0)
            } completion: {
                completeAdvance()
            }
        }
    }
    private func retry() {
        // 重练选词待 IPA 调用链补证后收敛；当前明确采用本轮完整队列。
        index = 0; known = []; unknown = []; flipped = false; finished = queue.isEmpty
    }
}

private struct ReviewFlashcard: View {
    let word: Word
    let mode: ReviewTextMode
    let flipped: Bool
    let color: Color
    var dragProgress: CGFloat = 0
    var body: some View {
        ZStack {
            front.opacity(flipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .allowsHitTesting(!flipped).accessibilityHidden(flipped)
            back.opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .allowsHitTesting(flipped).accessibilityHidden(!flipped)
        }
    }

    private var back: some View {
        ReviewCardPaper(color: .white, grainOpacity: 0.14) {
            GeometryReader { geometry in
                let inset = geometry.size.width * 0.15
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 7) {
                            Text(word.pronunciation).font(.system(size: 15))
                            Button { SpeechService.shared.speak(word.name, language: word.languageCode) } label: {
                                Image(systemName: "speaker.wave.2.fill").font(.system(size: 13)).padding(.vertical, 6)
                            }.buttonStyle(.plain).accessibilityLabel("播放发音")
                        }
                        Text(word.name).font(.system(size: 32, weight: .bold, design: .rounded))
                            .lineLimit(2).minimumScaleFactor(0.65)
                    }.padding(.horizontal, inset).padding(.top, geometry.size.height * 0.14)
                        .padding(.bottom, geometry.size.height * 0.045)
                    Rectangle().fill(color.opacity(0.65)).frame(height: 1)
                    Text(word.meaning).font(.system(size: 39, weight: .bold))
                        .multilineTextAlignment(.leading).lineLimit(4).minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, inset).padding(.top, geometry.size.height * 0.035)
                        .accessibilityIdentifier("flashcardBackMeaning")
                    Spacer(minLength: 8)
                    Image("launch-mark").resizable().scaledToFit().saturation(0).opacity(0.22)
                        .frame(width: 38, height: 38).padding(.leading, inset)
                        .padding(.bottom, geometry.size.height * 0.055).accessibilityHidden(true)
                }.foregroundStyle(Color(white: 0.15)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }.accessibilityIdentifier("flashcardBack")
    }

    private var front: some View {
        ReviewCardPaper(color: color, edgeIntensity: abs(dragProgress)) {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ReviewSwipeArtwork(word: word, intensity: max(0, dragProgress))
                        .frame(width: geometry.size.width * 0.52, height: geometry.size.height * 0.41)
                    Spacer(minLength: 8)
                    VStack(spacing: 16) {
                        if mode != .hidden {
                            Text(word.name).font(.system(size: 31, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.6).lineLimit(2)
                            HStack(spacing: 5) {
                                if !word.pronunciation.isEmpty { Text(word.pronunciation).font(.system(size: 14)) }
                                Button { SpeechService.shared.speak(word.name, language: word.languageCode) } label: {
                                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 12)).padding(.vertical, 6)
                                }.buttonStyle(.plain).accessibilityLabel("播放发音")
                            }
                            if mode == .bilingual { Text(word.meaning).font(.system(size: 17)) }
                        }
                    }.multilineTextAlignment(.center).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(minHeight: geometry.size.height * 0.23)
                }.padding(.horizontal, 16).padding(.top, geometry.size.height * 0.14)
                    .padding(.bottom, geometry.size.height * 0.065)
            }
        }
    }
}

/// 右拖的全息闪光只覆盖物品的 alpha 轮廓，不染色卡纸和文字。
private struct ReviewSwipeArtwork: View {
    let word: Word
    let intensity: CGFloat
    private var reveal: Double { Double(min(1, intensity * 2.4)) }
    var body: some View {
        ZStack {
            StickerArtwork(data: word.imageData, asset: word.assetName).opacity(1 - reveal)
            ZStack {
                LinearGradient(colors: [Color(red: 1, green: 0.48, blue: 0.74), Color(red: 1, green: 0.86, blue: 0.56), Color(red: 0.78, green: 0.97, blue: 0.84), Color(red: 0.49, green: 0.72, blue: 1), Color(red: 0.65, green: 0.35, blue: 1)], startPoint: .top, endPoint: .bottom)
                Canvas { context, size in
                    for index in 0..<850 {
                        let nx = sin(Double(index + 1) * 23.171) * 43758.5453
                        let ny = sin(Double(index + 1) * 71.317) * 23421.631
                        let x = CGFloat(nx - floor(nx)) * size.width
                        let y = CGFloat(ny - floor(ny)) * size.height
                        let diameter: CGFloat = index.isMultiple(of: 7) ? 1.1 : 0.5
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)), with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.85 : 0.4)))
                    }
                }
                LinearGradient(colors: [.clear, .white.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .offset(y: -15 + intensity * 30)
            }
            .mask { StickerArtwork(data: word.imageData, asset: word.assetName, outlined: false) }
            .opacity(reveal)
        }.accessibilityHidden(true)
    }
}

private struct ReviewCardPaper<Content: View>: View {
    let color: Color
    var cornerRadius: CGFloat = 36
    var grainOpacity: Double = 0.24
    var edgeIntensity: CGFloat = 0
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius).fill(color)
            Canvas { context, size in
                for index in 0..<500 {
                    let noiseX = sin(Double(index + 1) * 12.9898) * 43758.5453
                    let noiseY = sin(Double(index + 1) * 78.233 + 37.7) * 23421.631
                    let x = CGFloat(noiseX - floor(noiseX)) * size.width
                    let y = CGFloat(noiseY - floor(noiseY)) * size.height
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: index % 3 == 0 ? 1.4 : 0.7, height: index % 3 == 0 ? 1.4 : 0.7)), with: .color(.black.opacity(grainOpacity)))
                }
            }.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            content()
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color(red: 1, green: 0.98, blue: 0.87).opacity(Double(edgeIntensity) * 0.95), lineWidth: 1.2)
                .allowsHitTesting(false)
        }.shadow(color: .black.opacity(0.035), radius: 8, y: 6)
    }
}

private struct ReviewStatistic: View {
    let value: Int
    let title: String
    var body: some View {
        VStack(spacing: 8) {
            Text("\(value)").font(.system(size: 27, weight: .semibold))
                .accessibilityIdentifier("reviewStatistic-\(title)")
            Text(title).font(.system(size: 13)).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }
}

private struct ReviewCompletion: View {
    let total: Int
    let known: Int
    let unknown: Int
    let onDone: () -> Void
    let onRetry: () -> Void
    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 65)).foregroundStyle(Palette.orange)
            Text(total == 0 ? "今天无复习内容" : "复习完成！").font(.system(size: 28, weight: .medium))
            HStack { ReviewStatistic(value: total, title: "已复习"); ReviewStatistic(value: known, title: "认识"); ReviewStatistic(value: unknown, title: "未掌握") }
            if total > 0 { Button("再次复习", action: onRetry).buttonStyle(.bordered).accessibilityIdentifier("retryReviewButton") }
            Button("完成", action: onDone).buttonStyle(.borderedProminent).tint(.black).accessibilityIdentifier("finishReviewButton")
        }.padding(30)
    }
}

private func reviewCardColor(_ index: Int) -> Color {
    let colors = [Color(red: 0.69, green: 0.67, blue: 0.63), Color(red: 0.74, green: 0.78, blue: 0.75), Color(red: 0.59, green: 0.54, blue: 0.43), Color(red: 0.71, green: 0.68, blue: 0.61), Color(red: 0.65, green: 0.62, blue: 0.55)]
    return colors[index % colors.count]
}

private let reviewBackground = Color(red: 239/255, green: 239/255, blue: 239/255)
