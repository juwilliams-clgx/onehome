import Foundation
import Observation

/// Pin/unpin rules and state for a buyer's personal Vision Board. Ports the
/// interaction rules from the web prototype's `VisionBoardService`
/// (vision-board-prototype/src/app/services/vision-board.service.ts) verbatim;
/// only the presentation (sheet/alert vs. web modal) changes for iOS.
@Observable
final class VisionBoardStore {
    static let maxPinnedPhotos = 3

    private(set) var pinnedPhotos: [Photo] = []
    /// Photo awaiting unpin confirmation, shown via `.alert` in the view layer.
    var unpinTarget: Photo?
    /// True while the board is full and the user tried to pin from elsewhere
    /// (Gallery/photo detail); the view presents a "manage pins" sheet so they
    /// don't lose their place, mirroring the web's stacked capacity modal.
    var isCapacitySheetPresented = false
    /// Photo shown in the "Love This Look?" sheet (choice: pin vs. search similar).
    var loveThisLookTarget: Photo?

    private let toast: ToastCenter

    init(toast: ToastCenter) {
        self.toast = toast
    }

    var isFull: Bool {
        pinnedPhotos.count >= Self.maxPinnedPhotos
    }

    func isPinned(_ photo: Photo) -> Bool {
        pinnedPhotos.contains { $0.id == photo.id }
    }

    /// Entry point for the pin/unpin control shown on a photo.
    func requestPin(_ photo: Photo) {
        if isPinned(photo) {
            requestUnpin(photo)
            return
        }
        if isFull {
            isCapacitySheetPresented = true
            return
        }
        pin(photo)
    }

    func closeCapacitySheet() {
        isCapacitySheetPresented = false
    }

    /// Always confirm before removing a photo, whether triggered from the
    /// gallery or from the manage-pins sheet.
    func requestUnpin(_ photo: Photo) {
        unpinTarget = photo
    }

    func cancelUnpin() {
        unpinTarget = nil
    }

    func confirmUnpin() {
        guard let photo = unpinTarget else { return }
        unpinTarget = nil
        pinnedPhotos.removeAll { $0.id == photo.id }
        toast.show("Image removed from Vision Board.") { [weak self] in
            self?.pin(photo)
        }
    }

    func openLoveThisLook(_ photo: Photo) {
        loveThisLookTarget = photo
    }

    func closeLoveThisLook() {
        loveThisLookTarget = nil
    }

    func pinFromLoveThisLook() {
        guard let photo = loveThisLookTarget else { return }
        loveThisLookTarget = nil
        requestPin(photo)
    }

    /// Board is full: send them to manage pins so they choose what to unpin,
    /// rather than guessing for them.
    func managePinsFromLoveThisLook() {
        loveThisLookTarget = nil
        isCapacitySheetPresented = true
    }

    func searchSimilarFromLoveThisLook() {
        loveThisLookTarget = nil
        toast.show("Searching for more properties with a similar look...")
    }

    /// "Search Similar Look" has its own dedicated control next to Pin, so the
    /// intent is unambiguous - perform the search immediately. The web version
    /// opens the results in a new browser tab; there is no tab equivalent on
    /// iOS, so this surfaces a toast instead of silently pushing a screen
    /// the user didn't ask to navigate to.
    func searchSimilarLook(_ photo: Photo) {
        toast.show("Searching for more properties with a look similar to \(photo.room)...")
    }

    /// Pin a user-selected image from the Vision Board's "Add an Image" tile.
    func pinUpload(data: Data, suggestedName: String) -> Bool {
        guard !isFull else { return false }
        do {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("upload-\(Int(Date().timeIntervalSince1970))")
                .appendingPathExtension("jpg")
            try data.write(to: url)
            let photo = Photo(
                id: "upload-\(Int(Date().timeIntervalSince1970))",
                url: url,
                room: suggestedName.isEmpty ? "Uploaded photo" : suggestedName,
                caption: "Inspiration photo uploaded from your device."
            )
            pin(photo)
            return true
        } catch {
            toast.show("Couldn't add that image. Try again.")
            return false
        }
    }

    private func pin(_ photo: Photo) {
        pinnedPhotos.append(photo)
        toast.show("Image pinned to Vision Board!") { [weak self] in
            self?.pinnedPhotos.removeAll { $0.id == photo.id }
        }
    }
}
