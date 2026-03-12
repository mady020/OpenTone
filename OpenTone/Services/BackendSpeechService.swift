import Foundation

/// Networking layer for the OpenTone Speech Coach backend.
/// Replaces GeminiService for all speech analysis.
final class BackendSpeechService {

    static let shared = BackendSpeechService()

    private let baseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String, !url.isEmpty {
            return url
        }
        return "http://44.221.98.186:8000"
    }()

    enum BackendError: LocalizedError {
        case networkError(Error)
        case httpError(Int, String)
        case decodingError(String)
        case noInput

        var errorDescription: String? {
            switch self {
            case .networkError(let e):      return "Network error: \(e.localizedDescription)"
            case .httpError(let c, let b):  return "Backend error (\(c)): \(b)"
            case .decodingError(let m):     return "Parse error: \(m)"
            case .noInput:                  return "No audio or transcript available."
            }
        }
    }

    private let session = URLSession.shared
    private var decoder: JSONDecoder { JSONDecoder() }
    private init() {}

    private struct ChatStartForm: Encodable {
        let mode: String
        let scenario: String
        let difficulty: String
    }

    // MARK: - POST /analyze/audio  (multipart — Whisper path)

    /// Upload raw .m4a to the backend so Whisper transcribes it with real word timestamps.
    func analyzeAudio(
        fileURL:   URL,
        userId:    String,
        sessionId: String
    ) async throws -> SpeechAnalysisResponse {
        guard let url = URL(string: "\(baseURL)/analyze/audio") else {
            throw BackendError.httpError(0, "Invalid URL")
        }

        let boundary = "OpenTone-\(UUID().uuidString)"
        var request  = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180  // Whisper can take 30–90 s on first run

        let audioData = try Data(contentsOf: fileURL)
        request.httpBody = buildMultipart(
            boundary:  boundary,
            audio:     audioData,
            userId:    userId,
            sessionId: sessionId
        )

        return try await fetchDecoded(request)
    }

    private func buildMultipart(boundary: String, audio: Data, userId: String, sessionId: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        let dash = "--"

        func appendText(_ name: String, _ value: String) {
            body.append("\(dash)\(boundary)\(crlf)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\(crlf)\(crlf)".data(using: .utf8)!)
            body.append(value.data(using: .utf8)!)
            body.append(crlf.data(using: .utf8)!)
        }

        appendText("user_id",    userId)
        appendText("session_id", sessionId)

        // Audio file field
        body.append("\(dash)\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\(crlf)".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(audio)
        body.append(crlf.data(using: .utf8)!)

        body.append("\(dash)\(boundary)\(dash)\(crlf)".data(using: .utf8)!)
        return body
    }

    // MARK: - POST /transcribe (Quick whisper-only ASR)

    func transcribe(audioData: Data, userId: String = "demo") async throws -> TranscribeResponse {
        guard let url = URL(string: "\(baseURL)/transcribe") else {
            throw BackendError.httpError(0, "Invalid URL")
        }

        let boundary = "OpenTone-Transcribe-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        var body = Data()
        let crlf = "\r\n"
        let dash = "--"

        // Form field: user_id
        body.append("\(dash)\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\(crlf)\(crlf)".data(using: .utf8)!)
        body.append("\(userId)\(crlf)".data(using: .utf8)!)

        // Audio file field
        body.append("\(dash)\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\(crlf)".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(audioData)
        body.append(crlf.data(using: .utf8)!)

        body.append("\(dash)\(boundary)\(dash)\(crlf)".data(using: .utf8)!)
        request.httpBody = body

        return try await fetchDecoded(request)
    }

    // MARK: - POST /analyze  (JSON transcript fallback)

    /// Analyze speech — prefers audio URL, falls back to transcript+duration.
    func analyze(
        audioURL: String?,
        transcript: String?,
        durationS: Double,
        userId: String,
        sessionId: String
    ) async throws -> SpeechAnalysisResponse {

        guard (audioURL != nil && !(audioURL!.isEmpty)) || (transcript != nil && !(transcript!.isEmpty)) else {
            throw BackendError.noInput
        }

        let body = AnalyzeRequest(
            audioURL:   audioURL?.isEmpty == false ? audioURL : nil,
            transcript: transcript?.isEmpty == false ? transcript : nil,
            durationS:  durationS,
            userId:     userId,
            sessionId:  sessionId
        )

        guard let url = URL(string: "\(baseURL)/analyze") else {
            throw BackendError.httpError(0, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONEncoder().encode(body)

        return try await fetchDecoded(request)
    }

    // MARK: - POST /chat  (1-on-1 AI Call conversation turn)

    func startChat(
        mode: String = "call",
        scenario: String = "",
        difficulty: String = "medium"
    ) async throws -> ChatStartResponse {
        guard let url = URL(string: "\(baseURL)/chat/start") else {
            throw BackendError.httpError(0, "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = formEncodedData(from: ChatStartForm(mode: mode, scenario: scenario, difficulty: difficulty))

        return try await fetchDecoded(request)
    }

    // MARK: - POST /jam/topics  (LLM-generated JAM topic)

    /// Ask the backend to generate a speaking topic + suggestions via Ollama.
    func generateJamTopic() async throws -> JamTopicResponse {
        guard let url = URL(string: "\(baseURL)/jam/topics") else {
            throw BackendError.httpError(0, "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        // No body needed — the backend generates on its own
        request.httpBody = "{}".data(using: .utf8)

        return try await fetchDecoded(request)
    }

    /// Send one audio chunk from the AI Call screen.
    /// Returns the AI's text reply, WAV audio bytes, and per-turn metrics.
    func analyzeChat(
        audioData: Data,
        userId: String,
        mode: String = "call",
        scenario: String = "",
        difficulty: String = "medium",
        conversationHistory: [[String: String]] = []
    ) async throws -> ChatResponse {
        guard let url = URL(string: "\(baseURL)/chat") else {
            throw BackendError.httpError(0, "Invalid URL")
        }

        let boundary = "OpenTone-Chat-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90

        // Encode conversation history as JSON string
        let historyJSON = (try? JSONSerialization.data(withJSONObject: conversationHistory)).flatMap {
            String(data: $0, encoding: .utf8)
        } ?? "[]"

        request.httpBody = buildChatMultipart(
            boundary: boundary,
            audioData: audioData,
            userId: userId,
            mode: mode,
            scenario: scenario,
            difficulty: difficulty,
            historyJSON: historyJSON
        )

        let chatResponse: ChatResponse = try await fetchDecoded(request)

        // Persist WPM delta for dashboard ProgressCell
        UserDefaults.standard.set(chatResponse.metrics.wpm, forKey: "opentone.lastWpmDelta")

        return chatResponse
    }

    private func buildChatMultipart(
        boundary: String,
        audioData: Data,
        userId: String,
        mode: String,
        scenario: String,
        difficulty: String,
        historyJSON: String
    ) -> Data {
        var body = Data()
        let crlf = "\r\n"
        let dash = "--"

        func appendText(_ name: String, _ value: String) {
            body.append("\(dash)\(boundary)\(crlf)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\(crlf)\(crlf)".data(using: .utf8)!)
            body.append(value.data(using: .utf8)!)
            body.append(crlf.data(using: .utf8)!)
        }

        appendText("user_id", userId)
        appendText("mode", mode)
        appendText("scenario", scenario)
        appendText("difficulty", difficulty)
        appendText("conversation_history", historyJSON)

        // Audio field
        body.append("\(dash)\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"chunk.m4a\"\(crlf)".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(audioData)
        body.append(crlf.data(using: .utf8)!)

        body.append("\(dash)\(boundary)\(dash)\(crlf)".data(using: .utf8)!)
        return body
    }

    // MARK: - POST /chat/end-session  (Session-level feedback)

    /// Call when the AI Call or Roleplay session ends.
    /// Sends the last audio chunk + cumulative transcript for full-pipeline feedback.
    func endSession(
        lastAudioData: Data?,
        fullTranscript: String,
        totalDurationS: Double,
        userId: String,
        sessionId: String,
        turnSummaries: [SessionTurnSummary],
        mode: String = "call"
    ) async throws -> SpeechAnalysisResponse {
        guard let url = URL(string: "\(baseURL)/chat/end-session") else {
            throw BackendError.httpError(0, "Invalid URL")
        }

        let boundary = "OpenTone-EndSession-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        var body = Data()
        let crlf = "\r\n"
        let dash = "--"

        func appendText(_ name: String, _ value: String) {
            body.append("\(dash)\(boundary)\(crlf)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\(crlf)\(crlf)".data(using: .utf8)!)
            body.append(value.data(using: .utf8)!)
            body.append(crlf.data(using: .utf8)!)
        }

        appendText("user_id", userId)
        appendText("session_id", sessionId)
        appendText("mode", mode)
        appendText("full_transcript", fullTranscript)
        appendText("total_duration_s", String(totalDurationS))
        appendText("turn_summaries_json", encodeJSONString(turnSummaries))

        // Audio file field — send last chunk or a minimal placeholder
        let audioData = (lastAudioData != nil && lastAudioData!.count > 100) ? lastAudioData! : _minimalWav()
        body.append("\(dash)\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"final.m4a\"\(crlf)".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(audioData)
        body.append(crlf.data(using: .utf8)!)

        body.append("\(dash)\(boundary)\(dash)\(crlf)".data(using: .utf8)!)
        request.httpBody = body

        return try await fetchDecoded(request)
    }

    /// Minimal valid WAV header (44 bytes of silence) used as placeholder when no audio chunk is available.
    private func _minimalWav() -> Data {
        var d = Data()
        d.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        d.append(contentsOf: withUnsafeBytes(of: UInt32(36).littleEndian) { Array($0) }) // file size - 8
        d.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        d.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        d.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // chunk size
        d.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })  // PCM
        d.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })  // mono
        d.append(contentsOf: withUnsafeBytes(of: UInt32(16000).littleEndian) { Array($0) }) // sample rate
        d.append(contentsOf: withUnsafeBytes(of: UInt32(32000).littleEndian) { Array($0) }) // byte rate
        d.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })  // block align
        d.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) }) // bits per sample
        d.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        d.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Array($0) })  // data size
        return d
    }

    // MARK: - GET /user/profile

    func fetchProfile(userId: String) async throws -> UserSpeechProfile {
        guard let url = URL(string: "\(baseURL)/user/profile?user_id=\(userId)") else {
            throw BackendError.httpError(0, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        return try await fetchDecoded(request)
    }

    // MARK: - POST /tts

    func tts(text: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/tts") else {
            throw BackendError.httpError(0, "Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(["text": text])
        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data)
        return data
    }

    // MARK: - Private helpers

    private func fetchDecoded<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw BackendError.networkError(error)
        }
        try validateHTTP(response: response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<binary>"
            throw BackendError.decodingError("\(error). Raw: \(raw.prefix(300))")
        }
    }

    private func validateHTTP(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw BackendError.httpError(http.statusCode, body)
        }
    }

    private func formEncodedData<T: Encodable>(from value: T) -> Data? {
        guard let data = try? JSONEncoder().encode(value),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&="))
        let formString = object.map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let escapedValue = String(describing: value).addingPercentEncoding(withAllowedCharacters: allowed) ?? String(describing: value)
            return "\(escapedKey)=\(escapedValue)"
        }
        .sorted()
        .joined(separator: "&")

        return formString.data(using: .utf8)
    }

    private func encodeJSONString<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}

