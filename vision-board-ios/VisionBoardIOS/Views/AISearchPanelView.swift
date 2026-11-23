import SwiftUI

/// Conversational search sheet - a ChatGPT-style chat mode for narrowing
/// down listings, opened from the search header's existing sparkle button
/// (previously a stub comment: "Stub, matching the web's placeholder AI
/// search action"). Presented as a sheet rather than replacing
/// ListingsBrowseView, so the grid keeps updating live underneath and the
/// understood criteria stay visible as removable chips - the filtering
/// stays transparent instead of being a black box inside the conversation.
struct AISearchPanelView: View {
    @Environment(AISearchStore.self) private var aiSearch
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !aiSearch.activeFilters.isEmpty {
                    filterChips
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(aiSearch.messages) { message in
                                bubble(for: message).id(message.id)
                            }
                            if aiSearch.sending {
                                thinkingBubble
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: aiSearch.messages.count) {
                        if let lastID = aiSearch.messages.last?.id {
                            withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                        }
                    }
                }

                inputRow
            }
            .navigationTitle("AI Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { aiSearch.close() }
                }
            }
        }
    }

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(aiSearch.activeFilters, id: \.self) { chip in
                Text(chip)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.075, green: 0.478, blue: 0.561))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.918, green: 0.965, blue: 0.957), in: Capsule())
            }
            Spacer()
            Button("Clear") { aiSearch.clearFilters() }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func bubble(for message: AIChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            Text(message.content)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.role == .user ? Color(red: 0.271, green: 0.467, blue: 0.714) : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .foregroundStyle(message.role == .user ? .white : .primary)

            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    private var thinkingBubble: some View {
        HStack(spacing: 4) {
            ProgressView().controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inputRow: some View {
        HStack(spacing: 10) {
            TextField("e.g. 3 bedroom homes under $900K in Austin", text: $draft)
                .textFieldStyle(.roundedBorder)
                .disabled(aiSearch.sending)
                .onSubmit { send() }

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(aiSearch.sending || draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(.bar)
    }

    private func send() {
        let text = draft
        draft = ""
        Task { await aiSearch.send(text) }
    }
}
