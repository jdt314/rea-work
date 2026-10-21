import SwiftUI
import SwiftData

enum SettingsInterfaceLanguage {
    static var currentTitle: String {
        let identifier = Bundle.main.preferredLocalizations.first ?? "zh-Hans"
        return identifier.hasPrefix("en") ? "English" : "中文"
    }
}

struct SettingsHealthView: View {
    @State private var health = SettingsHealthStore()
    @Environment(\.openURL) private var openURL
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 30) {
                    Image("launch-mark").resizable().scaledToFit().padding(8).frame(width: 80, height: 80)
                        .background(Color.yellow.opacity(0.65), in: RoundedRectangle(cornerRadius: 20))
                    Image(systemName: "arrow.left.arrow.right").font(.system(size: 26, weight: .semibold)).foregroundStyle(.tertiary)
                    Image(systemName: "heart.fill").font(.system(size: 42))
                        .foregroundStyle(LinearGradient(colors: [.pink, .red], startPoint: .top, endPoint: .bottom))
                        .frame(width: 80, height: 80).background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
                }.padding(.top, 36)
                Text("连接 Apple 健康后，可以在这里查看数据来源的连接状态。仅在你授权后读取选定数据，不会向 Apple 健康写入，也不会上传健康数据。你可以在“健康”App 的个人资料中管理权限。")
                    .font(.system(size: 14)).foregroundStyle(.secondary).lineSpacing(6)
                Button {
                    Task { await health.connect() }
                } label: {
                    HStack {
                        Spacer()
                        if health.busy { ProgressView() }
                        Text(health.requested ? "重新检查连接" : "连接 Apple 健康").font(.system(size: 16, weight: .semibold))
                        Spacer()
                    }.frame(minHeight: 56).background(Palette.surface, in: Capsule())
                }.buttonStyle(.plain).disabled(health.busy || !health.available).accessibilityIdentifier("connectAppleHealthButton")
                Button("打开健康 App") { openURL(URL(string: "x-apple-health://")!) }
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.ink)
                SettingsCardSection("数据来源") {
                    HStack {
                        Text("读取权限")
                        Spacer()
                        Text("在健康中管理").font(.system(size: 12)).foregroundStyle(.secondary)
                    }.padding(.horizontal, 24).frame(minHeight: 64)
                    ForEach(SettingsHealthStore.sources) { source in
                        SettingsDivider()
                        HStack {
                            Text(LocalizedStringKey(source.title))
                            Spacer()
                            if health.readableSources.contains(source.id) {
                                Image(systemName: "checkmark").foregroundStyle(.orange).font(.system(size: 17, weight: .semibold))
                                    .accessibilityLabel("已读取到数据")
                            } else {
                                Text(health.requested ? "暂无可读数据" : "未连接").font(.system(size: 12)).foregroundStyle(.tertiary)
                            }
                        }.padding(.horizontal, 24).frame(minHeight: 64)
                    }
                }
                if !health.available { Text("这台设备暂不支持 Apple 健康。").font(.system(size: 13)).foregroundStyle(.secondary) }
                if let error = health.error { Text(error).font(.system(size: 13)).foregroundStyle(.secondary) }
                Text("没有可读数据不一定代表未授权，也可能尚未记录对应数据。")
                    .font(.system(size: 12)).foregroundStyle(.tertiary)
                Color.clear.frame(height: 112)
            }.padding(.horizontal, 26)
        }
        .background(Palette.library.ignoresSafeArea()).foregroundStyle(Palette.ink)
        .navigationTitle("Apple 健康").navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

