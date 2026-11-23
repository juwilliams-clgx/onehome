import SwiftUI

/// Marker route value so tapping the Compare tray icon can push `CompareView`
/// via the shared NavigationStack in `ContentView`.
struct CompareRoute: Hashable {}

private struct SavedSearch: Identifiable {
    let id = UUID()
    var label: String
}

/// Native port of the web prototype's mobile search header: a Compare tray
/// (badge = count), the saved-search picker pill (defaults to the detected
/// location), and a Search control that expands into a full text field -
/// matching the production OneHome app's own header pattern.
struct SearchHeaderView: View {
    var onSearchByPhoto: () -> Void = {}

    @Environment(CompareStore.self) private var compare
    @Environment(LocationStore.self) private var location
    @Environment(AISearchStore.self) private var aiSearch

    @State private var dropdownOpen = false
    @State private var searchExpanded = false
    @State private var query = ""
    @State private var selectedSearchLabel: String?
    @FocusState private var searchFieldFocused: Bool

    @State private var agentSearches = ["AE Canopy UAT - mixed listings", "AE 2", "AE"]
    @State private var mySearches: [SavedSearch] = [
        SavedSearch(label: "Canton OH Saved search Oct 13, 2026"),
        SavedSearch(label: "Saved search Oct 9, 2026"),
        SavedSearch(label: "Saved search Oct 7, 2026"),
        SavedSearch(label: "Saved search Oct 5, 2026"),
        SavedSearch(label: "Saved search Oct 1, 2026"),
    ]

    private var pillLabel: String {
        if let selectedSearchLabel { return selectedSearchLabel }
        if let displayLocation = location.displayLocation { return displayLocation }
        return location.isLoading ? "Finding your area…" : "Search an address, city, zip…"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                NavigationLink(value: CompareRoute()) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "square.on.square")
                            .frame(width: 40, height: 40)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                        if compare.count > 0 {
                            Text("\(compare.count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(.red, in: Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .buttonStyle(.plain)
                // Condenses away when the search field expands, matching the
                // web version's reveal rather than overlapping the field.
                .frame(width: searchExpanded ? 0 : 40)
                .opacity(searchExpanded ? 0 : 1)
                .clipped()

                if !searchExpanded {
                    Button {
                        withAnimation { dropdownOpen.toggle() }
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text(pillLabel)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(dropdownOpen ? 180 : 0))
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        dropdownOpen = false
                        withAnimation(.easeOut(duration: 0.22)) {
                            searchExpanded = true
                        }
                        searchFieldFocused = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .frame(width: 40, height: 40)
                            .background(Color(.secondarySystemBackground), in: Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    searchField
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            if dropdownOpen {
                dropdown
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Address, neighborhood, city, zip…", text: $query)
                .focused($searchFieldFocused)

            // Camera chip does the same job as Vision Board's "Search Similar
            // Look," so it opens that flow rather than being a disconnected stub.
            Button {
                withAnimation(.easeOut(duration: 0.22)) { searchExpanded = false }
                onSearchByPhoto()
            } label: {
                Image(systemName: "camera")
                    .foregroundStyle(.orange)
                    .frame(width: 30, height: 30)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.orange.opacity(0.4)))
            }

            Button {
                aiSearch.open()
            } label: {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color(red: 0.486, green: 0.227, blue: 0.929))
                    .frame(width: 30, height: 30)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.486, green: 0.227, blue: 0.929).opacity(0.3)))
            }

            Button {
                withAnimation(.easeOut(duration: 0.22)) {
                    searchExpanded = false
                }
                query = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground), in: Capsule())
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private var dropdown: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("YOUR AGENT'S SAVED SEARCHES")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                ForEach(agentSearches, id: \.self) { search in
                    Button(search) {
                        selectedSearchLabel = search
                        dropdownOpen = false
                    }
                    .buttonStyle(.plain)
                }

                Divider().padding(.vertical, 4)

                Text("YOUR SAVED SEARCHES")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                ForEach(mySearches) { search in
                    HStack {
                        Button(search.label) {
                            selectedSearchLabel = search.label
                            dropdownOpen = false
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Button {
                            mySearches.removeAll { $0.id == search.id }
                        } label: {
                            Image(systemName: "xmark").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxHeight: 320)
        .background(Color(.systemBackground))
    }
}
