import SwiftUI

/// Root screen: a custom header (hamburger + logo, replacing the web
/// prototype's full topbar on mobile) over whichever top-level section the
/// nav menu selected - Buy/Rent (the listings browse screen, default) or My
/// Properties (the Vision Board). Tapping a listing pushes into its photos,
/// reusing the existing Gallery/Photos viewer built for the Vision Board
/// effort - browsing, pinning, and reviewing the board are one continuous flow.
struct ContentView: View {
    @State private var topSection: TopSection = .buyRent
    @State private var navMenuOpen = false
    @State private var navigationPath = NavigationPath()

    @Environment(VisionBoardStore.self) private var visionBoard
    @Environment(ToastCenter.self) private var toast

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                header

                switch topSection {
                case .buyRent:
                    ListingsBrowseView(listings: MockListings.all) { listing in
                        openPhotos(for: listing)
                    } onSearchByPhoto: {
                        topSection = .myProperties
                    }
                case .myProperties:
                    VisionBoardView()
                }
            }
            .navigationDestination(for: PhotoGalleryRoute.self) { route in
                PhotoGridView(photos: route.photos)
                    .navigationTitle(route.title)
            }
            .navigationDestination(for: CompareRoute.self) { _ in
                CompareView(listings: MockListings.all)
            }
            .navigationDestination(for: ManageListRoute.self) { route in
                ManageListView(kind: route.kind)
            }
            .navigationDestination(for: AgentListingsRoute.self) { _ in
                AgentListingsView()
            }
            .navigationDestination(for: AgentPhotoUploadRoute.self) { route in
                if let listing = MockListings.all.first(where: { $0.id == route.listingID }) {
                    AgentPhotoUploadView(listing: listing)
                }
            }
            .navigationDestination(for: ServiceUnavailableRoute.self) { _ in
                ServiceUnavailableView()
                    .navigationTitle("Preview")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .overlay(alignment: .bottom) {
            if let current = toast.current {
                ToastBannerView(toast: current) { toast.dismiss() }
                    .animation(.default, value: toast.current)
            }
        }
        .overlay {
            NavMenuView(isOpen: $navMenuOpen) { section in
                topSection = section
            } onManageList: { kind in
                navigationPath.append(ManageListRoute(kind: kind))
            } onAgentTools: {
                navigationPath.append(AgentListingsRoute())
            } onServiceUnavailablePreview: {
                navigationPath.append(ServiceUnavailableRoute())
            }
        }
        .sheet(isPresented: Binding(
            get: { visionBoard.isCapacitySheetPresented },
            set: { if !$0 { visionBoard.closeCapacitySheet() } }
        )) {
            CapacityManageSheet()
        }
        .alert(
            "Are you sure you want to unpin this photo from your Vision Board?",
            isPresented: Binding(
                get: { visionBoard.unpinTarget != nil },
                set: { if !$0 { visionBoard.cancelUnpin() } }
            )
        ) {
            Button("Continue Browsing", role: .cancel) {
                visionBoard.cancelUnpin()
            }
            Button("Yes, Unpin Photo", role: .destructive) {
                visionBoard.confirmUnpin()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                navMenuOpen = true
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3)
            }
            .buttonStyle(.plain)

            (Text("one").bold() + Text("home").bold().foregroundStyle(Color(red: 1, green: 0.42, blue: 0.42)))

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    /// Hands a listing's photos to the existing Vision Board photo viewer by
    /// pushing a route value onto the stack's path.
    private func openPhotos(for listing: Listing) {
        navigationPath.append(
            PhotoGalleryRoute(
                title: listing.address,
                photos: listing.images.enumerated().map { index, url in
                    Photo(id: "\(listing.id)-\(index)", url: url, room: listing.address, caption: "")
                }
            )
        )
    }
}

/// Carries one listing's photos into the shared photo viewer, keyed by the
/// listing id + title rather than the listing itself (ListingsBrowseView
/// doesn't need to know the viewer's internal model).
struct PhotoGalleryRoute: Hashable {
    let title: String
    let photos: [Photo]
}
