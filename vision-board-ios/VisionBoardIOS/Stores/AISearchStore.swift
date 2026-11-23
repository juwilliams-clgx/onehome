import Foundation
import Observation

/// One turn in the conversational search transcript.
struct AIChatMessage: Identifiable, Hashable {
    enum Role: String {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let content: String
}

/// Request/response payloads for POST /api/ai-search (server/index.js).
private struct AISearchRequestMessage: Encodable {
    let role: String
    let content: String
}

private struct AISearchRequestBody: Encodable {
    let messages: [AISearchRequestMessage]
}

private struct AISearchResponseBody: Decodable {
    let reply: String
    let filters: [String]?
    let matchingIds: [String]?
}

/// POC conversational search, mirroring a ChatGPT-style chat mode and the web
/// prototype's AiSearchService. Talks to the new server/ Express backend
/// (server/index.js) rather than calling an LLM directly from the app, since
/// that would expose the API key to anyone who inspected network traffic or
/// decompiled the binary. The backend turns natural language into a
/// structured filter object (via OpenAI tool calling) and applies it
/// deterministically against the shared mock listings dataset, then returns
/// both a conversational reply and the resulting listing ids - this store
/// just relays that round trip for the panel and browse view to read.
@Observable
final class AISearchStore {
    private static let endpoint = URL(string: "http://localhost:4300/api/ai-search")!
    private static let greeting = AIChatMessage(
        role: .assistant,
        content: "Hi! Tell me what you're looking for \u{2014} price range, bedrooms, a city, anything \u{2014} and I'll narrow down the results for you."
    )

    var isOpen = false
    private(set) var messages: [AIChatMessage] = []
    private(set) var sending = false
    /// Short chip labels describing the currently-applied filters, e.g. "3+ bd", "< $900K".
    private(set) var activeFilters: [String] = []
    /// nil = show every listing; otherwise restrict the browse view to just these ids.
    private(set) var visibleListingIDs: [String]?

    func open() {
        isOpen = true
        if messages.isEmpty {
            messages = [Self.greeting]
        }
    }

    func close() {
        isOpen = false
    }

    @MainActor
    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !sending else { return }

        messages.append(AIChatMessage(role: .user, content: trimmed))
        sending = true
        defer { sending = false }

        do {
            var request = URLRequest(url: Self.endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = AISearchRequestBody(messages: messages.map { AISearchRequestMessage(role: $0.role.rawValue, content: $0.content) })
            request.httpBody = try JSONEncoder().encode(body)

            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(AISearchResponseBody.self, from: data)

            messages.append(AIChatMessage(role: .assistant, content: decoded.reply))
            activeFilters = decoded.filters ?? []
            visibleListingIDs = decoded.matchingIds
        } catch {
            messages.append(AIChatMessage(role: .assistant, content: "I couldn't reach the AI search service \u{2014} is the server running?"))
        }
    }

    /// Clears the applied filters (back to showing every listing) without touching the transcript.
    func clearFilters() {
        activeFilters = []
        visibleListingIDs = nil
    }
}
