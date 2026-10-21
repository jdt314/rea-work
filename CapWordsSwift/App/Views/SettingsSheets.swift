import SwiftUI
import PhotosUI
import AVFoundation

struct SettingsCloseButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark").font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.ink).frame(width: 40, height: 40)
                .background(Palette.surface, in: Circle())
        }.buttonStyle(.plain).accessibilityLabel("关闭")
    }
}

struct SettingsPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Palette.library).frame(minWidth: 150, minHeight: 56)
            .padding(.horizontal, 26).background(Palette.ink, in: Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct SettingsProfileEditor: View {
    @Binding var nickname: String
    @Binding var avatar: Data
    @Environment(\.dismiss) private var dismiss
    @State private var draftName = ""
    @State private var draftAvatar = Data()
    @State private var photo: PhotosPickerItem?
    @State private var error: String?
    var body: some View {
        VStack(spacing: 14) {
            PhotosPicker(selection: $photo, matching: .images) { [draftAvatar] in
                SettingsAvatar(data: draftAvatar, size: 78)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill").font(.system(size: 12)).foregroundStyle(.secondary)
                            .frame(width: 25, height: 25).background(Palette.surface, in: Circle())
                    }
            }.accessibilityLabel("更换头像")
            TextField("昵称", text: $draftName).font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center).submitLabel(.done)
                .accessibilityIdentifier("profileNicknameField")
            Text("随时可以更改头像和昵称。\n资料保存在这台设备上。")
                .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("保存") {
                nickname = String(draftName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(30))
                avatar = draftAvatar
                Haptics.success()
                dismiss()
            }.buttonStyle(SettingsPrimaryButtonStyle())
                .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("saveProfileButton")
            Button("取消") { dismiss() }.font(.system(size: 13)).foregroundStyle(.secondary)
        }
        .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.library)
        .onAppear { draftName = nickname; draftAvatar = avatar }
        .onChange(of: photo) { _, item in
            Task {
                do {
                    guard let data = try await item?.loadTransferable(type: Data.self),
                          let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else { return }
                    let edge: CGFloat = 256
                    let scale = max(edge / image.size.width, edge / image.size.height)
                    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                    let format = UIGraphicsImageRendererFormat(); format.scale = 1
                    let rendered = UIGraphicsImageRenderer(size: CGSize(width: edge, height: edge), format: format).image { _ in
                        image.draw(in: CGRect(x: (edge - size.width) / 2, y: (edge - size.height) / 2, width: size.width, height: size.height))
                    }
                    guard let jpeg = rendered.jpegData(compressionQuality: 0.85) else { return }
                    draftAvatar = jpeg
                } catch { self.error = error.localizedDescription }
            }
        }
        .alert("无法读取照片", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("知道了", role: .cancel) { error = nil }
        } message: { Text(error ?? "") }
    }
}

