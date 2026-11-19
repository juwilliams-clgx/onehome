import SwiftUI

/// Route marker for pushing the agent photo tools from the nav menu.
struct AgentListingsRoute: Hashable {}

/// Native mirror of vision-board-prototype's /agent/listings page: a simple picker
/// so the agent chooses which listing's photos they're uploading/cropping for.
/// Agent tooling is a different user type from the buyer browse/Vision Board
/// screens, so this intentionally doesn't borrow any of that chrome.
struct AgentListingsView: View {
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("AGENT TOOLS")
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.075, green: 0.478, blue: 0.561))
                Text("Select a listing to upload and crop photos.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .top])

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(MockListings.all) { listing in
                    NavigationLink(value: AgentPhotoUploadRoute(listingID: listing.id)) {
                        listingCard(listing)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Your Listings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func listingCard(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: listing.images.first) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.secondarySystemBackground)
            }
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(listing.address).font(.subheadline.bold()).lineLimit(1)
                Text(listing.cityStateZip).font(.caption).foregroundStyle(.secondary)
                Text("\(listing.images.count) photos on file").font(.caption2).foregroundStyle(Color(.tertiaryLabel))

                Text("Upload Photos")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.075, green: 0.478, blue: 0.561), in: Capsule())
                    .padding(.top, 4)
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }
}
