import SwiftUI
import PhotosUI

/// Grid of pinned photos (max `VisionBoardStore.maxPinnedPhotos`), each with an
/// unpin control, plus an "Add an Image" tile backed by `PhotosPicker` when
/// there's room. Shared between the always-visible Vision Board segment and
/// the "manage pins" sheet shown when the board is full elsewhere - same as
/// the web prototype reusing `<app-vision-board-grid>` in both its panel and
/// its modal.
///
/// Native adaptation: the web tile uses an `<input type="file">` drag-and-drop
/// target for uploads. `PhotosPicker` is the native equivalent - it reads
/// straight from the user's photo library instead of a file-system drop.
struct VisionBoardGridView: View {
    @Environment(VisionBoardStore.self) private var visionBoard
    @State private var pickerItem: PhotosPickerItem?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(visionBoard.pinnedPhotos) { photo in
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: photo.url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(.secondarySystemBackground)
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        visionBoard.requestUnpin(photo)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.55))
                    }
                    .padding(6)
                    .accessibilityLabel("Unpin \(photo.room)")
                }
            }

            if !visionBoard.isFull {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add an Image").font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .onChange(of: pickerItem) { _, newItem in
                    Task {
                        guard let newItem, let data = try? await newItem.loadTransferable(type: Data.self) else {
                            return
                        }
                        _ = visionBoard.pinUpload(data: data, suggestedName: "")
                        pickerItem = nil
                    }
                }
            }
        }
    }
}
