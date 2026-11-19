import SwiftUI

/// Full-screen, swipeable photo viewer. Equivalent of the web prototype's
/// "Photos" tab (vision-board-prototype/.../components/photo-viewer):
/// previous/next navigation, Pin/Unpin and Search Similar Look controls, and
/// a caption with a position counter.
///
/// `TabView(.page)` gives the native swipe-between-photos behavior for free,
/// including the system page indicator, instead of hand-rolled prev/next
/// buttons layered over a single image.
struct PhotoDetailView: View {
    let photos: [Photo]
    @State private var index: Int
    @Environment(VisionBoardStore.self) private var visionBoard

    init(photos: [Photo], startIndex: Int) {
        self.photos = photos
        _index = State(initialValue: startIndex)
    }

    private var currentPhoto: Photo { photos[index] }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $index) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { i, photo in
                    AsyncImage(url: photo.url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.black)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(currentPhoto.room).font(.headline)
                    Spacer()
                    Text("\(index + 1) / \(photos.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text(currentPhoto.caption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()

            actionBar
                .padding(.horizontal)
                .padding(.bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $visionBoard.loveThisLookTarget) { photo in
            LoveThisLookSheet(photo: photo)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button {
                visionBoard.searchSimilarLook(currentPhoto)
            } label: {
                Image(systemName: "camera")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Search Similar Look")

            Button {
                visionBoard.requestPin(currentPhoto)
            } label: {
                Image(systemName: visionBoard.isPinned(currentPhoto) ? "pin.slash.fill" : "pin.fill")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(visionBoard.isPinned(currentPhoto) ? "Unpin" : "Pin")

            Spacer()

            // The web prototype wires up the "Love This Look?" modal in its
            // VisionBoardService but never attaches it to a control in the
            // current UI, so there's no existing trigger to port. Exposing it
            // here as an explicit action keeps the flow reachable for review;
            // confirm/replace with the team's intended entry point (e.g. a
            // long-press, or auto-surfacing after a pin) once decided.
            Button {
                visionBoard.openLoveThisLook(currentPhoto)
            } label: {
                Label("Love This Look?", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
        }
        .font(.body)
    }
}