struct SettingsLanguageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("learningLanguage") private var language = LearningLanguage.english.rawValue
    @AppStorage("nativeLanguage") private var nativeLanguage = LearningLanguage.chinese.rawValue
    @State private var draft = LearningLanguage.english.rawValue
    @State private var path: [String] = []
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    Text("切换学习语言").font(.system(size: 23, weight: .bold))
                    Text("切换后，已拍摄和掌握的单词会继续保留")
                        .font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        ForEach(LearningLanguage.allCases) { option in
                            Button { draft = option.rawValue; Haptics.tap() } label: {
                                VStack(spacing: 10) {
                                    Text(verbatim: option.flag).font(.system(size: 33))
                                    Text(LocalizedStringKey(option.title)).font(.system(size: 15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity).frame(height: 100)
                                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
                                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(draft == option.rawValue ? Palette.ink : Palette.separator.opacity(0.18),
                                                                                        lineWidth: draft == option.rawValue ? 2.5 : 1))
                            }
                            .buttonStyle(.plain).accessibilityIdentifier("learning-language-\(option.rawValue)")
                            .accessibilityValue(draft == option.rawValue ? "已选择" : "未选择")
                        }
                    }.padding(.top, 20)
                }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 28)
            }
            .background(Palette.library.ignoresSafeArea()).foregroundStyle(Palette.ink)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { SettingsCloseButton() }
                ToolbarItem(placement: .confirmationAction) {
                    NavigationLink(value: "native") {
                        Text("母语").font(.system(size: 13)).foregroundStyle(.secondary)
                    }.accessibilityIdentifier("nativeLanguageButton")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { _ in SettingsNativeLanguageSheet(selection: $nativeLanguage) }
            .safeAreaInset(edge: .bottom) {
                Button("完成") { language = draft; Haptics.success(); dismiss() }
                    .buttonStyle(SettingsPrimaryButtonStyle()).padding(.vertical, 10)
                    .frame(maxWidth: .infinity).background(Palette.library.opacity(0.95))
                    .accessibilityIdentifier("saveLearningLanguageButton")
            }
        }
        .onAppear { draft = language }
        #if DEBUG
        .task {
            guard LaunchOptions.arguments.contains("--uitesting"), LaunchOptions.arguments.contains("--preview-settings-native-language") else { return }
            path = ["native"]
        }
        #endif
    }
}

struct SettingsNativeLanguageSheet: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft = LearningLanguage.chinese.rawValue
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("更改你的母语").font(.system(size: 23, weight: .bold)).padding(.bottom, 28)
                ForEach(LearningLanguage.allCases) { option in
                    Button { draft = option.rawValue; Haptics.tap() } label: {
                        HStack(spacing: 15) {
                            Text(verbatim: option.flag).font(.system(size: 26))
                            Text(LocalizedStringKey(option.title)).font(.system(size: 17))
                            Spacer()
                        }
                        .padding(.horizontal, 20).frame(height: 54)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(draft == option.rawValue ? Palette.ink : Palette.separator.opacity(0.18),
                                                                                lineWidth: draft == option.rawValue ? 2.5 : 1))
                    }.buttonStyle(.plain).accessibilityIdentifier("native-language-\(option.rawValue)")
                }
            }.padding(20)
        }
        .background(Palette.library.ignoresSafeArea()).foregroundStyle(Palette.ink)
        .toolbarBackground(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Button("完成") { selection = draft; Haptics.success(); dismiss() }
                .buttonStyle(SettingsPrimaryButtonStyle()).padding(.vertical, 10)
                .frame(maxWidth: .infinity).background(Palette.library.opacity(0.95))
        }.onAppear { draft = selection }
    }
}

