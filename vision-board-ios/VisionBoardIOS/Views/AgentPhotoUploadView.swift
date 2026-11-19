import PhotosUI
import SwiftUI

/// Route value carrying which listing's photos are being uploaded/cropped.
struct AgentPhotoUploadRoute: Hashable {
    let listingID: String
}

private let targetAspectRatio: CGFloat = 4.0 / 3.0
/// Caps how many of a listing's existing MLS photos preload into the demo batch, so the screen opens fast.
private let existingPhotoLimit = 6

/// One photo in the current upload batch: its working (possibly rotated) source
/// image, its saved crop, and review status. Mirrors
/// vision-board-prototype/.../agent-photo-upload.ts's `WorkingPhoto`.
private struct WorkingPhoto: Identifiable {
    let id: String
    var sourceImage: UIImage
    var naturalWidth: CGFloat
    var naturalHeight: CGFloat
    var state: CropState
    var preview: UIImage
    /// True once the agent has opened this photo in the cropper and confirmed a crop (even the untouched default).
    var reviewed: Bool
    /// True when the original aspect ratio was far enough from 4:3 that it was auto-cropped and deserves a look.
    var needsReview: Bool
    var isCover: Bool
    let sortIndex: Int
}

/// Native mirror of vision-board-prototype's AgentPhotoUploadComponent: an agent
/// reviews a listing's photos (preloaded here) plus anything they add, each
/// auto-cropped to 4:3 by default with a tap-to-fine-tune cropper, then saves.
struct AgentPhotoUploadView: View {
    let listing: Listing

    @Environment(ToastCenter.self) private var toast
    @Environment(\.dismiss) private var dismiss

    @State private var photos: [WorkingPhoto] = []
    @State private var activeIndex: Int?
    @State private var loadingCount = 0
    @State private var saving = false
    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var nextSortIndex = 0

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var needsReviewCount: Int { photos.filter { $0.needsReview && !$0.reviewed }.count }

    var body: some View {
        ScrollView {
            introText
            statusBanner
            addPhotosRow
            photoGrid
        }
        .navigationTitle(listing.address)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { footer }
        .task { loadExistingPhotos() }
        .onChange(of: pickerSelection) { _, items in
            ingest(pickerItems: items)
            pickerSelection = []
        }
        .fullScreenCover(isPresented: Binding(
            get: { activeIndex != nil },
            set: { if !$0 { activeIndex = nil } }
        )) {
            if let index = activeIndex, photos.indices.contains(index) {
                let photo = photos[index]
                PhotoCropperView(
                    image: photo.sourceImage,
                    initialState: photo.state,
                    stepLabel: "Photo \(index + 1) of \(photos.count)",
                    canGoPrev: index > 0,
                    canGoNext: index < photos.count - 1,
                    onApply: { result in applyCrop(result, at: index) },
                    onClose: { activeIndex = nil },
                    onPrev: { activeIndex = index - 1 },
                    onNext: { activeIndex = index + 1 }
                )
                .id(photo.id)
            }
        }
    }

    // MARK: - Status banner

