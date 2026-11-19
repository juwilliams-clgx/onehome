import SwiftUI

/// Native port of vision-board-prototype/.../property-card: a swipeable photo
/// carousel, status/limited-exposure badges, map/dislike/favorite actions,
/// and price/stats/address. No prev/next buttons - `TabView(.page)` gives
/// swipe-to-browse for free, which is the native answer to the web version's
/// arrows-stuck-visible-on-touch problem rather than a ported workaround.
struct ListingCardView: View {
    let listing: Listing
    var onMapFocus: (Listing) -> Void = { _ in }

    @Environment(SavedPropertiesStore.self) private var saved
    @Environment(CompareStore.self) private var compare

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            media
            details
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }

    private var media: some View {
        ZStack(alignment: .topLeading) {
            TabView {
                ForEach(listing.images.prefix(12), id: \.self) { url in
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(.secondarySystemBackground)
                    }
                    .clipped()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: listing.images.count > 1 ? .automatic : .never))
            .frame(height: 220)

            if listing.visibility == .limited {
                Label("Limited Exposure", systemImage: "info.circle.fill")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.871, green: 0.91, blue: 0.976), in: Capsule())
                    .foregroundStyle(Color(red: 0.259, green: 0.337, blue: 0.463))
                    .padding(8)
            } else if listing.status != .forSale {
                Text(listing.status.rawValue.uppercased())
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(.white)
                    .padding(8)
            }

            HStack(spacing: 6) {
                Spacer()
                actionButton(systemImage: "mappin.and.ellipse") { onMapFocus(listing) }
                actionButton(systemImage: saved.isDisliked(listing) ? "hand.thumbsdown.fill" : "hand.thumbsdown") {
                    saved.toggleDislike(listing)
                }
                actionButton(systemImage: saved.isFavorited(listing) ? "heart.fill" : "heart") {
                    saved.toggleFavorite(listing)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func actionButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.footnote)
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.9), in: Circle())
                .shadow(color: .black.opacity(0.2), radius: 3)
        }
        .buttonStyle(.plain)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(listing.formattedPrice)
                .font(.title3.bold())

            HStack(spacing: 8) {
                Text("\(listing.beds) bd")
                Text("\(listing.baths) ba")
                Text("\(listing.sqft) sqft")
                Spacer()
                if listing.priceDropped {
                    freshnessTag("PRICE DROP", tint: .orange)
                } else if listing.isNew {
                    freshnessTag("NEW", tint: .indigo)
                }
            }
            .font(.footnote)
            .foregroundStyle(.primary)

            Text("\(listing.address), \(listing.cityStateZip)")
                .font(.footnote)

            HStack {
                if listing.isAgentPick {
                    Text("Agent Pick")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 1, green: 0.97, blue: 0.9), in: Capsule())
                        .foregroundStyle(Color(red: 0.573, green: 0.396, blue: 0.039))
                        .overlay(Capsule().stroke(Color(red: 0.949, green: 0.843, blue: 0.620)))
                }
                Spacer()
                Button {
                    compare.toggle(listing)
                } label: {
                    Label(
                        compare.isCompared(listing) ? "Added to Compare" : "Compare",
                        systemImage: compare.isCompared(listing) ? "checkmark.square.fill" : "square.on.square"
                    )
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(compare.isCompared(listing) ? .accentColor : .secondary)
            }
        }
        .padding(14)
    }

    private func freshnessTag(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
            .foregroundStyle(tint)
    }
}
