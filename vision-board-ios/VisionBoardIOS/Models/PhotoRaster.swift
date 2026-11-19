import UIKit

/// Raster helpers for the photo cropper: producing the actual cropped pixels for a
/// grid thumbnail or the final "saved" photo, given a normalized `CropState`.
/// Mirrors crop-math.ts's `exportCrop` (canvas `drawImage` with a source rect), using
/// `CGImage.cropping` + `UIGraphicsImageRenderer` instead of a canvas.
enum PhotoRaster {
    static func exportCrop(
        image: UIImage,
        state: CropState,
        outputSize: CGSize = CGSize(width: 1200, height: 900)
    ) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let naturalWidth = CGFloat(cgImage.width)
        let naturalHeight = CGFloat(cgImage.height)
        let rect = CropMath.sourceRect(
            for: state, naturalWidth: naturalWidth, naturalHeight: naturalHeight,
            frameWidth: outputSize.width, frameHeight: outputSize.height
        )
        let cropRect = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
            .intersection(CGRect(x: 0, y: 0, width: naturalWidth, height: naturalHeight))
        guard !cropRect.isEmpty, let cropped = cgImage.cropping(to: cropRect) else { return image }

        let renderer = UIGraphicsImageRenderer(size: outputSize)
        return renderer.image { _ in
            UIImage(cgImage: cropped).draw(in: CGRect(origin: .zero, size: outputSize))
        }
    }

    /// Rotates 90° clockwise, baking the rotation into a new image - the cropper
    /// resets to that image's own default crop afterward, mirroring the web port's
    /// canvas-bake-then-reset approach rather than composing a live rotation transform.
    static func rotatedClockwise(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let newSize = CGSize(width: cgImage.height, height: cgImage.width)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { ctx in
            ctx.cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            ctx.cgContext.rotate(by: .pi / 2)
            let original = UIImage(cgImage: cgImage)
            original.draw(in: CGRect(x: -original.size.width / 2, y: -original.size.height / 2, width: original.size.width, height: original.size.height))
        }
    }
}
