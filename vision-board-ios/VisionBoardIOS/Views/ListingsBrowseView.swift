import SwiftUI

/// Native port of the web prototype's property-grid screen plus this
/// session's mobile redesign: a condensed Filter pill + layout toggle control
/// bar (not the old row of pills), and the fixed 50/50 Split view where
/// scrolling the list pans/highlights the map pin for whichever listing is
/// in view - the one deliberate departure from a Zillow-style map takeover.
struct ListingsBrowseView: View {
    let listings: [Listing]
    var onOpenPhotos: (Listing) -> Void
    var onSearchByPhoto: () -> Void = {}

    @Environment(BrowseStore.self) private var browse
    @Environment(AISearchStore.self) private var aiSearch
    @State private var scrolledListingID: Listing.ID?

    /// `listings`, narrowed to the AI search panel's result ids when a conversational filter is active.
    private var filteredListings: [Listing] {
        guard let ids = aiSearch.visibleListingIDs else { return listings }
        return listings.filter { ids.contains($0.id) }
    }

    var body: some View {
        @Bindable var browse = browse
        @Bindable var aiSearch = aiSearch

        VStack(spacing: 0) {
            SearchHeaderView(onSearchByPhoto: onSearchByPhoto)
            controlBar

            switch browse.layout {
            case .list:
                listContent
            case .split:
                splitContent
            case .map:
                PropertyMapView(listings: filteredListings)
            case .table:
                tableContent
            }
        }
        .sheet(isPresented: $browse.filterSheetOpen) {
            FilterSortSheet()
        }
        .sheet(isPresented: $aiSearch.isOpen) {
            AISearchPanelView()
        }
    }

    // MARK: Control bar

    private var controlBar: some View {
        HStack {
            Button {
                browse.filterSheetOpen = true
            } label: {
                Label("Filter", systemImage: "slider.vertical.3")
            }
            .buttonStyle(.bordered)

            Spacer()

            Text("\(filteredListings.count) Results")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)

            Spacer()

            layoutPicker
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var layoutPicker: some View {
        // A native `Menu` is the vertical, labeled list this calls for - each
        // option shows its icon *and* name, rather than the icon-only row
        // this started as, which didn't say what each view actually was.
        Menu {
            ForEach(BrowseLayout.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        browse.selectLayout(option)
                    }
                } label: {
                    Label(option.label, systemImage: option.systemImage)
                    if browse.layout == option {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            Label(browse.layout.label, systemImage: browse.layout.systemImage)
        }
        .buttonStyle(.bordered)
    }

    // MARK: Layouts

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredListings) { listing in
                    ListingCardView(listing: listing) { focusOnMap($0) }
                        .onTapGesture { onOpenPhotos(listing) }
                }
            }
            .padding()
        }
    }

    private var splitContent: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                PropertyMapView(listings: filteredListings)
                    .frame(height: proxy.size.height / 2)

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredListings) { listing in
                            ListingCardView(listing: listing) { focusOnMap($0) }
                                .id(listing.id)
                                .onTapGesture { onOpenPhotos(listing) }
                        }
                    }
                    .padding()
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrolledListingID)
                .frame(height: proxy.size.height / 2)
                .onChange(of: scrolledListingID) { _, newID in
                    browse.highlightedListingID = newID
                }
            }
        }
    }

    private var tableContent: some View {
        List(filteredListings) { listing in
            HStack {
                Text(listing.formattedPrice).bold()
                Spacer()
                Text("\(listing.beds) bd").font(.footnote)
                Text("\(listing.baths) ba").font(.footnote)
                Text("\(listing.sqft) sqft").font(.footnote)
            }
            .onTapGesture { onOpenPhotos(listing) }
        }
        .listStyle(.plain)
    }

    /// The card's map-pin action: same job as the web's `onMapFocus` - pan to
    /// and highlight this listing's pin, without navigating away from the list.
    private func focusOnMap(_ listing: Listing) {
        browse.highlightedListingID = listing.id
    }
}
