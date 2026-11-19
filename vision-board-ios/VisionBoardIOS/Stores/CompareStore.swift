import Foundation
import Observation

/// Tracks which listings the buyer has added to Compare - the native
/// counterpart to the web prototype's CompareService. Analytics showed heavy
/// Compare use while the button itself did nothing, so this makes it real:
/// toggle from any card, a badge count in the search header, and a
/// dedicated comparison view.
@Observable
final class CompareStore {
    private(set) var ids: Set<String> = []

    var count: Int { ids.count }

    func isCompared(_ listing: Listing) -> Bool {
        ids.contains(listing.id)
    }

    func toggle(_ listing: Listing) {
        if ids.contains(listing.id) {
            ids.remove(listing.id)
        } else {
            ids.insert(listing.id)
        }
    }

    func remove(_ id: String) {
        ids.remove(id)
    }

    func clear() {
        ids.removeAll()
    }
}
