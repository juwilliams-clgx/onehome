import Foundation
import AVFoundation

enum RealtimeVoiceState {
    case idle
    case connecting
    case listening
    case error
}

/// Manages a live voice-to-voice session with OpenAI's Realtime API over a
/// direct WebSocket connection - not WebRTC. iOS has no built-in WebRTC
/// framework, and pulling in a third-party implementation (e.g. Google's
/// WebRTC via SPM) would be this app's first external dependency ever; a
/// direct WebSocket + AVAudioEngine is fully achievable with Apple's own
/// frameworks, and is the transport OpenAI itself documents for non-browser
/// clients (WebRTC is specifically tuned for browser audio-routing quirks
/// like echo cancellation across tabs, which don't apply to a native app).
///
/// Captures mic audio, converts it to 24kHz mono PCM16, and streams it as
/// base64 `input_audio_buffer.append` events; plays back the model's
/// streamed `response.audio.delta` chunks through a second audio graph node.
/// Shares the same ephemeral-token backend endpoint and event vocabulary as
/// the web prototype's WebRTC implementation (AiSearchService.ts) - only the
/// transport and audio plumbing differ.
///
/// Syntax- and structurally-validated only (`swiftc -parse`, no Xcode
/// available in this environment) - the exact audio format assumptions,
/// buffer sizing, and the live round trip need confirming on a real device
/// with a real OPENAI_API_KEY before this is considered working, not just
/// written.
@MainActor
final class RealtimeVoiceSession {
    private static let socketURL = URL(string: "wss://api.openai.com/v1/realtime?model=gpt-realtime")!
    private static let sampleRate: Double = 24_000

    private let urlSession = URLSession(configuration: .default)
    private var task: URLSessionWebSocketTask?
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var inputConverter: AVAudioConverter?
    private var playbackFormat: AVAudioFormat?

    var onTranscript: ((AIChatMessage.Role, String) -> Void)?
    var onFunctionCall: ((_ name: String, _ argumentsJSON: String, _ callId: String) -> Void)?
    var onStateChange: ((RealtimeVoiceState) -> Void)?
    var onError: ((String) -> Void)?

    func start(ephemeralKey: String) async throws {
        onStateChange?(.connecting)

        var request = URLRequest(url: Self.socketURL)
        request.setValue("Bearer \(ephemeralKey)", forHTTPHeaderField: "Authorization")
        let task = urlSession.webSocketTask(with: request)
        self.task = task
        task.resume()

        try startAudioGraph()
        receiveLoop()
        onStateChange?(.listening)
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        playerNode.stop()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        onStateChange?(.idle)
    }

    /// Sends the executed function's result back to the model and asks it to
    /// continue speaking (e.g. "Found 3 homes...") - called by AISearchStore
    /// after it POSTs the tool call to the shared /api/apply-filters
    /// endpoint, same as the text-chat path.
    func sendFunctionCallOutput(callId: String, output: String) {
        send([
            "type": "conversation.item.create",
            "item": ["type": "function_call_output", "call_id": callId, "output": output],
        ])
        send(["type": "response.create"])
    }

    // MARK: - Audio capture (mic -> WebSocket)

    private func startAudioGraph() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Self.sampleRate, channels: 1, interleaved: true) else {
            throw RealtimeVoiceError.unsupportedAudioFormat
        }
        playbackFormat = targetFormat

        let input = audioEngine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        inputConverter = AVAudioConverter(from: inputFormat, to: targetFormat)

        input.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            self?.forwardMicBuffer(buffer, targetFormat: targetFormat)
        }

        audioEngine.attach(playerNode)
        // AVAudioPlayerNode documents support for integer PCM formats, but most
        // real-world AVAudioEngine graphs process Float32 internally - if audio
        // playback is garbled/silent on a real device, converting to Float32
        // before scheduling (instead of connecting at Int16 directly) is the
        // first thing to try.
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: targetFormat)

        audioEngine.prepare()
        try audioEngine.start()
        playerNode.play()
    }

    private func forwardMicBuffer(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        guard let converter = inputConverter else { return }

        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
        guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var bufferConsumed = false
        var conversionError: NSError?
        converter.convert(to: converted, error: &conversionError) { _, inputStatus in
            if bufferConsumed {
                inputStatus.pointee = .noDataNow
                return nil
            }
            bufferConsumed = true
            inputStatus.pointee = .haveData
            return buffer
        }
        guard conversionError == nil, let channelData = converted.int16ChannelData else { return }

        let frameLength = Int(converted.frameLength)
        guard frameLength > 0 else { return }
        let audioData = Data(bytes: channelData[0], count: frameLength * MemoryLayout<Int16>.size)
        send(["type": "input_audio_buffer.append", "audio": audioData.base64EncodedString()])
    }

    // MARK: - Audio playback (WebSocket -> speaker)

    private func playAudioChunk(base64: String) {
        guard let data = Data(base64Encoded: base64), let format = playbackFormat else { return }
        let frameCount = UInt32(data.count / MemoryLayout<Int16>.size)
        guard frameCount > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        data.withUnsafeBytes { raw in
            guard let base = raw.baseAddress, let channel = buffer.int16ChannelData else { return }
            channel[0].update(from: base.assumingMemoryBound(to: Int16.self), count: Int(frameCount))
        }
        playerNode.scheduleBuffer(buffer)
    }

    // MARK: - WebSocket event loop

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                switch result {
                case .failure(let error):
                    self.onError?(error.localizedDescription)
                    self.onStateChange?(.error)
                case .success(let message):
                    if case .string(let text) = message, let data = text.data(using: .utf8) {
                        self.handleEvent(data)
                    }
                    self.receiveLoop()
                }
            }
        }
    }

    /// Server events arriving over the WebSocket - see https://platform.openai.com/docs/guides/realtime
    private func handleEvent(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "conversation.item.input_audio_transcription.completed":
            if let transcript = json["transcript"] as? String {
                onTranscript?(.user, transcript)
            }

        case "response.audio_transcript.done":
            if let transcript = json["transcript"] as? String {
                onTranscript?(.assistant, transcript)
            }

        case "response.audio.delta":
            if let base64 = json["delta"] as? String {
                playAudioChunk(base64: base64)
            }

        case "response.done":
            guard let response = json["response"] as? [String: Any],
                  let output = response["output"] as? [[String: Any]] else { return }
            for item in output where item["type"] as? String == "function_call" {
                guard let name = item["name"] as? String,
                      let arguments = item["arguments"] as? String,
                      let callId = item["call_id"] as? String
                else { continue }
                onFunctionCall?(name, arguments, callId)
            }

        case "error":
            if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
                onError?(message)
            }

        default:
            break
        }
    }

    private func send(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8)
        else { return }
        task?.send(.string(text)) { _ in }
    }
}

enum RealtimeVoiceError: Error {
    case unsupportedAudioFormat
    case serverError(String)
}
