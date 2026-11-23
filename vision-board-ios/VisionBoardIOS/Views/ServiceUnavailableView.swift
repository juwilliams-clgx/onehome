import SwiftUI

/// Route marker for pushing the service-unavailable preview from the nav menu.
struct ServiceUnavailableRoute: Hashable {}

/// Reviewable concept for the "orchestration layer is down, no MLS data" fallback -
/// mirrors vision-board-prototype's ServiceUnavailableMockupComponent, which in turn
/// is modeled on OneHome's real sign-in screen, with the hierarchy ordered as:
/// illustration -> headline -> support text -> primary CTA -> secondary action.
/// Covers the app's one entry point (sign-in; there's no separate splash flow, and
/// login fields are never shown here). A true responsive layout - content is
/// centered in a readable column at any width, not boxed into a fixed phone-sized
/// frame - so it reads correctly on both iPhone and iPad. Not wired to a real
/// sign-in flow or backend. Retry is a believable two-step demo (still down, then
/// recovers) so a reviewer can see both outcomes without a real backend to fail
/// against.
struct ServiceUnavailableView: View {
    @Environment(ToastCenter.self) private var toast
    @Environment(\.dismiss) private var dismiss

    @State private var retrying = false
    @State private var stillDown = false
    @State private var attempts = 0

    var body: some View {
        VStack(spacing: 24) {
            Image("illustration-wet-floor-sign")
                .resizable()
                .scaledToFit()
                .frame(width: 108)

            Text("It\u{2019}s not you, it\u{2019}s our wiring.")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("We\u{2019}re having a quick hiccup connecting to our home listings right now. Your account is safe\u{2014}just give us a few minutes to get things back in order.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if stillDown {
                Label("Still having trouble \u{2014} we\u{2019}ll keep trying in the background.", systemImage: "info.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.541, green: 0.353, blue: 0))
                    .padding(10)
                    .background(Color(red: 1, green: 0.969, blue: 0.902), in: RoundedRectangle(cornerRadius: 10))
            }

            VStack(spacing: 16) {
                Button(action: retry) {
                    HStack(spacing: 8) {
                        if retrying {
                            ProgressView().tint(.white)
                        }
                        Text(retrying ? "Trying again\u{2026}" : "Try Again")
                            .font(.body.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.271, green: 0.467, blue: 0.714))
                .disabled(retrying)

                Button("Contact Support") {
                    toast.show("support@onehome.com \u{b7} (800) 555-0199")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.075, green: 0.478, blue: 0.561))
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(false)
    }

    private func retry() {
        guard !retrying else { return }
        retrying = true
        stillDown = false
        attempts += 1
        Task {
            try? await Task.sleep(for: .milliseconds(1100))
            retrying = false
            if attempts >= 2 {
                dismiss()
            } else {
                stillDown = true
            }
        }
    }
}
