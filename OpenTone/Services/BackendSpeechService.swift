import Foundation

/// Networking layer for the OpenTone Speech Coach backend.
/// Replaces GeminiService for all speech analysis.
final class BackendSpeechService {

    static let shared = BackendSpeechService()

    private let baseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String, !url.isEmpty {
            return url
        }
        return "http://localhost:8000"
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
        body.append("Content-Type: audio/m4a\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(audio)
        body.append(crlf.data(using: .utf8)!)

        body.append("\(dash)\(boundary)\(dash)\(crlf)".data(using: .utf8)!)
        return body
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

    private static func _rating(fluency: Double) -> SessionFeedbackRating {
        switch fluency {
        case 85...: return .excellent
        case 65...: return .good
        case 45...: return .average
        default:    return .poor
        }
    }
}