    private var introText: some View {
        Text("Every photo is automatically cropped to a 4:3 ratio for a consistent look across your listing. Tap any photo to manually fine-tune the crop until it fits perfectly.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 10)
    }

    @ViewBuilder
    private var statusBanner: some View {
        if photos.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 8) {
                if needsReviewCount > 0 {
                    Image(systemName: "crop")
                    Text("\(needsReviewCount) photo\(needsReviewCount == 1 ? "" : "s") auto-cropped to 4:3 — tap to fine-tune.")
                } else {
                    Image(systemName: "checkmark.circle")
                    Text("All \(photos.count) photos are ready at 4:3.")
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(needsReviewCount > 0 ? Color(red: 0.541, green: 0.353, blue: 0) : Color(red: 0.059, green: 0.431, blue: 0.49))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                (needsReviewCount > 0 ? Color(red: 1, green: 0.969, blue: 0.902) : Color(red: 0.918, green: 0.965, blue: 0.957)),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // MARK: - Add photos

    private var addPhotosRow: some View {
        PhotosPicker(selection: $pickerSelection, maxSelectionCount: 20, matching: .images) {
            HStack(spacing: 12) {
                Image(systemName: "icloud.and.arrow.up").font(.title3).foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(photos.isEmpty ? "Add photos" : "Add more photos").font(.subheadline.bold())
                    Text("JPG or PNG from your library").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("Choose")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.075, green: 0.478, blue: 0.561), in: Capsule())
            }
            .padding(14)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
        }
        .buttonStyle(.plain)
        .padding()
    }

    // MARK: - Grid

    private var photoGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                tile(photo, index: index)
            }
            ForEach(0..<loadingCount, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
                    .aspectRatio(targetAspectRatio, contentMode: .fit)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    private func tile(_ photo: WorkingPhoto, index: Int) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                Image(uiImage: photo.preview)
                    .resizable()
                    .aspectRatio(targetAspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack {
                    Spacer()
                    HStack {
                        badge(for: photo)
                        Spacer()
                    }
                }
                .padding(8)

                HStack {
                    Button {
                        setCover(index: index)
                    } label: {
                        Image(systemName: photo.isCover ? "star.fill" : "star")
                            .foregroundStyle(photo.isCover ? Color(red: 0.961, green: 0.773, blue: 0.094) : .white)
                            .frame(width: 28, height: 28)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                    Spacer()
                    Button {
                        removePhoto(index: index)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                }
                .padding(7)
            }
            .buttonStyle(.plain)

            if photo.isCover {
                Text("Cover photo").font(.caption2.bold()).foregroundStyle(Color(red: 0.075, green: 0.478, blue: 0.561))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { activeIndex = index }
    }

    private func badge(for photo: WorkingPhoto) -> some View {
        Label(
            photo.needsReview && !photo.reviewed ? "Tap to adjust" : "Ready",
            systemImage: photo.needsReview && !photo.reviewed ? "crop" : "checkmark"
        )
        .font(.caption2.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (photo.needsReview && !photo.reviewed ? Color(red: 0.541, green: 0.353, blue: 0) : Color(red: 0.075, green: 0.478, blue: 0.561)).opacity(0.92),
            in: Capsule()
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("\(photos.count) photo\(photos.count == 1 ? "" : "s")").font(.subheadline.bold()).foregroundStyle(.secondary)
            Spacer()
            Button(saving ? "Saving…" : "Save Photos") {
                save()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.075, green: 0.478, blue: 0.561))
            .disabled(photos.isEmpty || saving)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Data

    private func loadExistingPhotos() {
        for url in listing.images.prefix(existingPhotoLimit) {
            ingest(remoteURL: url)
        }
    }

    private func ingest(remoteURL: URL) {
        let sortIndex = nextSortIndex
        nextSortIndex += 1
        loadingCount += 1
        Task {
            defer { loadingCount -= 1 }
            guard let (data, _) = try? await URLSession.shared.data(from: remoteURL), let image = UIImage(data: data) else { return }
            addPhoto(image: image, sortIndex: sortIndex)
        }
    }

    private func ingest(pickerItems: [PhotosPickerItem]) {
        for item in pickerItems {
            let sortIndex = nextSortIndex
            nextSortIndex += 1
            loadingCount += 1
            Task {
                defer { loadingCount -= 1 }
                guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
                addPhoto(image: image, sortIndex: sortIndex)
            }
        }
    }

    @MainActor
    private func addPhoto(image: UIImage, sortIndex: Int) {
        guard let cg = image.cgImage else { return }
        let width = CGFloat(cg.width)
        let height = CGFloat(cg.height)
        let needsReview = !CropMath.isNearAspectRatio(naturalWidth: width, naturalHeight: height, target: targetAspectRatio)
        let state = CropState.standard
        let preview = PhotoRaster.exportCrop(image: image, state: state, outputSize: CGSize(width: 400, height: 300))
        let hasCover = photos.contains { $0.isCover }
        let photo = WorkingPhoto(
            id: UUID().uuidString, sourceImage: image, naturalWidth: width, naturalHeight: height,
            state: state, preview: preview, reviewed: !needsReview, needsReview: needsReview,
            isCover: sortIndex == 0 && !hasCover, sortIndex: sortIndex
        )
        photos.append(photo)
        photos.sort { $0.sortIndex < $1.sortIndex }
    }

    private func applyCrop(_ result: CropResult, at index: Int) {
        guard photos.indices.contains(index) else { return }
        let thumb = PhotoRaster.exportCrop(image: result.image, state: .standard, outputSize: CGSize(width: 400, height: 300))
        photos[index].state = result.state
        photos[index].preview = thumb
        photos[index].reviewed = true
    }

    private func removePhoto(index: Int) {
        photos.remove(at: index)
        if !photos.isEmpty, !photos.contains(where: { $0.isCover }) {
            photos[0].isCover = true
        }
    }

    private func setCover(index: Int) {
        for i in photos.indices { photos[i].isCover = (i == index) }
    }

    private func save() {
        saving = true
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            saving = false
            toast.show("\(photos.count) photo\(photos.count == 1 ? "" : "s") saved to \(listing.address)")
            dismiss()
        }
    }
}
