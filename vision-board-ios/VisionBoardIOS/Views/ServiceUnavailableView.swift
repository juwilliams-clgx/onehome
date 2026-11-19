import SwiftUI

/// Route marker for pushing the service-unavailable preview from the nav menu.
struct ServiceUnavailableRoute: Hashable {}

private enum PreviewContext: String, CaseIterable, Identifiable {
    case splash = "Splash"
    case login = "Login"
    var id: String { rawValue }
}

/// Reviewable concept for the "orchestration layer is down, no MLS data" fallback -
/// mirrors vision-board-prototype's ServiceUnavailableMockupComponent. The same
/// designed state covers both the splash and login touchpoints (nothing meaningful
/// can render on either without listing data, so there's one design, not two). Not
/// wired to a real splash/login flow or backend; this app has neither yet. Retry is a
/// believable two-step demo (still down, then recovers) so a reviewer can see both
/// outcomes without a real backend to fail against.
struct ServiceUnavailableView: View {
    @Environment(ToastCenter.self) private var toast
    @Environment(\.dismiss) private var dismiss

    @State private var context: PreviewContext = .splash
    @State private var retrying = false
    @State private var stillDown = false
    @State private var attempts = 0
    @State private var spin = false

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
                logo
                    .padding(.top, 40)

                if context == .login {
                    loginChrome
                        .padding(.top, 24)
                        .padding(.horizontal, 24)
                }

                Spacer()

                card
                    .padding(.horizontal, 28)

                Spacer()
                Spacer()
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

    private var logo: some View {
        (Text("one").bold() + Text("home").bold().foregroundStyle(Color(red: 1, green: 0.42, blue: 0.42)))
            .font(.title2)
    }

    private var loginChrome: some View {
        VStack(spacing: 10) {
            placeholderField("Email")
            placeholderField("Password")
            placeholderField("Sign In", filled: true)
        }
        .opacity(0.35)
        .saturation(0.5)
        .allowsHitTesting(false)
    }

    private func placeholderField(_ label: String, filled: Bool = false) -> some View {
        Text(label)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(filled ? Color(.systemGray4) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private var card: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.918, green: 0.965, blue: 0.957))
                    .frame(width: 84, height: 84)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color(red: 0.075, green: 0.478, blue: 0.561))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(retrying ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default, value: spin)
            }
            .padding(.bottom, 16)

            Text("It\u{2019}s not you, it\u{2019}s our wiring.")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("We\u{2019}re having a quick hiccup connecting to our home listings right now. Your account is safe\u{2014}just give us a few minutes to get things back in order.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.bottom, 18)

            if stillDown {
                Label("Still having trouble \u{2014} we\u{2019}ll keep trying in the background.", systemImage: "info.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.541, green: 0.353, blue: 0))
                    .padding(10)
                    .background(Color(red: 1, green: 0.969, blue: 0.902), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 14)
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
            .tint(Color(red: 0.075, green: 0.478, blue: 0.561))
            .clipShape(Capsule())
            .disabled(retrying)
            .padding(.bottom, 10)

            Button("Contact Support") {
                toast.show("support@onehome.com \u{b7} (800) 555-0199")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(red: 0.075, green: 0.478, blue: 0.561))
        }
    }

    private func retry() {
        guard !retrying else { return }
        retrying = true
        stillDown = false
        spin = true
        attempts += 1
        Task {
            try? await Task.sleep(for: .milliseconds(1100))
            retrying = false
            spin = false
            if attempts >= 2 {
                dismiss()
            } else {
                stillDown = true
            }
        }
    }
}
