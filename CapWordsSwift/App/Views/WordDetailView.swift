import SwiftUI
import SwiftData

struct WordDetailView: View {
    @Bindable var word: Word
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var editing = false
    @State private var deleting = false
    @State private var notice: String?
    @State private var exporting = false

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle().fill(.yellow.opacity(0.15)).frame(width: 220, height: 220).blur(radius: 35)
                            StickerArtwork(data: word.imageData, asset: word.assetName).frame(width: 215, height: 205)
                                .rotationEffect(.degrees(-4))
                        }.padding(.top, 16)
                        VStack(spacing: 9) {
                            HStack(spacing: 10) {
                                StickerLabel(text: word.name, size: 32)
                                Button { SpeechService.shared.speak(word.name, language: word.languageCode) } label: {
                                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 20)).foregroundStyle(Palette.ink)
                                }.accessibilityLabel("朗读单词")
                            }
                            Text(word.meaning).font(.system(size: 19)).foregroundStyle(Palette.ink)
                            if !word.pronunciation.isEmpty { Text(word.pronunciation).font(.system(size: 14)).foregroundStyle(.secondary) }
                        }
                        if !word.example.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("生活中的一句话").font(.system(size: 12)).foregroundStyle(.secondary)
                                    Spacer()
                                    Button { SpeechService.shared.speak(word.example, language: word.languageCode) } label: {
                                        Image(systemName: "speaker.wave.2").foregroundStyle(Palette.lilac)
                                    }.accessibilityLabel("朗读例句")
                                }
                                Text(word.example).font(.system(size: 17, weight: .medium)).foregroundStyle(Palette.ink)
                                Text(word.exampleMeaning).font(.system(size: 14)).foregroundStyle(.secondary)
                            }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
                                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22))
                        }
                        HStack(spacing: 26) {
                            VStack(spacing: 8) {
                                RoundButton(symbol: "doc.on.doc", label: "复制贴纸") {
                                    guard let image = StickerExport.image(for: word) else { return }
                                    UIPasteboard.general.image = image; notice = "已复制，可以粘贴到其他应用。"
                                }
                                Text("复制").font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            VStack(spacing: 8) {
                                RoundButton(symbol: "square.and.arrow.down", label: "保存贴纸到相册") {
                                    guard !exporting, let image = StickerExport.image(for: word) else { return }
                                    exporting = true
                                    Task {
                                        defer { exporting = false }
                                        do { try await StickerExport.save(image); notice = "贴纸已保存到相册。" }
                                        catch { notice = error.localizedDescription }
                                    }
                                }.disabled(exporting)
                                Text("保存图片").font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            VStack(spacing: 8) {
                                RoundButton(symbol: "pencil", label: "编辑单词") { editing = true }
                                Text("编辑").font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                        }
                        Text("\(word.category) · \(word.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    }.padding(.horizontal, 26).padding(.bottom, 40)
                }.scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("完成") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { deleting = true } label: { Image(systemName: "trash").foregroundStyle(Palette.muted) }.accessibilityLabel("删除单词")
                }
            }
            .sheet(isPresented: $editing) {
                WordEditor(name: word.name, meaning: word.meaning, pronunciation: word.pronunciation) { name, meaning, pronunciation in
                    if name != word.name { word.example = ""; word.exampleMeaning = "" }
                    word.name = name; word.meaning = meaning; word.pronunciation = pronunciation
                    do { try context.save() } catch { context.rollback(); notice = error.localizedDescription }
                }
            }
            .confirmationDialog("删除这个单词？删除后无法恢复。", isPresented: $deleting, titleVisibility: .visible) {
                Button("删除单词", role: .destructive) {
                    context.delete(word)
                    do { try context.save(); dismiss() } catch { context.rollback(); notice = error.localizedDescription }
                }
            }
            .alert("提示", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("知道了", role: .cancel) { notice = nil }
            } message: { Text(notice ?? "") }
            .onDisappear { SpeechService.shared.stop() }
        }
    }
}
