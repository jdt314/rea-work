import Photos
import UIKit

@MainActor
enum StickerExport {
    static func image(for word: Word) -> UIImage? {
        if let data = word.imageData { return UIImage(data: data) }
        if let asset = word.assetName { return UIImage(named: asset) }
        return nil
    }
    static func save(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw ExportError.permission }
        guard let data = image.pngData() else { throw RecognitionError.encodingFailed }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
        }
    }
    enum ExportError: LocalizedError {
        case permission
        var errorDescription: String? { "请在系统设置中允许保存图片到相册。" }
    }
}
