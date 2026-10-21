// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CapWordsCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "CapWordsCore", targets: ["CapWordsCore"])],
    targets: [
        .target(name: "CapWordsCore", path: "App", exclude: ["CapWordsApp.swift", "Info.plist", "Resources", "Views",
                                                               "Services/CameraService.swift", "Services/AIRecognitionSettings.swift", "Services/RecognitionService.swift",
                                                               "Services/SpeechService.swift", "Services/StickerExport.swift",
                                                               "Services/SettingsServices.swift", "Services/WordWidgetBridge.swift", "CapWordsSwift.entitlements"],
                sources: ["Models", "Services/SeedLibrary.swift"]),
        .testTarget(name: "CapWordsCoreTests", dependencies: ["CapWordsCore"], path: "CoreTests")
    ],
    swiftLanguageModes: [.v6]
)
