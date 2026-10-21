import Foundation
import UIKit
import WidgetKit

@MainActor
enum WordWidgetBridge {
    static func publish(words: [Word]) {
        // Debug capture libraries are isolated and must never overwrite the user's widget.
        #if DEBUG
        if LaunchOptions.arguments.contains("--uitesting") { return }
        #endif
        let latest = words.first
        let image = latest?.imageData.flatMap(UIImage.init(data:)) ?? latest?.assetName.flatMap(UIImage.init(named:))
        let thumbnail = image?.preparingThumbnail(of: CGSize(width: 240, height: 240))?.pngData()
        let snapshot = WidgetWordSnapshot(name: latest?.name ?? "", meaning: latest?.meaning ?? "",
                                          wordCount: words.count, imageData: thumbnail)
        guard let storage = UserDefaults(suiteName: WidgetWordSnapshot.suite),
              let data = try? JSONEncoder().encode(snapshot),
              data != storage.data(forKey: WidgetWordSnapshot.storageKey) else { return }
        storage.set(data, forKey: WidgetWordSnapshot.storageKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "WordroveWordWidget")
    }
}
