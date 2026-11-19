import SwiftUI

/// Bottom banner rendering `ToastCenter.current`. Equivalent of the web
/// prototype's `<app-toast>`: a brief message with an optional Undo button,
/// auto-dismissing after 5 seconds (handled by `ToastCenter`).
struct ToastBannerView: View {
    let toast: ToastCenter.Toast
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Text(toast.message)
                .font(.subheadline)
            Spacer()
            if let undo = toast.undo {
                Button("Undo") {
                    undo()
                    onDismiss()
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
