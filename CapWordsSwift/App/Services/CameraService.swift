import AVFoundation
import SwiftUI
import Observation

enum CameraError: LocalizedError {
    case unavailable, captureFailed
    var errorDescription: String? {
        switch self {
        case .unavailable: "相机暂时不可用，你可以从相册选择图片。"
        case .captureFailed: "照片拍摄失败，请重试。"
        }
    }
}

// session 的配置和所有可变状态仅在 queue 上访问。
final class CameraEngine: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "dev.reawork.camera", qos: .userInitiated)
    private let output = AVCapturePhotoOutput()
    private var continuation: CheckedContinuation<Data, any Error>?
    private var configured = false
    private var device: AVCaptureDevice?

    func start() async throws {
        try await withCheckedThrowingContinuation { (completion: CheckedContinuation<Void, any Error>) in
            queue.async { [self] in
                do {
                    if !configured {
                        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                            throw CameraError.unavailable
                        }
                        let input = try AVCaptureDeviceInput(device: camera)
                        session.beginConfiguration()
                        session.sessionPreset = .photo
                        guard session.canAddInput(input), session.canAddOutput(output) else {
                            session.commitConfiguration(); throw CameraError.unavailable
                        }
                        session.addInput(input); session.addOutput(output)
                        session.commitConfiguration()
                        device = camera
                        configured = true
                    }
                    if !session.isRunning { session.startRunning() }
                    completion.resume()
                } catch { completion.resume(throwing: error) }
            }
        }
    }

    func stop() { queue.async { [self] in if session.isRunning { session.stopRunning() } } }

    func capture(flash: Bool) async throws -> Data {
        try await withCheckedThrowingContinuation { completion in
            queue.async { [self] in
                guard configured, session.isRunning, continuation == nil else {
                    completion.resume(throwing: CameraError.captureFailed); return
                }
                continuation = completion
                let settings = AVCapturePhotoSettings()
                if device?.hasFlash == true { settings.flashMode = flash ? .on : .off }
                output.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func focus(at point: CGPoint) {
        queue.async { [self] in
            guard let device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    if device.isFocusModeSupported(.autoFocus) { device.focusMode = .autoFocus }
                }
                device.unlockForConfiguration()
            } catch { /* 对焦失败不终止取景。 */ }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        let data = photo.fileDataRepresentation()
        queue.async { [self] in
            defer { continuation = nil }
            if let error { continuation?.resume(throwing: error) }
            else if let data { continuation?.resume(returning: data) }
            else { continuation?.resume(throwing: CameraError.captureFailed) }
        }
    }
}

@MainActor @Observable
final class CameraModel {
    let engine = CameraEngine()
    var authorized = false
    var ready = false
    var denied = false
    var error: String?
    var flash = false

    func start() async {
        #if targetEnvironment(simulator)
        return
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: authorized = true
        case .notDetermined: authorized = await AVCaptureDevice.requestAccess(for: .video)
        default: authorized = false
        }
        guard authorized else { denied = true; return }
        do { try await engine.start(); ready = true } catch { self.error = error.localizedDescription }
        if Task.isCancelled { engine.stop(); ready = false }
        #endif
    }
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    var onFocus: ((CGPoint) -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }
    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        onFocus?(previewLayer.captureDevicePointConverted(fromLayerPoint: gesture.location(in: self)))
    }
}

struct CameraPreview: UIViewRepresentable {
    let engine: CameraEngine
    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = engine.session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.onFocus = { engine.focus(at: $0) }
        return view
    }
    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}
