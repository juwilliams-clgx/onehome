import SwiftUI

/// Route marker for pushing the service-unavailable preview from the nav menu.
struct ServiceUnavailableRoute: Hashable {}

private enum PreviewContext: String, CaseIterable, Identifiable {
    case splash = "Splash"
    case login = "Login"
    var id: String { rawValue }
}

/// A teal banner with a diagonal bottom edge, matching the real OneHome sign-in
/// screen's header (vs. a plain rectangle) so this fallback reads as "the sign-in
/// screen, paused" rather than a generic error page.
private struct DiagonalHeaderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.90))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.72))
        path.closeSubpath()
        return path
    }
}

/// Reviewable concept for the "orchestration layer is down, no MLS data" fallback -
/// mirrors vision-board-prototype's ServiceUnavailableMockupComponent, which in turn
/// is modeled on OneHome's real sign-in screen (teal diagonal header -> headline ->
/// body copy -> form position -> primary button -> secondary link footer), so the
/// fallback reads as "the sign-in screen, paused" rather than a generic error page.
/// The same designed state covers both the splash and login touchpoints (nothing
/// meaningful can render on either without listing data, so there's one design, not
/// two). Not wired to a real splash/login flow or backend; this app has neither yet.
/// Retry is a believable two-step demo (still down, then recovers) so a reviewer can
/// see both outcomes without a real backend to fail against.
struct ServiceUnavailableView: View {
    @Environment(ToastCenter.self) private var toast
    @Environment(\.dismiss) private var dismiss

    @State private var context: PreviewContext = .splash
    @State private var retrying = false
    @State private var stillDown = false
    @State private var attempts = 0

    var body: some View {
        VStack(spacing: 24) {
            Picker("Preview context", selection: $context) {
                ForEach(PreviewContext.allCases) { c in
                    Text(c.rawValue).tag(c)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)
            .padding(.top, 12)

            VStack(spacing: 0) {
                header

                card
                    .padding(.horizontal, 24)
                    .padding(.top, -28)

                footer
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(Color(.separator)))
            .shadow(color: .black.opacity(0.1), radius: 24, y: 12)
            .frame(maxWidth: 390)
            .padding(.horizontal, 20)

            Text("Preview only — the same fallback design covers both the splash and login entry points, since neither can show anything meaningful without listing data. Tap \u{201c}Try Again\u{201d} twice to see the recovered state.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
        .navigationBarBackButtonHidden(false)
    }

    private var header: some View {
        (Text("one").bold() + Text("home").bold())
            .font(.title2)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 24)
            .padding(.top, 28)
            .padding(.bottom, 56)
            .background(
                DiagonalHeaderShape().fill(Color(red: 0.075, green: 0.478, blue: 0.561))
            )
    }

    private var loginChrome: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Email address").font(.caption.bold())
            placeholderField()
            Text("Password").font(.caption.bold()).padding(.top, 8)
            placeholderField()
        }
        .foregroundStyle(.secondary)
        .opacity(0.4)
        .allowsHitTesting(false)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    private func placeholderField() -> some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color(.systemGray3))
            .frame(height: 38)
    }

    private var card: some View {
        VStack(spacing: 6) {
            Text("It\u{2019}s not you, it\u{2019}s our wiring.")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 20)

            Text("We\u{2019}re having a quick hiccup connecting to our home listings right now. Your account is safe\u{2014}just give us a few minutes to get things back in order.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            if context == .login {
                loginChrome
            }

            Image("illustration-house-search")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.vertical, 10)

            if stillDown {
                Label("Still having trouble \u{2014} we\u{2019}ll keep trying in the background.", systemImage: "info.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.541, green: 0.353, blue: 0))
                    .padding(10)
                    .background(Color(red: 1, green: 0.969, blue: 0.902), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 6)
            }

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
        }
    }

    private var footer: some View {
        Button("Contact Support") {
            toast.show("support@onehome.com \u{b7} (800) 555-0199")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color(red: 0.075, green: 0.478, blue: 0.561))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
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
