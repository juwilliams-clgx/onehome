import SwiftUI

/// Persistent "Vision Board" segment. Equivalent of the web prototype's
/// always-reachable Vision Board tab/panel (vision-board-panel): header with
/// the "Powered by AI" badge and a privacy note, the pinned-photo grid, a
/// sizing hint, and a "Launch Vision Board Search" action (disabled until at
/// least one photo is pinned - the web button is left unwired in the
/// prototype too, so this stays a disabled/stub action rather than inventing
/// search behavior that doesn't exist yet).
struct VisionBoardView: View {
    @Environment(VisionBoardStore.self) private var visionBoard

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

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

                    Text("Maximum 3 images\n(600 px minimum recommended)\nFor best results, try uploading different kinds of images.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            Divider()

            Button("Launch Vision Board Search") {
                // Stub: not wired to a real search flow, matching the web
                // prototype's own unimplemented button.
            }
            .buttonStyle(.borderedProminent)
            .disabled(visionBoard.pinnedPhotos.isEmpty)
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("Vision Board").font(.title2.bold())
            Label("Powered by AI", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.15), in: Capsule())
            Spacer()
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .accessibilityLabel("We do not store or share any images you upload.")
        }
    }
}
