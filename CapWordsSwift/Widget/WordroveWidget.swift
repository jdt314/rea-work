import SwiftUI
import WidgetKit
import UIKit

struct WordroveWidgetEntry: TimelineEntry {
    let date: Date
    let word: WidgetWordSnapshot?
}

struct WordroveWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WordroveWidgetEntry {
        WordroveWidgetEntry(date: .now, word: WidgetWordSnapshot(name: "Donut", meaning: "甜甜圈", wordCount: 1, imageData: nil))
    }
    func getSnapshot(in context: Context, completion: @escaping (WordroveWidgetEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : load())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WordroveWidgetEntry>) -> Void) {
        completion(Timeline(entries: [load()], policy: .after(.now.addingTimeInterval(3600))))
    }
    private func load() -> WordroveWidgetEntry {
        let storage = UserDefaults(suiteName: WidgetWordSnapshot.suite)
        let word = storage?.data(forKey: WidgetWordSnapshot.storageKey).flatMap { try? JSONDecoder().decode(WidgetWordSnapshot.self, from: $0) }
        return WordroveWidgetEntry(date: .now, word: word)
    }
}

struct WordroveWidgetView: View {
    let entry: WordroveWidgetEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        Group {
            if family == .systemMedium {
                HStack(spacing: 16) {
                    WordroveWidgetArtwork(imageData: entry.word?.imageData).frame(maxWidth: .infinity)
                    WordroveWidgetCaption(word: entry.word, medium: true).frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    WordroveWidgetArtwork(imageData: entry.word?.imageData).frame(maxWidth: .infinity, maxHeight: .infinity)
                    WordroveWidgetCaption(word: entry.word, medium: false)
                }
            }
        }
        .foregroundStyle(Color(red: 0.14, green: 0.17, blue: 0.19))
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 1, green: 0.80, blue: 0.45), Color(red: 1, green: 0.67, blue: 0.26)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .widgetURL(URL(string: "wordrove://library"))
    }
}

struct WordroveWidgetArtwork: View {
    let imageData: Data?
    var body: some View {
        if let data = imageData, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFit()
        } else {
            Image(systemName: "camera.aperture").font(.system(size: 56, weight: .light)).padding(10)
        }
    }
}

struct WordroveWidgetCaption: View {
    let word: WidgetWordSnapshot?
    let medium: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let word, !word.name.isEmpty {
                Text(verbatim: word.name).font(.system(size: medium ? 24 : 17, weight: .bold, design: .rounded)).lineLimit(2)
                Text(verbatim: word.meaning).font(.system(size: 13)).lineLimit(1)
                if medium {
                    Text("已经收集 \(word.wordCount) 个单词").font(.system(size: 11)).opacity(0.65).padding(.top, 12)
                }
            } else {
                Text("拍下第一个单词").font(.system(size: 17, weight: .semibold))
                Text("让生活成为词汇").font(.system(size: 12)).opacity(0.65)
            }
        }
    }
}

struct WordroveWordWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WordroveWordWidget", provider: WordroveWidgetProvider()) { WordroveWidgetView(entry: $0) }
            .configurationDisplayName("单词卡片")
            .description("在主屏幕上遇见你最新收集的单词。")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct WordroveWidgets: WidgetBundle {
    var body: some Widget { WordroveWordWidget() }
}
