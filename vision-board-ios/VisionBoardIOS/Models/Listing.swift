import Foundation

/// Mirrors the web prototype's `Listing` model
/// (vision-board-prototype/src/app/models/listing.model.ts), trimmed to the
/// fields the browse grid, card, and map actually use. Full detail fields
/// (description, schools, lot size, etc.) aren't needed yet - no property
/// detail screen exists natively; tapping a card opens its photos.
struct Listing: Identifiable, Hashable {
    enum Status: String {
        case forSale = "For Sale"
        case pending = "Pending"
        case sold = "Sold"
    }

    /// MLS "Listing Visibility" field; `.limited` drives the "Limited Exposure" badge.
    enum Visibility {
        case publicListing
        case limited
    }

    let id: String
    let address: String
    let cityStateZip: String
    let price: Int
    let beds: Int
    let baths: Int
    let sqft: Int
    let status: Status
    let images: [URL]
    let daysOnMarket: Int
    let priceDropped: Bool
    let isAgentPick: Bool
    let visibility: Visibility?
    let lat: Double
    let lng: Double

    var isNew: Bool { daysOnMarket <= 2 }

    var formattedPrice: String {
        price.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
