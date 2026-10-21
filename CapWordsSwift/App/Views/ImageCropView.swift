import SwiftUI

enum ImageCropRenderer {
    static func render(image: UIImage, viewport: CGFloat, zoom: CGFloat, offset: CGSize) -> Data? {
        guard viewport > 0, image.size.width > 0, image.size.height > 0 else { return nil }
        let imageScale = max(viewport / image.size.width, viewport / image.size.height) * max(1, zoom)
        let width = image.size.width * imageScale, height = image.size.height * imageScale
        let dx = min(max(offset.width, -(width - viewport) / 2), (width - viewport) / 2)
        let dy = min(max(offset.height, -(height - viewport) / 2), (height - viewport) / 2)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 1000, height: 1000), format: format).image { ctx in
            ctx.cgContext.scaleBy(x: 1000 / viewport, y: 1000 / viewport)
            image.draw(in: CGRect(x: (viewport - width) / 2 + dx, y: (viewport - height) / 2 + dy, width: width, height: height))
        }.jpegData(compressionQuality: 0.93)
    }
}

struct ImageCropView: View {
    let data: Data
    let onCrop: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1
    @State private var baseZoom: CGFloat = 1
    @State private var offset = CGSize.zero
    @State private var baseOffset = CGSize.zero
    @State private var error = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let side = proxy.size.width - 32
                VStack(spacing: 28) {
                    Spacer()
                    if let image = UIImage(data: data) {
                        ZStack {
                            Image(uiImage: image).resizable().scaledToFill()
                                .frame(width: side, height: side).scaleEffect(zoom).offset(offset)
                            Rectangle().stroke(.white.opacity(0.8), lineWidth: 1)
                                .frame(width: side / 3, height: side)
                            Rectangle().stroke(.white.opacity(0.8), lineWidth: 1)
                                .frame(width: side, height: side / 3)
                        }
                        .frame(width: side, height: side).clipped().contentShape(Rectangle())
                        .gesture(MagnifyGesture().onChanged { value in
                            zoom = min(max(baseZoom * value.magnification, 1), 4)
                            offset = clamped(offset, image: image, side: side)
                        }.onEnded { _ in baseZoom = zoom; baseOffset = offset })
                        .simultaneousGesture(DragGesture().onChanged { value in
                            offset = clamped(CGSize(width: baseOffset.width + value.translation.width,
                                                    height: baseOffset.height + value.translation.height), image: image, side: side)
                        }.onEnded { _ in baseOffset = offset })
                        Text("双指缩放，拖动照片选择主体").font(.system(size: 13)).foregroundStyle(.secondary)
                        Button("使用这张照片") {
                            if let cropped = ImageCropRenderer.render(image: image, viewport: side, zoom: zoom, offset: offset) {
                                onCrop(cropped); dismiss()
                            } else { error = true }
                        }.buttonStyle(.borderedProminent).tint(Palette.lilac)
                    }
                    Spacer()
                }.frame(maxWidth: .infinity)
            }.background(Palette.paper)
            .navigationTitle("裁剪照片").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
            .alert("照片无法裁剪，请重新选择。", isPresented: $error) { Button("知道了", role: .cancel) { } }
        }
    }

    private func clamped(_ offset: CGSize, image: UIImage, side: CGFloat) -> CGSize {
        let scale = max(side / image.size.width, side / image.size.height) * zoom
        let maxX = max(0, (image.size.width * scale - side) / 2)
        let maxY = max(0, (image.size.height * scale - side) / 2)
        return CGSize(width: min(max(offset.width, -maxX), maxX), height: min(max(offset.height, -maxY), maxY))
    }
}
