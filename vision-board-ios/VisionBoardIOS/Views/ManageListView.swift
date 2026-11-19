import SwiftUI

/// Route value for pushing a Favorites or Dislikes management screen from the
/// nav menu's "My Properties" section.
struct ManageListRoute: Hashable {
    let kind: ManagedListKind
}

/// Native counterpart to the web prototype's manage-list screen
/// (vision-board-prototype/.../manage-list), with the same bulk-select
/// feature added this round: a "Select" mode with per-card checkboxes,
/// Select All, and a confirmed "Remove Selected" bulk action - so clearing a
/// whole saved list doesn't require removing items one at a time.
struct ManageListView: View {
    let kind: ManagedListKind

    @Environment(SavedPropertiesStore.self) private var saved

    @State private var selectionMode = false
    @State private var selectedIDs: Set<String> = []
    @State private var confirmBulkRemoveOpen = false

    private var listName: String { kind == .favorites ? "Favorites" : "Dislikes" }

    private var savedIDs: Set<String> {
        kind == .favorites ? saved.favoriteIDs : saved.dislikedIDs
    }

    private var listings: [Listing] {
        MockListings.all.filter { savedIDs.contains($0.id) }
    }

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        content
            .navigationTitle("\(listName) (\(listings.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !listings.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button(selectionMode ? "Cancel" : "Select") {
                            selectionMode.toggle()
                            selectedIDs = []
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if selectionMode {
                    bulkBar
                }
            }
            .alert(
                "Remove \(selectedIDs.count) \(selectedIDs.count == 1 ? "property" : "properties")?",
                isPresented: $confirmBulkRemoveOpen
            ) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    saved.remove(ids: selectedIDs, from: kind)
                    selectedIDs = []
                    selectionMode = false
                }
            } message: {
                Text("This will remove them from \(listName). This can't be undone.")
            }
    }

    private var content: some View {
        Group {
            if listings.isEmpty {
                ContentUnavailableView(
                    "Nothing left on \(listName)",
                    systemImage: kind == .favorites ? "heart" : "hand.thumbsdown"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(listings) { listing in
                            card(for: listing)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func card(for listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: listing.images.first) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.secondarySystemBackground)
                }
                .frame(height: 130)
                .clipped()

                if selectionMode {
                    Image(systemName: selectedIDs.contains(listing.id) ? "checkmark.circle.fill" : "circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, selectedIDs.contains(listing.id) ? Color.accentColor : .black.opacity(0.4))
                        .font(.title3)
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(listing.formattedPrice).font(.subheadline.bold())
                    Spacer()
                    if !selectionMode {
                        Button {
                            saved.remove(id: listing.id, from: kind)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(listing.address).font(.caption).lineLimit(1)
                Text(listing.cityStateZip).font(.caption2).foregroundStyle(.secondary)
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard selectionMode else { return }
            if selectedIDs.contains(listing.id) {
                selectedIDs.remove(listing.id)
            } else {
                selectedIDs.insert(listing.id)
            }
        }
    }

    private var bulkBar: some View {
        VStack(spacing: 10) {
            HStack {
                Button(selectedIDs.count == listings.count ? "Deselect All" : "Select All") {
                    selectedIDs = selectedIDs.count == listings.count ? [] : Set(listings.map(\.id))
                }
                Spacer()
                Text("\(selectedIDs.count) selected").foregroundStyle(.secondary)
            }
            .font(.subheadline)

            Button("Remove Selected", role: .destructive) {
                if !selectedIDs.isEmpty {
                    confirmBulkRemoveOpen = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(selectedIDs.isEmpty)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.bar)
    }
}