struct SettingsReminderSheet: View {
    @AppStorage("dailyReminderEnabled") private var enabled = false
    @AppStorage("dailyReminderMinutes") private var minutes = 780
    @Environment(\.openURL) private var openURL
    @State private var busy = false
    @State private var error: String?
    @State private var scheduleTask: Task<Void, Never>?
    private var time: Binding<Date> {
        Binding(get: { Calendar.current.startOfDay(for: .now).addingTimeInterval(Double(minutes * 60)) }, set: { date in
            let values = Calendar.current.dateComponents([.hour, .minute], from: date)
            minutes = (values.hour ?? 13) * 60 + (values.minute ?? 0)
            reschedule()
        })
    }
    var body: some View {
        VStack(spacing: 18) {
            HStack {
                SettingsCloseButton()
                Spacer()
                Toggle("学习提醒", isOn: Binding(get: { enabled }, set: changeEnabled))
                    .labelsHidden().tint(.orange).disabled(busy).accessibilityIdentifier("studyReminderToggle")
            }
            Image(systemName: "bell").font(.system(size: 26, weight: .light)).padding(.top, 8)
            Text("学习提醒").font(.system(size: 23, weight: .bold))
            Text("你想在什么时候收到学习提醒？").font(.system(size: 14)).foregroundStyle(.secondary)
            DatePicker("提醒时间", selection: time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel).labelsHidden().environment(\.locale, Locale(identifier: "zh_CN"))
                .frame(maxWidth: 280).frame(height: 180).accessibilityIdentifier("studyReminderTime")
            if let error {
                Text(error).font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("打开系统设置") { openURL(URL(string: UIApplication.openSettingsURLString)!) }.font(.system(size: 13))
            }
            Spacer(minLength: 0)
            Text("小建议：把学习和日常习惯结合，更容易坚持")
                .font(.system(size: 12)).foregroundStyle(.tertiary).multilineTextAlignment(.center)
        }
        .padding(20).padding(.bottom, 22).foregroundStyle(Palette.ink)
        .onDisappear {
            scheduleTask?.cancel()
            if enabled {
                let savedMinutes = minutes
                Task { try? await StudyReminderService.schedule(minutes: savedMinutes, requestPermission: false) }
            }
        }
    }
    private func changeEnabled(_ value: Bool) {
        scheduleTask?.cancel()
        if !value { enabled = false; StudyReminderService.cancel(); Haptics.tap(); return }
        busy = true
        Task {
            defer { busy = false }
            do {
                try await StudyReminderService.schedule(minutes: minutes, requestPermission: true)
                enabled = true; error = nil; Haptics.success()
            } catch { self.error = error.localizedDescription; enabled = false }
        }
    }
    private func reschedule() {
        scheduleTask?.cancel()
        guard enabled else { return }
        scheduleTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
                try await StudyReminderService.schedule(minutes: minutes, requestPermission: false)
            } catch is CancellationError { }
            catch { self.error = error.localizedDescription }
        }
    }
}

struct SettingsVoiceGroup: Identifiable {
    let id: Int
    let title: LocalizedStringKey
    let voices: [AVSpeechSynthesisVoice]
}

struct SettingsVoiceSheet: View {
    @AppStorage("learningLanguage") private var languageCode = LearningLanguage.english.rawValue
    @AppStorage("pronunciationVoiceIdentifier") private var selected = ""
    @AppStorage("pronunciationSpeed") private var speed = 1.0
    @State private var groups: [SettingsVoiceGroup] = []
    private let colors: [Color] = [.cyan, .mint, .yellow, .purple, .pink, .blue]
    private var activeIdentifier: String { selected.isEmpty ? AVSpeechSynthesisVoice(language: languageCode)?.identifier ?? "" : selected }
    var body: some View {
        VStack(spacing: 0) {
            HStack { SettingsCloseButton(); Spacer() }.padding(16)
            ScrollView {
                VStack(spacing: 20) {
                    Text("选择一个你每天都想听到的\n声音").font(.system(size: 23, weight: .bold)).multilineTextAlignment(.center)
                    Text("每个声音都有自己的特色，试试几个，找到最适合你的那个")
                        .font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.bottom, 18)
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.title).font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary).padding(.leading, 5)
                            ForEach(Array(group.voices.enumerated()), id: \.element.identifier) { index, voice in
                                Button { selected = voice.identifier; preview(); Haptics.tap() } label: {
                                    SettingsVoiceRow(name: voice.name, color: colors[index % colors.count], selected: activeIdentifier == voice.identifier)
                                }.buttonStyle(.plain).accessibilityIdentifier("voice-\(voice.identifier)")
                                    .accessibilityValue(activeIdentifier == voice.identifier ? "已选择" : "未选择")
                            }
                        }
                    }
                    if groups.isEmpty {
                        ContentUnavailableView("暂无可用声音", systemImage: "speaker.slash", description: Text("可在系统辅助功能的朗读内容设置中下载声音。"))
                    }
                    Text("这里展示本机可用的系统声音。可在系统辅助功能的朗读内容设置中下载更多声音。")
                        .font(.system(size: 12)).foregroundStyle(.secondary).padding(.vertical, 12)
                }.padding(.horizontal, 20).padding(.bottom, 10)
            }
        }
        .foregroundStyle(Palette.ink)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                HStack {
                    Text("语速").font(.system(size: 14)).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(speed, specifier: "%.1f")x").font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                Slider(value: $speed, in: 0.5...1.5, step: 0.1, onEditingChanged: { editing in if !editing { preview() } })
                    .tint(Palette.ink).accessibilityLabel("语速").accessibilityIdentifier("pronunciationSpeedSlider")
            }
            .padding(18).background(Palette.surface.opacity(0.85), in: RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 20).padding(.bottom, 12).background(Palette.library.opacity(0.98))
        }
        .task {
            let family = languageCode.split(separator: "-").first ?? "en"
            let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.split(separator: "-").first == family }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            let genders: [(AVSpeechSynthesisVoiceGender, LocalizedStringKey)] = [(.male, "男声"), (.female, "女声"), (.unspecified, "系统声音")]
            groups = genders.compactMap { gender, title in
                let matches = voices.filter { $0.gender == gender }
                return matches.isEmpty ? nil : SettingsVoiceGroup(id: gender.rawValue, title: title, voices: matches)
            }
        }
        .onDisappear { SpeechService.shared.stop() }
    }
    private func preview() {
        let language = LearningLanguage(rawValue: languageCode) ?? .english
        SpeechService.shared.speak(language.voiceSample, language: languageCode, voiceIdentifier: activeIdentifier, speed: speed)
    }
}

