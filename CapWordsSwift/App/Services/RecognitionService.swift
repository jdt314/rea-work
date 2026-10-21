import Foundation
import Vision
import UIKit
import CoreImage

struct RecognitionResult: Sendable {
    var imageData: Data
    var originalData: Data
    var name: String
    var meaning: String
    var pronunciation: String
    var example: String
    var exampleMeaning: String
    var category: String
    var languageCode: String
    var isScene: Bool
    var needsNaming: Bool
    var subjectRect: CGRect
}

enum RecognitionError: LocalizedError {
    case invalidImage, encodingFailed
    var errorDescription: String? {
        switch self {
        case .invalidImage: "这张图片无法读取，请重新选择。"
        case .encodingFailed: "贴纸生成失败，请重试。"
        }
    }
}

actor RecognitionService {
    static let shared = RecognitionService()
    private let context = CIContext()

    func prepare(data: Data, language: LearningLanguage, scene: Bool = false,
                 onNormalized: (@Sendable (Data) async -> Void)? = nil) async throws -> RecognitionResult {
        try Task.checkCancellation()
        guard let input = UIImage(data: data) else { throw RecognitionError.invalidImage }
        // 统一方向并限制长边，防止高像素照片产生过量内存占用。
        let scale = min(1, 1600 / max(input.size.width, input.size.height))
        let size = CGSize(width: input.size.width * scale, height: input.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let normalized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            input.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let cgImage = normalized.cgImage, let original = normalized.jpegData(compressionQuality: 0.9) else {
            throw RecognitionError.invalidImage
        }
        // 图片规范化后立即启动网络，不让 Vision 分割占用云端请求的等待时间。
        await onNormalized?(original)
        try Task.checkCancellation()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var sticker = normalized
        var isScene = scene
        var subjectRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        if !scene {
            do {
                let request = VNGenerateForegroundInstanceMaskRequest()
                try handler.perform([request])
                if let observation = request.results?.first, !observation.allInstances.isEmpty {
                    let pixelBuffer = try observation.generateMaskedImage(ofInstances: observation.allInstances,
                                                                          from: handler, croppedToInstancesExtent: false)
                    let image = CIImage(cvPixelBuffer: pixelBuffer)
                    guard let full = context.createCGImage(image, from: image.extent) else { throw RecognitionError.encodingFailed }
                    let bounds = AlphaGeometry.bounds(of: full)
                    if bounds.width > 2, bounds.height > 2, let cropped = full.cropping(to: bounds) {
                        sticker = UIImage(cgImage: cropped)
                        subjectRect = CGRect(x: bounds.minX / CGFloat(full.width), y: bounds.minY / CGFloat(full.height),
                                             width: bounds.width / CGFloat(full.width), height: bounds.height / CGFloat(full.height))
                    } else { isScene = true }
                } else { isScene = true }
            } catch is CancellationError { throw CancellationError() }
            catch { isScene = true }
        }
        try Task.checkCancellation()
        guard let output = sticker.pngData() else { throw RecognitionError.encodingFailed }
        return RecognitionResult(imageData: output, originalData: original, name: "",
                                 meaning: "", pronunciation: "", example: "", exampleMeaning: "",
                                 category: "日常", languageCode: language.rawValue,
                                 isScene: isScene, needsNaming: true, subjectRect: subjectRect)
    }

    func recognize(data: Data, language: LearningLanguage, scene: Bool = false) async throws -> RecognitionResult {
        var result = try await prepare(data: data, language: language, scene: scene)
        let word = try await AIRecognitionClient().recognize(image: result.originalData, languageCode: language.rawValue,
                                                            scene: scene, configuration: AIRecognitionSettings.load(),
                                                            nativeLanguageCode: UserDefaults.standard.string(forKey: "nativeLanguage") ?? "zh-CN")
        result.apply(word)
        return result
    }
}

extension RecognitionResult {
    mutating func apply(_ word: AIWordEntry) {
        name = word.name; meaning = word.meaning; pronunciation = word.pronunciation
        example = word.example; exampleMeaning = word.exampleMeaning; category = word.category
        languageCode = word.languageCode; needsNaming = word.needsNaming
    }
}
