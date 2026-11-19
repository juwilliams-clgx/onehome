import SwiftUI

/// Entry point into a property's photos. Equivalent of the web prototype's
/// "Gallery" tab (vision-board-prototype/.../components/photo-grid): a grid of
/// thumbnails, each with inline Pin and Search Similar Look controls, that
/// pushes a full-screen viewer when tapped.
///
/// Native adaptation: the web page keeps Gallery/Photos as separate in-page
/// tabs you click between. On iOS, tapping a tile pushes `PhotoDetailView`
/// (NavigationStack), which is the idiomatic equivalent of "open in Photos
/// tab" without needing a persistent tab for it.
struct PhotoGridView: View {
    let photos: [Photo]

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    // The tile hosts its own Pin/Search Similar buttons, so the
                    // push-to-detail link sits behind them as a background
                    // rather than wrapping them as a NavigationLink label -
                    // nesting real buttons inside a NavigationLink's label is
                    // unreliable for hit-testing which control wins the tap.
                    PhotoGridTile(photo: photo)
                        .background(
                            NavigationLink(value: PhotoDetailRoute(startIndex: index)) { EmptyView() }
                                .opacity(0)
                        )
                }
            }
            .padding(16)
        }
        .navigationDestination(for: PhotoDetailRoute.self) { route in
            PhotoDetailView(photos: photos, startIndex: route.startIndex)
        }
    }
}

/// Routing value so pushing the detail view carries only the tapped index,
/// not the whole photo array, through `navigationDestination`.
struct PhotoDetailRoute: Hashable {
    let startIndex: Int
}

private struct PhotoGridTile: View {
    let photo: Photo
    @Environment(VisionBoardStore.self) private var visionBoard

    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: photo.url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.secondarySystemBackground)
            }
            .frame(height: 150)
            .clipped()

            HStack(spacing: 6) {
                Button {
                    visionBoard.searchSimilarLook(photo)
                } label: {
                    Label("Search Similar", systemImage: "camera")
                        .labelStyle(.iconOnly)
                        .font(.footnote)
                }
                Spacer()
                Button {
                    visionBoard.requestPin(photo)
                } label: {
                    Image(systemName: visionBoard.isPinned(photo) ? "pin.slash.fill" : "pin.fill")
                        .font(.footnote)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .padding(8)
            .background(.black.opacity(0.35), in: Capsule())
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(photo.room)
    }
}
