import SwiftUI

/// "Love This Look?" sheet, equivalent to the web prototype's
/// `love-this-look-modal`: an AI-framed choice between pinning the photo and
/// searching for similar listings. When the board is already full, the pin
/// option is replaced with "Manage Pins" and surfaces first, same ordering
/// the web modal uses (`[style.order]`).
struct LoveThisLookSheet: View {
    let photo: Photo
    @Environment(VisionBoardStore.self) private var visionBoard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if visionBoard.isFull {
                        option(
                            title: "Vision Board Full",
                            body: "You've already pinned 3 photos. Manage your Vision Board to make room for this one.",
                            actionTitle: "Manage Pins",
                            systemImage: "square.grid.2x2"
                        ) {
                            visionBoard.managePinsFromLoveThisLook()
                        }
                        Text("Or").font(.footnote).foregroundStyle(.secondary)
                        option(
                            title: "Search Similar Look",
                            body: "Pin this style and instantly find more properties with a matching aesthetic.",
                            actionTitle: "Search Similar Look",
                            systemImage: "camera"
                        ) {
                            visionBoard.searchSimilarFromLoveThisLook()
                        }
                    } else {
                        option(
                            title: "Pin to Vision Board",
                            body: "Pin your favorite finds as you go—we'll keep them safe while you browse.",
                            actionTitle: "Pin to Vision Board",
                            systemImage: "pin"
                        ) {
                            visionBoard.pinFromLoveThisLook()
                        }
                        Text("Or").font(.footnote).foregroundStyle(.secondary)
                        option(
                            title: "Search Similar Look",
                            body: "Pin this style and instantly find more properties with a matching aesthetic.",
                            actionTitle: "Search Similar Look",
                            systemImage: "camera"
                        ) {
                            visionBoard.searchSimilarFromLoveThisLook()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Love This Look?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        visionBoard.closeLoveThisLook()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func option(
        title: String,
        body: String,
        actionTitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
            Text(title).font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
    }
}
