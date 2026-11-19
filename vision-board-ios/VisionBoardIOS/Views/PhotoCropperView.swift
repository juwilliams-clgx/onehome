import SwiftUI

struct CropResult {
    let image: UIImage
    let state: CropState
}

/// Full-screen "pinch to fill" photo cropper, locked to a fixed aspect ratio (4:3 by
/// default for listing photos) - the native mirror of
/// vision-board-prototype/src/app/components/photo-cropper. The parent recreates this
/// view (new `image`/`initialState`) to move between photos in a batch; `onApply`
/// fires on every exit path (Prev/Next, Done, the close button) so nothing is lost
/// mid-review.
struct PhotoCropperView: View {
    let image: UIImage
    let initialState: CropState
    let stepLabel: String
    let canGoPrev: Bool
    let canGoNext: Bool

    var onApply: (CropResult) -> Void
    var onClose: () -> Void
    var onPrev: () -> Void
    var onNext: () -> Void

    @State private var workingImage: UIImage
    @State private var cropState: CropState
    @State private var naturalWidth: CGFloat
    @State private var naturalHeight: CGFloat
    @State private var showGrid = false
    @State private var gridHideTask: Task<Void, Never>?

    @GestureState private var dragTranslation: CGSize = .zero
    @GestureState private var pinchMagnification: CGFloat = 1

    init(
        image: UIImage, initialState: CropState, stepLabel: String, canGoPrev: Bool, canGoNext: Bool,
        onApply: @escaping (CropResult) -> Void, onClose: @escaping () -> Void,
        onPrev: @escaping () -> Void, onNext: @escaping () -> Void
    ) {
        self.image = image
        self.initialState = initialState
        self.stepLabel = stepLabel
        self.canGoPrev = canGoPrev
        self.canGoNext = canGoNext
        self.onApply = onApply
        self.onClose = onClose
        self.onPrev = onPrev
        self.onNext = onNext
        _workingImage = State(initialValue: image)
        _cropState = State(initialValue: initialState)
        let cg = image.cgImage
        _naturalWidth = State(initialValue: CGFloat(cg?.width ?? 1))
        _naturalHeight = State(initialValue: CGFloat(cg?.height ?? 1))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            instructions
            stage
            zoomControls
            footer
        }
        .background(Color.black)
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var instructions: some View {
        Text("Pinch to zoom · drag to reposition the photo")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
    }

