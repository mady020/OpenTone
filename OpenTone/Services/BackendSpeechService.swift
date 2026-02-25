import Foundation

/// Networking layer for the OpenTone Speech Coach backend.
/// Replaces GeminiService for all speech analysis.
final class BackendSpeechService {

    static let shared = BackendSpeechService()

    // MARK: - Configuration
    // Update this to your deployed backend URL.
    // For local dev: "http://localhost:8000"
    // For staging/production: "https://your-backend.example.com"
    private let baseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String,
           !url.isEmpty {
            return url
        }
        return "http://localhost:8000"
    }()

    enum BackendError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case httpError(Int, String)
        case decodingError(String)
        case noAudioURL

        var errorDescription: String? {
            switch self {
            case .invalidURL:               return "Invalid backend URL."
            case .networkError(let e):      return "Network error: \(e.localizedDescription)"
            case .httpError(let c, let b):  return "Backend error (\(c)): \(b)"
            case .decodingError(let m):     return "Response parse error: \(m)"
            case .noAudioURL:               return "No audio URL provided for analysis."
            }
        }
    }

    private let session = URLSession.shared
    private lazy var decoder: JSONDecoder = JSONDecoder()

    private init() {}

    // MARK: - POST /analyze

    /// Analyse a speech recording and return coaching + progress feedback.
    /// - Parameters:
    ///   - audioURL: Supabase Storage public URL of the recorded audio file.
    ///   - userId: Authenticated user UUID string.
    ///   - sessionId: JAM session UUID string (for Supabase upsert).
    func analyze(
        audioURL: String,
        userId: String,
        sessionId: String
    ) async throws -> SpeechAnalysisResponse {

        guard !audioURL.isEmpty else { throw BackendError.noAudioURL }

        let endpoint = "\(baseURL)/analyze"
        guard let url = URL(string: endpoint) else { throw BackendError.invalidURL }

        let body: [String: String] = [
            "audio_url":  audioURL,
            "user_id":    userId,
            "session_id": sessionId,
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120   // Whisper can take a while
        request.httpBody = try JSONEncoder().encode(body)

        return try await fetchDecoded(request)
    }

    // MARK: - GET /user/profile

    /// Fetch the rolling speech profile for a user.
    func fetchProfile(userId: String) async throws -> UserSpeechProfile {
        let endpoint = "\(baseURL)/user/profile?user_id=\(userId)"
        guard let url = URL(string: endpoint) else { throw BackendError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        return try await fetchDecoded(request)
    }

    // MARK: - POST /tts

    /// Synthesise coaching text via Kokoro TTS.
    /// Returns raw WAV data suitable for AVAudioPlayer.
    func tts(text: String) async throws -> Data {
        let endpoint = "\(baseURL)/tts"
        guard let url = URL(string: endpoint) else { throw BackendError.invalidURL }

        let body = ["text": text]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(body)

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
            throw BackendError.decodingError("Could not decode \(T.self): \(error). Raw: \(raw.prefix(200))")
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

    /// Convert a SpeechAnalysisResponse into the existing Feedback model
    /// so all existing UI cells keep working without modification.
    static func toFeedback(_ response: SpeechAnalysisResponse) -> Feedback {
        let coaching = response.coaching
        let metrics  = response.metrics

        // Map coaching evidence to SpeechMistake for reuse in FeedbackMistakeCell
        let mistakes: [SpeechMistake] = coaching.suggestions.prefix(5).map { suggestion in
            SpeechMistake(
                original:    coaching.primaryIssueTitle,
                correction:  suggestion,
                explanation: coaching.strengths.first ?? ""
            )
        }

        // Persist WPM delta so ProgressCell can show "↑ +8 WPM" on dashboard
        let wpmDelta = response.progress.deltas.wpm
        UserDefaults.standard.set(wpmDelta, forKey: "opentone.lastWpmDelta")

        return Feedback(
            comments:         coaching.strengths.first ?? "Keep practising!",
            rating:           _ratingFrom(fluency: coaching.scores.fluency),
            wordsPerMinute:   metrics.wpm,
            durationInSeconds: metrics.durationS,
            totalWords:       metrics.totalWords,
            transcript:       response.transcript,
            fillerWordCount:  metrics.fillers,
            pauseCount:       metrics.pauses,
            mistakes:         mistakes,
            aiFeedbackSummary: response.progress.weeklySummary,
            coaching:         coaching,
            progress:         response.progress
        )
    }

    private static func _ratingFrom(fluency: Double) -> SessionFeedbackRating {
        switch fluency {
        case 85...: return .excellent
        case 65...: return .good
        case 45...: return .average
        default:    return .poor
        }
    }
}
