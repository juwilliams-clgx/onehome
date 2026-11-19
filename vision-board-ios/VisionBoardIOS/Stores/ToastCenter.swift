import Foundation
import Observation

/// A brief, dismissible confirmation message with an optional Undo action.
/// Mirrors the web prototype's `ToastService` (5-second auto-dismiss, one
/// toast at a time). SwiftUI has no built-in toast component; `ToastBannerView`
/// renders this as a bottom banner, which is the closest native-feeling
/// equivalent (the same pattern Mail/Notes use for "Message moved. Undo").
@Observable
final class ToastCenter {
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let undo: (() -> Void)?

        static func == (lhs: Toast, rhs: Toast) -> Bool {
            lhs.id == rhs.id
        }
    }

    private(set) var current: Toast?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, undo: (() -> Void)? = nil) {
        dismissTask?.cancel()
        current = Toast(message: message, undo: undo)
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        current = nil
    }
}
