import Foundation
import Observation

/// Equivalent to the web prototype's four view options
/// (vision-board-prototype/.../property-grid.ts `GridLayout`). `.list` is the
/// default here (phones only - no desktop variant to default differently
/// for), matching the mobile default added to the web prototype.
enum BrowseLayout: CaseIterable {
    case list, split, map, table

    var label: String {
        switch self {
        case .list: "List"
        case .split: "Split"
        case .map: "Map"
        case .table: "Table"
        }
    }

    var systemImage: String {
        switch self {
        case .list: "rectangle.grid.1x2"
        case .split: "rectangle.split.2x1"
        case .map: "map"
        case .table: "tablecells"
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case highestPriceFirst = "Highest Price First"
    case lowestPriceFirst = "Lowest Price First"
    case status = "Status"
    case propertyFitScore = "PropertyFit™ Score"
    case openHouses = "Open Houses"

    var id: String { rawValue }
}

/// Browse-screen UI state: current layout, the filter sheet, and which
/// listing the map should currently pan to/highlight (driven by the split
/// view's scroll position - see ListingsBrowseView).
@Observable
final class BrowseStore {
    var layout: BrowseLayout = .list
    var filterSheetOpen = false
    var sort: SortOption = .newest
    var highlightedListingID: String?

    func selectLayout(_ layout: BrowseLayout) {
        self.layout = layout
    }
}
