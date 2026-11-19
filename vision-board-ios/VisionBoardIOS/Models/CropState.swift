import CoreGraphics
import Foundation

/// Mirrors vision-board-prototype/src/app/components/photo-cropper/crop-math.ts:
/// a photo is cropped by scaling it to fill a fixed-aspect frame (the
/// Instagram/Airbnb "pinch to fill" pattern, not a resizable selection box) and
/// panning it behind that frame. Stored NORMALIZED - independent of the frame's
/// actual rendered point size - so the same saved crop renders identically
/// whether it's a small grid thumbnail or the full-screen live editor.
struct CropState: Equatable, Codable {
    /// 1 = default cover-fit (no extra zoom). Larger values zoom in further.
    var zoom: CGFloat = 1
    /// Pan as a fraction of frame width, e.g. 0.1 = shifted right by 10% of the frame.
    var offsetXFrac: CGFloat = 0
    /// Pan as a fraction of frame height.
    var offsetYFrac: CGFloat = 0

    static let standard = CropState()
}

enum CropMath {
    static let maxZoomMultiplier: CGFloat = 4
    static let nearRatioTolerance: CGFloat = 0.03

    static func isNearAspectRatio(naturalWidth: CGFloat, naturalHeight: CGFloat, target: CGFloat) -> Bool {
        guard naturalWidth > 0, naturalHeight > 0 else { return false }
        let ratio = naturalWidth / naturalHeight
        return abs(ratio / target - 1) <= nearRatioTolerance
    }

    private static func coverFitScale(naturalWidth: CGFloat, naturalHeight: CGFloat, frameWidth: CGFloat, frameHeight: CGFloat) -> CGFloat {
        guard naturalWidth > 0, naturalHeight > 0 else { return 1 }
        return max(frameWidth / naturalWidth, frameHeight / naturalHeight)
    }

    struct PixelCrop {
        var scale: CGFloat
        var offsetX: CGFloat
        var offsetY: CGFloat
    }

    /// Converts a normalized, frame-size-independent state into actual point values for one specific rendered frame.
    static func toPixelCrop(
        _ state: CropState, naturalWidth: CGFloat, naturalHeight: CGFloat, frameWidth: CGFloat, frameHeight: CGFloat
    ) -> PixelCrop {
        let scale = coverFitScale(naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight) * state.zoom
        return PixelCrop(scale: scale, offsetX: state.offsetXFrac * frameWidth, offsetY: state.offsetYFrac * frameHeight)
    }

    private static func fromPixelCrop(
        _ px: PixelCrop, naturalWidth: CGFloat, naturalHeight: CGFloat, frameWidth: CGFloat, frameHeight: CGFloat
    ) -> CropState {
        let minScale = coverFitScale(naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight)
        return CropState(
            zoom: minScale > 0 ? px.scale / minScale : 1,
            offsetXFrac: frameWidth > 0 ? px.offsetX / frameWidth : 0,
            offsetYFrac: frameHeight > 0 ? px.offsetY / frameHeight : 0
        )
    }

    private static func maxPixelOffset(naturalSize: CGFloat, frameSize: CGFloat, scale: CGFloat) -> CGFloat {
        max(0, (naturalSize * scale - frameSize) / 2)
    }

    /// Clamps raw pixel values directly - used by live gesture previews that only need
    /// a renderable scale/offset, not a round-trip through the normalized state.
    static func clampPixel(
        _ px: PixelCrop, naturalWidth: CGFloat, naturalHeight: CGFloat, frameWidth: CGFloat, frameHeight: CGFloat
    ) -> PixelCrop {
        let maxX = maxPixelOffset(naturalSize: naturalWidth, frameSize: frameWidth, scale: px.scale)
        let maxY = maxPixelOffset(naturalSize: naturalHeight, frameSize: frameHeight, scale: px.scale)
        return PixelCrop(
            scale: px.scale,
            offsetX: min(maxX, max(-maxX, px.offsetX)),
            offsetY: min(maxY, max(-maxY, px.offsetY))
        )
    }

    /// Clamps a normalized state so the image never shows a gap or an edge inside the frame.
    static func clamp(
        _ state: CropState, naturalWidth: CGFloat, naturalHeight: CGFloat, frameWidth: CGFloat, frameHeight: CGFloat
    ) -> CropState {
        let zoom = min(maxZoomMultiplier, max(1, state.zoom))
        let px = toPixelCrop(
            CropState(zoom: zoom, offsetXFrac: state.offsetXFrac, offsetYFrac: state.offsetYFrac),
            naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight
        )
        let clampedPx = clampPixel(px, naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight)
        return fromPixelCrop(clampedPx, naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight)
    }

    /// Zooms to `newZoom`, keeping the image point under focal point (relative to
    /// frame center, in this frame's current point size) fixed on screen.
    static func zoomAnchored(
        _ state: CropState, newZoom: CGFloat, focalX: CGFloat, focalY: CGFloat,
        naturalWidth: CGFloat, naturalHeight: CGFloat, frameWidth: CGFloat, frameHeight: CGFloat
    ) -> CropState {
        let px = toPixelCrop(state, naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight)
        let newScale = coverFitScale(naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight) * newZoom
        let ratio = px.scale > 0 ? newScale / px.scale : 1
        let offsetX = focalX * (1 - ratio) + px.offsetX * ratio
        let offsetY = focalY * (1 - ratio) + px.offsetY * ratio
        let normalized = fromPixelCrop(
            PixelCrop(scale: newScale, offsetX: offsetX, offsetY: offsetY),
            naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight
        )
        return clamp(normalized, naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight)
    }

    /// Pans by a raw point delta measured against this frame's current render size.
    static func panned(
        _ state: CropState, dx: CGFloat, dy: CGFloat,
        naturalWidth: CGFloat, naturalHeight: CGFloat, frameWidth: CGFloat, frameHeight: CGFloat
    ) -> CropState {
        let px = toPixelCrop(state, naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight)
        let moved = PixelCrop(scale: px.scale, offsetX: px.offsetX + dx, offsetY: px.offsetY + dy)
        return clamp(
            fromPixelCrop(moved, naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight),
            naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight
        )
    }

    struct SourceRect {
        var x: CGFloat
        var y: CGFloat
        var width: CGFloat
        var height: CGFloat
    }

    /// Natural-image-space rectangle currently visible inside the frame, for raster export.
    static func sourceRect(
        for state: CropState, naturalWidth: CGFloat, naturalHeight: CGFloat, frameWidth: CGFloat, frameHeight: CGFloat
    ) -> SourceRect {
        let px = toPixelCrop(state, naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameWidth, frameHeight: frameHeight)
        let w = frameWidth / px.scale
        let h = frameHeight / px.scale
        let x = naturalWidth / 2 - (px.offsetX + frameWidth / 2) / px.scale
        let y = naturalHeight / 2 - (px.offsetY + frameHeight / 2) / px.scale
        return SourceRect(x: x, y: y, width: w, height: h)
    }
}