// MARK: - Feedback bridge

extension BackendSpeechService {

    /// Bridge backend response → existing Feedback model so nav flow is unchanged.
    static func toFeedback(_ r: SpeechAnalysisResponse) -> Feedback {
        // Persist WPM delta for ProgressCell
        UserDefaults.standard.set(r.progress.deltas.wpm, forKey: "opentone.lastWpmDelta")

        let mistakes: [SpeechMistake] = r.coaching.suggestions.prefix(5).enumerated().map { i, s in
            SpeechMistake(
                original:    r.coaching.primaryIssueTitle,
                correction:  s,
                explanation: r.coaching.strengths.first ?? ""
            )
        }

        return Feedback(
            comments:          r.coaching.strengths.first ?? "Keep practising!",
            rating:            _rating(fluency: r.coaching.scores.fluency),
            wordsPerMinute:    r.metrics.wpm,
            durationInSeconds: r.metrics.durationS,
            totalWords:        r.metrics.totalWords,
            transcript:        r.transcript,
            fillerWordCount:   r.metrics.fillers,
            pauseCount:        r.metrics.pauses,
            mistakes:          mistakes,
            aiFeedbackSummary: r.progress.weeklySummary,
            coaching:          r.coaching,
            progress:          r.progress
        )
    }

    /// Convert a backend response into a SessionFeedback record suitable for persisting in an Activity.
    static func toSessionFeedback(_ r: SpeechAnalysisResponse, sessionId: UUID) -> SessionFeedback {
        return SessionFeedback(
            id: UUID().uuidString,
            sessionId: sessionId,
            fillerWordCount: r.metrics.fillers,
            mispronouncedWords: [],
            fluencyScore: r.coaching.scores.fluency,
            onTopicScore: r.coaching.scores.clarity,
            pauses: r.metrics.pauses,
            summary: r.progress.weeklySummary,
            createdAt: Date()
        )
    }

    private static func _rating(fluency: Double) -> SessionFeedbackRating {
        switch fluency {
        case 85...: return .excellent
        case 65...: return .good
        case 45...: return .average
        default:    return .poor
        }
    }
}
