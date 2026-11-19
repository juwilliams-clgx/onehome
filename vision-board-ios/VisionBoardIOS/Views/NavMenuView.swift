import SwiftUI

/// Native port of the web prototype's slide-in nav menu (vision-board-prototype/.../app.html):
/// close/logo/bell/avatar header behind a violet accent bar (ties into the
/// existing "Powered by AI" badge color already used in the Vision Board
/// screens), then Buy/Rent and My Properties as real destinations with the
/// rest (Planner, Marketplace, Services, Help) kept inert, matching what the
/// web prototype itself wires up today.
struct NavMenuView: View {
    @Binding var isOpen: Bool
    var onSelect: (TopSection) -> Void
    var onManageList: (ManagedListKind) -> Void = { _ in }
    var onAgentTools: () -> Void = {}
    var onServiceUnavailablePreview: () -> Void = {}

    var body: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(isOpen ? 0.45 : 0)
                .ignoresSafeArea()
                .onTapGesture { close() }

            if isOpen {
                menu
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.interpolatingSpring(stiffness: 260, damping: 28), value: isOpen)
    }

    private var menu: some View {
        VStack(spacing: 0) {
            Color(red: 0.486, green: 0.227, blue: 0.929)
                .frame(height: 4)

            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sectionRow("Buy / Rent") {
                        onSelect(.buyRent)
                        close()
                    }
                    subitemRow("Saved Searches")
                    subitemRow("New Search")

                    sectionRow("My Properties") {
                        onSelect(.myProperties)
                        close()
                    }
                    subitemRow("Vision Board") {
                        onSelect(.myProperties)
                        close()
                    }
                    subitemRow("Favorites") {
                        onManageList(.favorites)
                        close()
                    }
                    subitemRow("Dislikes") {
                        onManageList(.dislikes)
                        close()
                    }

                    sectionRow("Planner", action: nil)

                    sectionRow("Marketplace", action: nil)
                    subitemRow("Marketplace")
                    subitemRow("My Marketplace")
                    subitemRow("Mortgage")
                    subitemRow("Insurance")
                    subitemRow("Home Professionals")

                    sectionRow("Services", action: nil)
                    sectionRow("Help", action: nil)

                    Divider().padding(.vertical, 8)

                    sectionRow("Agent Tools") {
                        onAgentTools()
                        close()
                    }
                    subitemRow("Upload Photos") {
                        onAgentTools()
                        close()
                    }

                    Divider().padding(.vertical, 8)

                    sectionRow("Service Unavailable (Preview)") {
                        onServiceUnavailablePreview()
                        close()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 320)
        .frame(maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                close()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 32, height: 32)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)

            Text("one")
                .fontWeight(.bold)
                + Text("home")
                .fontWeight(.bold)
                .foregroundStyle(Color(red: 1, green: 0.42, blue: 0.42))

            Spacer()

            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                Circle()
                    .fill(Color(red: 1, green: 0.42, blue: 0.42))
                    .frame(width: 7, height: 7)
                    .offset(x: 4, y: -2)
            }

            Image(systemName: "person.circle")
                .font(.title3)
        }
        .padding(16)
    }

    private func sectionRow(_ title: String, action: (() -> Void)? = nil) -> some View {
        Group {
            if let action {
                Button(action: action) {
                    Text(title)
                        .font(.body.weight(.bold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else {
                Text(title)
                    .font(.body.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 12)
    }

    private func subitemRow(_ title: String, action: (() -> Void)? = nil) -> some View {
        Group {
            if let action {
                Button(action: action) {
                    subitemLabel(title)
                }
                .buttonStyle(.plain)
            } else {
                subitemLabel(title)
            }
        }
    }

    private func subitemLabel(_ title: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(.tertiaryLabel))
                .frame(width: 4, height: 4)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 9)
        .padding(.leading, 8)
    }

    private func close() {
        isOpen = false
    }
}

/// Top-level sections the nav menu can switch between; `ContentView` owns
/// which one is currently showing.
enum TopSection {
    case buyRent
    case myProperties
}
