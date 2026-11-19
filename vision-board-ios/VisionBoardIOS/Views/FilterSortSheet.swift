import SwiftUI

/// Native port of the web prototype's mobile filter bottom sheet
/// (vision-board-prototype/.../filter-sheet): Sort By options plus the
/// filter pills, consolidated behind one Filter entry point instead of a
/// cluttered row of pills next to the results count.
struct FilterSortSheet: View {
    @Environment(BrowseStore.self) private var browse
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section("Sort By") {
                        VStack(spacing: 0) {
                            ForEach(SortOption.allCases) { option in
                                Button {
                                    browse.sort = option
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        Spacer()
                                        if browse.sort == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .foregroundStyle(browse.sort == option ? Color.accentColor : .primary)
                                    .fontWeight(browse.sort == option ? .bold : .regular)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                                if option != SortOption.allCases.last {
                                    Divider()
                                }
                            }
                        }
                    }

                    section("Filters") {
                        FlowChips(["For Sale", "Price", "Beds & Baths", "More Filters"])
                    }
                }
                .padding()
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("Save Search") {}
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    Button("Show Results") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(.bar)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            content()
        }
    }
}

/// Simple wrapping chip row (For Sale / Price / Beds & Baths / More Filters).
/// Stub buttons only - the web prototype's equivalent pills have no filtering
/// logic wired up either; this just carries the same visual placeholder.
private struct FlowChips: View {
    let labels: [String]

    init(_ labels: [String]) {
        self.labels = labels
    }

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(labels, id: \.self) { label in
                Button(label) {}
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}

/// Minimal wrapping HStack, since SwiftUI has no built-in flow layout prior
/// to composing one from the `Layout` protocol.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
