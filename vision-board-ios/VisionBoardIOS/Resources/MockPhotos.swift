import Foundation

/// Mock listing photos, standing in for real MLS photos the same way the web
/// prototype uses Unsplash stand-ins (vision-board-prototype/src/app/mock-photos.ts).
/// Kept in sync with that file (p1-p6; p7's floor plan is out of this effort's scope).
enum MockPhotos {
    private static func unsplash(_ photoID: String) -> URL {
        URL(string: "https://images.unsplash.com/\(photoID)?auto=format&fit=crop&w=1200&q=80")!
    }

    static let all: [Photo] = [
        Photo(
            id: "p1",
            url: unsplash("photo-1600210492486-724fe5c67fb0"),
            room: "Living Room",
            caption: "Open-concept living room with floating staircase and skylight."
        ),
        Photo(
            id: "p2",
            url: unsplash("photo-1540518614846-7eded433c457"),
            room: "Primary Bedroom",
            caption: "Bright primary bedroom with patterned accent pillows."
        ),
        Photo(
            id: "p3",
            url: unsplash("photo-1600585154340-be6161a56a0c"),
            room: "Kitchen",
            caption: "Modern kitchen with waterfall island and pendant lighting."
        ),
        Photo(
            id: "p4",
            url: unsplash("photo-1620626011761-996317b8d101"),
            room: "Primary Bathroom",
            caption: "Spa-style bathroom with backlit mirror and soaking tub."
        ),
        Photo(
            id: "p5",
            url: unsplash("photo-1617104551722-3b2d51366400"),
            room: "Dining Room",
            caption: "Formal dining room with glass table and statement chandelier."
        ),
        Photo(
            id: "p6",
            url: unsplash("photo-1601760562234-9814eea6663a"),
            room: "Backyard",
            caption: "Landscaped backyard with covered patio and fire pit."
        ),
    ]
}
