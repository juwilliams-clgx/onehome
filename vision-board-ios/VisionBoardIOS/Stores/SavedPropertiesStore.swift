import Foundation
import Observation

/// Favorite/Dislike state for listings. Ports
/// vision-board-prototype/src/app/services/saved-properties.service.ts: a
/// listing can be favorited or disliked, never both at once.
@Observable
final class SavedPropertiesStore {
    private(set) var favoriteIDs: Set<String> = []
    private(set) var dislikedIDs: Set<String> = []

    func isFavorited(_ listing: Listing) -> Bool {
        favoriteIDs.contains(listing.id)
    }

    func isDisliked(_ listing: Listing) -> Bool {
        dislikedIDs.contains(listing.id)
    }

    func toggleFavorite(_ listing: Listing) {
        if favoriteIDs.contains(listing.id) {
            favoriteIDs.remove(listing.id)
        } else {
            favoriteIDs.insert(listing.id)
            dislikedIDs.remove(listing.id)
        }
    }

    func toggleDislike(_ listing: Listing) {
        if dislikedIDs.contains(listing.id) {
            dislikedIDs.remove(listing.id)
        } else {
            dislikedIDs.insert(listing.id)
            favoriteIDs.remove(listing.id)
        }
    }

    /// Removes one listing from whichever list it's actually on - used by the
    /// manage-list screen's per-row and bulk remove actions, where the intent
    /// is "take this off the list," not "toggle its like/dislike state."
    func remove(id: String, from list: ManagedListKind) {
        switch list {
        case .favorites: favoriteIDs.remove(id)
        case .dislikes: dislikedIDs.remove(id)
        }
    }

    func remove(ids: Set<String>, from list: ManagedListKind) {
        switch list {
        case .favorites: favoriteIDs.subtract(ids)
        case .dislikes: dislikedIDs.subtract(ids)
        }
    }
}

enum ManagedListKind {
    case favorites
    case dislikes
}