    private var header: some View {
        HStack {
            Button(action: applyAndClose) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Crop for listing").font(.subheadline.bold())
                if !stepLabel.isEmpty {
                    Text(stepLabel).font(.caption).foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            Button(action: rotate) {
                Image(systemName: "rotate.right")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 4)
        .buttonStyle(.plain)
    }

    // MARK: - Stage

    private var stage: some View {
        HStack(spacing: 8) {
            navButton(systemImage: "chevron.left", enabled: canGoPrev, action: applyAndGoPrev)

            GeometryReader { geo in
                let frameSize = geo.size
                let live = liveState(frameSize: frameSize)
                ZStack {
                    Image(uiImage: workingImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: naturalWidth, height: naturalHeight)
                        .scaleEffect(live.scale)
                        .offset(x: live.offsetX, y: live.offsetY)
                        .frame(width: frameSize.width, height: frameSize.height)
                        .clipped()

                    if showGrid {
                        GridOverlay()
                    }

                    Rectangle()
                        .strokeBorder(.white.opacity(0.9), lineWidth: 1)
                }
                .contentShape(Rectangle())
                .gesture(combinedGesture(frameSize: frameSize))
                .onTapGesture(count: 2) { toggleZoom(frameSize: frameSize) }
            }
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .frame(maxWidth: 640)

            navButton(systemImage: "chevron.right", enabled: canGoNext, action: applyAndGoNext)
        }
        .padding(.vertical, 12)
    }

    private func navButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 36, height: 36)
                .background(.black.opacity(0.4), in: Circle())
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0)
        .disabled(!enabled)
        .frame(width: 36)
    }

    /// Resolves the committed crop state plus any in-flight gesture into actual
    /// scale/offset for this specific frame's rendered point size.
    private func liveState(frameSize: CGSize) -> CropMath.PixelCrop {
        var state = cropState
        if pinchMagnification != 1 {
            state = CropMath.zoomAnchored(
                state, newZoom: state.zoom * pinchMagnification, focalX: 0, focalY: 0,
                naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameSize.width, frameHeight: frameSize.height
            )
        }
        var px = CropMath.toPixelCrop(state, naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameSize.width, frameHeight: frameSize.height)
        if dragTranslation != .zero {
            px = CropMath.PixelCrop(scale: px.scale, offsetX: px.offsetX + dragTranslation.width, offsetY: px.offsetY + dragTranslation.height)
            px = CropMath.clampPixel(px, naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameSize.width, frameHeight: frameSize.height)
        }
        return px
    }

    private func combinedGesture(frameSize: CGSize) -> some Gesture {
        SimultaneousGesture(
            DragGesture()
                .updating($dragTranslation) { value, state, _ in
                    state = value.translation
                    flashGrid()
                }
                .onEnded { value in
                    cropState = CropMath.panned(
                        cropState, dx: value.translation.width, dy: value.translation.height,
                        naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameSize.width, frameHeight: frameSize.height
                    )
                },
            MagnificationGesture()
                .updating($pinchMagnification) { value, state, _ in
                    state = value
                    flashGrid()
                }
                .onEnded { value in
                    cropState = CropMath.zoomAnchored(
                        cropState, newZoom: cropState.zoom * value, focalX: 0, focalY: 0,
                        naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameSize.width, frameHeight: frameSize.height
                    )
                }
        )
    }

    private func toggleZoom(frameSize: CGSize) {
        let mid: CGFloat = (1 + CropMath.maxZoomMultiplier) / 2
        let target: CGFloat = cropState.zoom > mid ? 1 : mid
        withAnimation(.easeOut(duration: 0.2)) {
            cropState = CropMath.zoomAnchored(
                cropState, newZoom: target, focalX: 0, focalY: 0,
                naturalWidth: naturalWidth, naturalHeight: naturalHeight, frameWidth: frameSize.width, frameHeight: frameSize.height
            )
        }
    }

    private func flashGrid() {
        showGrid = true
        gridHideTask?.cancel()
        gridHideTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled { showGrid = false }
        }
    }

    // MARK: - Zoom controls

    private var zoomControls: some View {
        HStack(spacing: 12) {
            Button {
                nudgeZoom(by: -0.4)
            } label: {
                Image(systemName: "minus.magnifyingglass").frame(width: 36, height: 36).background(.white.opacity(0.1), in: Circle())
            }

            Slider(value: Binding(
                get: { cropState.zoom },
                set: { newValue in cropState.zoom = min(CropMath.maxZoomMultiplier, max(1, newValue)) }
            ), in: 1...CropMath.maxZoomMultiplier)
            .tint(.white)

            Button {
                nudgeZoom(by: 0.4)
            } label: {
                Image(systemName: "plus.magnifyingglass").frame(width: 36, height: 36).background(.white.opacity(0.1), in: Circle())
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
        .frame(maxWidth: 420)
    }

    private func nudgeZoom(by delta: CGFloat) {
        cropState.zoom = min(CropMath.maxZoomMultiplier, max(1, cropState.zoom + delta))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Reset") { cropState = .standard }
                .foregroundStyle(.white.opacity(0.75))

            Spacer()

            Button(action: applyAndClose) {
                Label("Use this crop", systemImage: "checkmark")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(Color(red: 0.075, green: 0.478, blue: 0.561), in: Capsule())
            }
        }
        .padding()
        .background(.black)
    }

    // MARK: - Actions

    private func rotate() {
        let oldWidth = naturalWidth
        let oldHeight = naturalHeight
        workingImage = PhotoRaster.rotatedClockwise(workingImage)
        let cg = workingImage.cgImage
        naturalWidth = CGFloat(cg?.width ?? Int(oldHeight))
        naturalHeight = CGFloat(cg?.height ?? Int(oldWidth))
        cropState = .standard
    }

    private func exportedResult() -> CropResult {
        let exported = PhotoRaster.exportCrop(image: workingImage, state: cropState)
        return CropResult(image: exported, state: cropState)
    }

    private func applyAndClose() {
        onApply(exportedResult())
        onClose()
    }

    private func applyAndGoPrev() {
        onApply(exportedResult())
        onPrev()
    }

    private func applyAndGoNext() {
        onApply(exportedResult())
        onNext()
    }
}

private struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                for i in 1...2 {
                    let x = geo.size.width * CGFloat(i) / 3
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    let y = geo.size.height * CGFloat(i) / 3
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(.white.opacity(0.55), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}