struct SettingsInformationView: View {
    let destination: SettingsDestination
    private var title: LocalizedStringKey {
        switch destination {
        case .faq: "FAQs"
        case .support: "联系与支持"
        case .suggestions: "功能建议"
        case .about: "关于 \(SettingsAppInfo.name)"
        case .weather: "天气来源"
        case .privacy: "隐私政策"
        case .terms: "使用条款"
        case .health: "Apple 健康"
        }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch destination {
                case .faq: SettingsFAQContent()
                case .support: SettingsSupportContent()
                case .suggestions: SettingsSuggestionContent()
                case .about: SettingsAboutContent()
                case .weather:
                    Image(systemName: "cloud.sun.fill").font(.system(size: 62)).symbolRenderingMode(.multicolor).padding(.top, 36)
                    Text("Apple Weather").font(.system(size: 23, weight: .semibold))
                    Text("查看天气数据来源、服务提供方及版权归属。").foregroundStyle(.secondary)
                    Link("查看 Apple Weather 数据来源", destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
                        .font(.system(size: 16, weight: .semibold))
                case .privacy: SettingsPrivacyContent()
                case .terms: SettingsTermsContent()
                case .health: EmptyView()
                }
                Color.clear.frame(height: 112)
            }.padding(.horizontal, 26).padding(.top, 24)
        }
        .background(Palette.library.ignoresSafeArea()).foregroundStyle(Palette.ink)
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

struct SettingsFAQContent: View {
    var body: some View {
        SettingsCardSection("常见问题") {
            SettingsFAQItem(question: "切换语言会删除单词吗？", answer: "不会。已保存的词卡保留原语言，新拍摄的词卡使用新选择的学习语言和母语。")
            SettingsDivider()
            SettingsFAQItem(question: "如何开始拍照识别？", answer: "先在“AI 图片识别”中保存服务地址、模型和密钥，然后拍摄或选择照片。识别结果可以修改后保存。")
            SettingsDivider()
            SettingsFAQItem(question: "学习提醒和复习提醒有什么区别？", answer: "学习提醒会在选定时间发送本地通知；复习提醒用于在打开应用时提醒你完成待复习词卡。")
            SettingsDivider()
            SettingsFAQItem(question: "为什么没有收到学习提醒？", answer: "请检查学习提醒开关及系统通知权限。专注模式和系统通知摘要也可能影响通知的展示时间。")
            SettingsDivider()
            SettingsFAQItem(question: "清理缓存会删除词卡吗？", answer: "不会。清理缓存只移除临时缓存，已保存的单词、贴纸、头像和昵称会保留。")
            SettingsDivider()
            SettingsFAQItem(question: "如何添加更多发音声音？", answer: "在系统设置的辅助功能中找到朗读内容与声音，下载所需语言的声音后，再返回发音声音页面选择。")
        }
    }
}

struct SettingsFAQItem: View {
    let question: LocalizedStringKey
    let answer: LocalizedStringKey
    var body: some View {
        DisclosureGroup {
            Text(answer).font(.system(size: 14)).foregroundStyle(.secondary).lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8).padding(.bottom, 12)
        } label: { Text(question).font(.system(size: 15)).padding(.vertical, 13) }
            .tint(Palette.ink).padding(.horizontal, 22)
    }
}

struct SettingsSupportContent: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "envelope.open.fill").font(.system(size: 48, weight: .light)).foregroundStyle(.secondary).padding(.top, 30)
            Text("我们很愿意听到你的声音").font(.system(size: 22, weight: .semibold))
            Text("遇到问题时，可以分享问题描述、截图和下面的应用信息。请不要在反馈中附上 API 密钥。")
                .font(.system(size: 14)).foregroundStyle(.secondary).lineSpacing(5)
            Text(verbatim: SettingsAppInfo.diagnostics).font(.system(size: 14, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading).padding(22)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22))
            ShareLink(item: SettingsAppInfo.diagnostics) { Label("分享应用信息", systemImage: "square.and.arrow.up") }
                .buttonStyle(SettingsPrimaryButtonStyle())
        }
    }
}