struct SettingsVoiceRow: View {
    let name: String
    let color: Color
    let selected: Bool
    var body: some View {
        HStack(spacing: 15) {
            Circle().fill(color.opacity(0.35)).overlay(Circle().fill(color.opacity(0.12)).padding(9)).frame(width: 62, height: 62)
            Text(verbatim: name).font(.system(size: 16, weight: .semibold))
            Spacer()
            ZStack {
                Circle().fill(selected ? Color.orange : .clear)
                if selected { Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white) }
                else { Circle().strokeBorder(Palette.separator.opacity(0.45), lineWidth: 2) }
            }.frame(width: 26, height: 26)
        }.padding(.horizontal, 22).frame(minHeight: 96)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct SettingsWidgetGuide: View {
    let word: Word?
    @Environment(\.dismiss) private var dismiss
    @State private var showSteps = false
    var body: some View {
        VStack(spacing: 22) {
            HStack { SettingsCloseButton(); Spacer() }
            Spacer(minLength: 0)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    StickerArtwork(data: word?.imageData, asset: word?.assetName ?? "sample-donut").frame(width: 78, height: 86)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: word?.name ?? "Donut").font(.system(size: 18, weight: .bold))
                        Text(verbatim: word?.meaning ?? "甜甜圈").font(.system(size: 12))
                        Spacer(minLength: 0)
                        Text(verbatim: SettingsAppInfo.name).font(.system(size: 10))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.padding(16).foregroundStyle(Palette.cardInk)
                    .frame(height: 132).background(Color.orange.opacity(0.65), in: RoundedRectangle(cornerRadius: 20))
                HStack(spacing: 12) {
                    ForEach(0..<3) { _ in RoundedRectangle(cornerRadius: 12).fill(Palette.separator.opacity(0.18)).frame(height: 50) }
                }
            }
            .padding(18).frame(maxWidth: 270)
            .background(Palette.separator.opacity(0.10), in: RoundedRectangle(cornerRadius: 32))
            .overlay(RoundedRectangle(cornerRadius: 32).strokeBorder(Palette.separator.opacity(0.25), lineWidth: 3))
            Text("将小组件添加到\n主屏幕！").font(.system(size: 23, weight: .bold)).multilineTextAlignment(.center)
            Button("添加小组件到主屏幕") { showSteps = true }
                .buttonStyle(SettingsPrimaryButtonStyle()).accessibilityIdentifier("widgetInstructionsButton")
            Button("以后再说") { dismiss() }.font(.system(size: 13)).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(20).foregroundStyle(Palette.ink)
        .alert("添加主屏幕小组件", isPresented: $showSteps) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text("长按主屏幕空白处，轻点“编辑”→“添加小组件”，搜索 \(SettingsAppInfo.name)，选择尺寸后添加。")
        }
    }
}
