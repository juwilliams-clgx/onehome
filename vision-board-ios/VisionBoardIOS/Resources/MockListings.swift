import Foundation

/// Mirrors vision-board-prototype/src/app/mock-listings.ts: the same 8
/// listings, same coordinates/prices/stats, same cycled Unsplash stand-in
/// photos, so native and web show comparable data side by side.
enum MockListings {
    private static let photoIDs = [
        "photo-1600210492486-724fe5c67fb0",
        "photo-1540518614846-7eded433c457",
        "photo-1600585154340-be6161a56a0c",
        "photo-1620626011761-996317b8d101",
        "photo-1617104551722-3b2d51366400",
        "photo-1601760562234-9814eea6663a",
    ]

    private static func unsplash(_ photoID: String) -> URL {
        URL(string: "https://images.unsplash.com/\(photoID)?auto=format&fit=crop&w=1200&q=80")!
    }

    private static func photos(from offset: Int, count: Int = 12) -> [URL] {
        (0..<count).map { unsplash(photoIDs[(offset + $0) % photoIDs.count]) }
    }

    static let all: [Listing] = [
        Listing(
            id: "l1", address: "890 Park Lane", cityStateZip: "San Francisco, CA 93108",
            price: 2_450_000, beds: 4, baths: 3, sqft: 3200, status: .forSale,
            images: photos(from: 0), daysOnMarket: 1, priceDropped: false, isAgentPick: true,
            visibility: nil, lat: 37.7849, lng: -122.4474
        ),
        Listing(
            id: "l2", address: "214 Cardinal Drive", cityStateZip: "Charlotte, NC 28226",
            price: 610_000, beds: 3, baths: 2, sqft: 2164, status: .forSale,
            images: photos(from: 2), daysOnMarket: 14, priceDropped: false, isAgentPick: false,
            visibility: nil, lat: 35.1283, lng: -80.8481
        ),
        Listing(
            id: "l3", address: "48 Harborview Terrace", cityStateZip: "Seattle, WA 98109",
            price: 985_000, beds: 3, baths: 2, sqft: 1980, status: .forSale,
            images: photos(from: 1), daysOnMarket: 32, priceDropped: true, isAgentPick: false,
            visibility: .limited, lat: 47.6305, lng: -122.3540
        ),
        Listing(
            id: "l4", address: "1200 Maplewood Court", cityStateZip: "Austin, TX 78701",
            price: 745_000, beds: 4, baths: 3, sqft: 2890, status: .forSale,
            images: photos(from: 3), daysOnMarket: 2, priceDropped: false, isAgentPick: false,
            visibility: nil, lat: 30.2672, lng: -97.7431
        ),
        Listing(
            id: "l5", address: "77 Lakeshore Drive", cityStateZip: "Chicago, IL 60601",
            price: 1_325_000, beds: 5, baths: 4, sqft: 4100, status: .forSale,
            images: photos(from: 4), daysOnMarket: 65, priceDropped: false, isAgentPick: false,
            visibility: .limited, lat: 41.8855, lng: -87.6221
        ),
        Listing(
            id: "l6", address: "365 Willow Bend", cityStateZip: "Denver, CO 80202",
            price: 560_000, beds: 2, baths: 2, sqft: 1450, status: .forSale,
            images: photos(from: 5), daysOnMarket: 0, priceDropped: false, isAgentPick: true,
            visibility: nil, lat: 39.7508, lng: -104.9963
        ),
        Listing(
            id: "l7", address: "920 Sunset Ridge", cityStateZip: "Phoenix, AZ 85004",
            price: 475_000, beds: 3, baths: 2, sqft: 1760, status: .forSale,
            images: photos(from: 0), daysOnMarket: 21, priceDropped: true, isAgentPick: false,
            visibility: nil, lat: 33.4506, lng: -112.0696
        ),
        Listing(
            id: "l8", address: "53 Birchwood Lane", cityStateZip: "Raleigh, NC 27601",
            price: 395_000, beds: 2, baths: 1, sqft: 1120, status: .forSale,
            images: photos(from: 1), daysOnMarket: 47, priceDropped: false, isAgentPick: false,
            visibility: nil, lat: 35.7807, lng: -78.6391
        ),
    ]
}
