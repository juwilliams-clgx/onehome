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
///
/// Voice mode is the real thing, not speech-to-text bolted onto the text
/// path above: it opens a live session directly with OpenAI's Realtime API
/// (true voice-to-voice, the same technology behind ChatGPT's voice mode)
/// via `RealtimeVoiceSession`, using a short-lived ephemeral token minted by
/// the backend so the real API key never reaches the device. Function calls
/// the model makes mid-conversation are executed by the same backend tool
/// executor the text path uses (POST /api/apply-filters), and update the
/// exact same activeFilters/visibleListingIDs properties - so the browse
/// view filters identically regardless of whether the user typed or spoke.
@Observable
final class AISearchStore {
    private static let endpoint = URL(string: "http://localhost:4300/api/ai-search")!
    private static let realtimeSessionEndpoint = URL(string: "http://localhost:4300/api/realtime-session")!
    private static let applyFiltersEndpoint = URL(string: "http://localhost:4300/api/apply-filters")!
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

    private(set) var voiceState: RealtimeVoiceState = .idle
    private(set) var voiceError: String?
    private var voiceSession: RealtimeVoiceSession?

    func open() {
        isOpen = true
        if messages.isEmpty {
            messages = [Self.greeting]
        }
    }

    @MainActor
    func close() {
        isOpen = false
        stopVoice()
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

    // MARK: - Voice mode (OpenAI Realtime API over WebSocket)

    @MainActor
    func startVoice() {
        guard voiceState != .connecting, voiceState != .listening else { return }
        voiceError = nil

        let session = RealtimeVoiceSession()
        voiceSession = session

        session.onStateChange = { [weak self] state in
            self?.voiceState = state
        }
        session.onError = { [weak self] message in
            self?.voiceError = message
        }
        session.onTranscript = { [weak self] role, transcript in
            self?.messages.append(AIChatMessage(role: role, content: transcript))
        }
        session.onFunctionCall = { [weak self] name, argumentsJSON, callId in
            Task { @MainActor in
                await self?.handleVoiceFunctionCall(name: name, argumentsJSON: argumentsJSON, callId: callId)
            }
        }

        Task { @MainActor in
            do {
                var request = URLRequest(url: Self.realtimeSessionEndpoint)
                request.httpMethod = "POST"
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
                    throw RealtimeVoiceError.serverError(message ?? "Could not start a voice session.")
                }
                let tokenResponse = try JSONDecoder().decode(RealtimeSessionResponse.self, from: data)
                try await session.start(ephemeralKey: tokenResponse.value)
            } catch {
                voiceState = .error
                voiceError = (error as? RealtimeVoiceError)?.message ?? "Could not start voice mode."
                voiceSession = nil
            }
        }
    }

    @MainActor
    func stopVoice() {
        voiceSession?.stop()
        voiceSession = nil
        if voiceState != .error {
            voiceState = .idle
        }
    }

    @MainActor
    private func handleVoiceFunctionCall(name: String, argumentsJSON: String, callId: String) async {
        do {
            var request = URLRequest(url: Self.applyFiltersEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let argsData = argumentsJSON.data(using: .utf8) ?? Data("{}".utf8)
            let argsObject = (try? JSONSerialization.jsonObject(with: argsData)) ?? [String: Any]()
            request.httpBody = try JSONSerialization.data(withJSONObject: ["name": name, "arguments": argsObject])

            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(ApplyFiltersResponse.self, from: data)

            activeFilters = result.filters ?? []
            visibleListingIDs = result.matchingIds

            let output = try JSONEncoder().encode(FunctionCallOutputPayload(matchCount: result.matchCount, matches: result.matchSummaries))
            voiceSession?.sendFunctionCallOutput(callId: callId, output: String(data: output, encoding: .utf8) ?? "{}")
        } catch {
            voiceError = "Couldn't apply that filter."
        }
    }
}

private struct RealtimeSessionResponse: Decodable {
    let value: String
}

private struct ApplyFiltersResponse: Decodable {
    let filters: [String]?
    let matchingIds: [String]?
    let matchCount: Int
    let matchSummaries: [String]
}

private struct FunctionCallOutputPayload: Encodable {
    let matchCount: Int
    let matches: [String]
}

extension RealtimeVoiceError {
    var message: String {
        switch self {
        case .unsupportedAudioFormat: return "This device doesn't support the required audio format."
        case .serverError(let message): return message
        }
    }
}