struct SettingsSuggestionContent: View {
    @AppStorage("settingsFeedbackDraft") private var draft = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("让下一次学习更好一点").font(.system(size: 22, weight: .semibold))
            Text("你希望添加什么功能，或者改善哪一处体验？").font(.system(size: 14)).foregroundStyle(.secondary)
            TextEditor(text: $draft).scrollContentBackground(.hidden).frame(minHeight: 200)
                .padding(15).background(Palette.surface, in: RoundedRectangle(cornerRadius: 22))
                .accessibilityLabel("功能建议").accessibilityIdentifier("suggestionTextEditor")
            ShareLink(item: "\(draft)\n\n\(SettingsAppInfo.diagnostics)") { Label("分享建议", systemImage: "square.and.arrow.up") }
                .buttonStyle(SettingsPrimaryButtonStyle()).frame(maxWidth: .infinity)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Text("草稿会自动保存在本机。").font(.system(size: 12)).foregroundStyle(.tertiary)
        }
    }
}

struct SettingsAboutContent: View {
    @Environment(\.modelContext) private var context
    @State private var message: String?
    var body: some View {
        VStack(spacing: 24) {
            Image("launch-mark").resizable().scaledToFit().frame(width: 100, height: 100).padding(.top, 25)
            Text(verbatim: SettingsAppInfo.name).font(.system(size: 28, weight: .semibold, design: .rounded))
            Text("Your world, in words.").font(.system(size: 22, design: .serif))
            Text("拍下身边的事物，把生活变成词汇。").font(.system(size: 15)).foregroundStyle(.secondary)
            SettingsBrandFooter().padding(.top, 12)
            Button("添加示例词库") {
                do { try SeedLibrary.insert(into: context); message = "示例词卡已加入词库。" }
                catch { message = error.localizedDescription }
            }.font(.system(size: 14)).padding(.top, 20)
            if let message { Text(message).font(.system(size: 13)).foregroundStyle(.secondary) }
        }
    }
}

struct SettingsPrivacyContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            SettingsInfoParagraph("你的资料和词卡", text: "昵称、头像、学习偏好和已保存的词卡保存在设备上。清理缓存不会删除这些内容。")
            SettingsInfoParagraph("照片与 AI 识别", text: "仅在你发起识别时，经过方向校正和缩小的照片才会发送至你配置的 AI 服务。请在使用前了解该服务的数据处理政策。API 密钥保存在本机钥匙串中。")
            SettingsInfoParagraph("通知", text: "学习提醒由设备本地安排。你可以随时关闭提醒或在系统设置中撤回通知权限。")
            SettingsInfoParagraph("Apple 健康", text: "健康数据只在你主动授权后读取，并仅在本机用于显示连接状态。应用不会向 Apple 健康写入数据，也不会向 AI 服务上传健康数据。")
            SettingsInfoParagraph("分享", text: "应用信息、功能建议和词卡仅在你使用系统分享功能并确认后，才会发送给你选择的接收方。")
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsTermsContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            SettingsInfoParagraph("学习用途", text: "识别、翻译和发音用于辅助语言学习。你可以在保存前检查和修改生成的词条。")
            SettingsInfoParagraph("你的内容", text: "请仅使用你有权拍摄、上传和分享的照片。使用 AI 识别时，需要遵守所配置服务的条款。")
            SettingsInfoParagraph("本地数据", text: "词卡和个人资料保存在本机。卸载应用可能移除这些内容，请分享或导出需要保留的词卡。")
            SettingsInfoParagraph("系统服务", text: "通知、健康授权、系统声音及订阅管理由 Apple 的相应系统服务提供，你可以在系统中管理相关权限与订阅。")
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsInfoParagraph: View {
    let title: LocalizedStringKey
    let text: LocalizedStringKey
    init(_ title: LocalizedStringKey, text: LocalizedStringKey) { self.title = title; self.text = text }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 18, weight: .semibold))
            Text(text).font(.system(size: 14)).foregroundStyle(.secondary).lineSpacing(6)
        }
    }
}
