import SwiftUI

/// Native port of the web prototype's compare-view: the real destination for
/// the Compare tray, since analytics showed heavy use of a button that
/// previously did nothing.
struct CompareView: View {
    let listings: [Listing]
    @Environment(CompareStore.self) private var compare

    private var comparedListings: [Listing] {
        listings.filter { compare.isCompared($0) }
    }

    var body: some View {
        ScrollView {
            if comparedListings.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(comparedListings) { listing in
                        card(for: listing)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Compare (\(comparedListings.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !comparedListings.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear All", role: .destructive) {
                        compare.clear()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.on.square")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("No properties added to Compare yet. Tap **Compare** on any listing to add it here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
        }
        .padding(.top, 80)
    }

    private func card(for listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: listing.images.first) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.secondarySystemBackground)
                }
                .frame(height: 180)
                .clipped()

                Button {
                    compare.remove(listing.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.55))
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(listing.formattedPrice).font(.title3.bold())

                HStack(spacing: 10) {
                    statChip("Beds", "\(listing.beds)")
                    statChip("Baths", "\(listing.baths)")
                    statChip("Sqft", "\(listing.sqft)")
                    statChip("Status", listing.status.rawValue)
                }

                Text("\(listing.address), \(listing.cityStateZip)")
                    .font(.footnote)
            }
            .padding(14)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }

    private func statChip(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased()).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
    }
}
