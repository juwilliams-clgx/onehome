import SwiftUI

/// "Manage pins" sheet, equivalent to the web prototype's `vision-board-modal`:
/// shown when the board is full and the user tried to pin from elsewhere, so
/// they can unpin without losing their place in the Gallery/photo viewer.
/// Reuses the same grid as the persistent Vision Board segment, matching the
/// web prototype reusing `<app-vision-board-grid>` in both places.
struct CapacityManageSheet: View {
    @Environment(VisionBoardStore.self) private var visionBoard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if visionBoard.isFull {
                        Text("Max photos pinned – unpin any photo to pin more.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(
                            "Manage your Vision Board here, upload more inspiration, continue browsing to pin photos from other properties, and launch a Vision Board search to find homes that match your aesthetic."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    VisionBoardGridView()

                    Text("Maximum 3 images\n(600 px minimum recommended)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Vision Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button("Launch Vision Board Search") {}
                        .buttonStyle(.borderedProminent)
                        .disabled(visionBoard.pinnedPhotos.isEmpty)
                        .frame(maxWidth: .infinity)
                    Button("Continue Browsing") { dismiss() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(.bar)
            }
        }
        .presentationDetents([.medium, .large])
    }
}
