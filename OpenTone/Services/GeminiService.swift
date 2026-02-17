import Foundation

/// Production-grade Gemini API service using the REST API.
/// Maintains conversation history and handles multi-turn chat.
final class GeminiService {

    static let shared = GeminiService()

    // MARK: - Types

    struct Message {
        let role: Role
        let text: String

        enum Role: String {
            case user
            case model
        }
    }

    enum GeminiError: LocalizedError {
        case noAPIKey
        case invalidURL
        case networkError(Error)
        case httpError(Int, String)
        case decodingError(String)
        case emptyResponse
        case blocked(String)
        case rateLimited          // 429 — transient, can retry
        case quotaExhausted       // 429 — hard limit, need plan upgrade

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No Gemini API key configured. Add your key in Settings."
            case .invalidURL:
                return "Invalid API URL."
            case .networkError(let err):
                return "Network error: \(err.localizedDescription)"
            case .httpError(let code, let body):
                return "API error (\(code)): \(body)"
            case .decodingError(let msg):
                return "Failed to parse response: \(msg)"
            case .emptyResponse:
                return "Gemini returned an empty response."
            case .blocked(let reason):
                return "Response blocked: \(reason)"
            case .rateLimited:
                return "Rate limited. Please wait a moment and try again."
            case .quotaExhausted:
                return "API quota exhausted. Check your Gemini plan and billing."
            }
        }
    }

    // MARK: - Configuration

    /// Models to try in order of preference. Falls back to the next if the
    /// current one returns a quota error (limit: 0 means no free tier).
    private let modelCandidates = [
        "gemini-2.5-flash",
        "gemini-2.0-flash",
        "gemini-1.5-flash"
    ]

    /// The currently selected model index.
    private var currentModelIndex = 0

    /// v1beta supports the latest models (2.5, 2.0).
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    /// Maximum automatic retries on transient 429 errors.
    private let maxRetries = 2

    // MARK: - State

    private(set) var conversationHistory: [Message] = []

    private let systemInstruction: String = """
    You are a friendly and encouraging English conversation partner in the OpenTone language learning app. \
    Your goal is to help users practice speaking English naturally. \
    Keep responses conversational, concise (2-3 sentences max), and at an appropriate level for language learners. \
    Ask follow-up questions to keep the conversation going. \
    Gently correct any grammar mistakes by naturally rephrasing what the user said. \
    Be warm, patient, and supportive. Do not use markdown formatting or emojis in your responses \
    since your text will be spoken aloud via text-to-speech.
    """

    private init() {}

    // MARK: - Public API

    /// Send a user message and get an AI response.
    /// Manages conversation history automatically. Retries on transient 429s
    /// and falls back to alternate models when a model has no free-tier quota.
    func sendMessage(_ text: String) async throws -> String {
        guard let apiKey = GeminiAPIKeyManager.shared.getAPIKey() else {
            throw GeminiError.noAPIKey
        }

        // Add user message to history
        conversationHistory.append(Message(role: .user, text: text))

        var lastError: Error = GeminiError.emptyResponse

        // Try each model candidate starting from the current one
        let startIndex = currentModelIndex
        for offset in 0..<modelCandidates.count {
            let modelIndex = (startIndex + offset) % modelCandidates.count
            let model = modelCandidates[modelIndex]

            do {
                let reply = try await callGemini(model: model, apiKey: apiKey)

                // Success — remember this model for next time
                currentModelIndex = modelIndex
                conversationHistory.append(Message(role: .model, text: reply))
                return reply
            } catch GeminiError.quotaExhausted {
                // This model has no quota — try the next one
                print("⚠️ \(model) quota exhausted, trying next model...")
                lastError = GeminiError.quotaExhausted
                continue
            } catch {
                // Remove the user message we optimistically added
                if conversationHistory.last?.role == .user {
                    conversationHistory.removeLast()
                }
                throw error
            }
        }

        // All models exhausted
        if conversationHistory.last?.role == .user {
            conversationHistory.removeLast()
        }
        throw lastError
    }

    /// Clear conversation history and start fresh.
    func resetConversation() {
        conversationHistory.removeAll()
        currentModelIndex = 0
    }

    /// Generate conversation starter questions based on peer interests.
    /// This is a one-shot call — does NOT affect conversation history.
    func generateQuestions(for interests: [String], peerName: String) async throws -> [String] {
        guard let apiKey = GeminiAPIKeyManager.shared.getAPIKey() else {
            throw GeminiError.noAPIKey
        }

        let interestList = interests.joined(separator: ", ")
        let prompt = """
        You are helping a language learner prepare conversation starters for a practice call with \(peerName).
        Their interests include: \(interestList).

        Generate exactly 4 short, friendly conversation starter questions based on these interests.
        Each question should be 5-12 words, natural and easy for a beginner/intermediate English learner.
        Return ONLY the 4 questions, one per line. No numbering, no bullets, no extra text.
        """

        let body = buildOneShotBody(prompt: prompt)
        var lastError: Error = GeminiError.emptyResponse

        for offset in 0..<modelCandidates.count {
            let modelIndex = (currentModelIndex + offset) % modelCandidates.count
            let model = modelCandidates[modelIndex]

            let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
            guard let url = URL(string: urlString) else { throw GeminiError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    let bodyStr = String(data: data, encoding: .utf8) ?? ""
                    if http.statusCode == 429 && (bodyStr.contains("limit: 0") || bodyStr.contains("RESOURCE_EXHAUSTED")) {
                        lastError = GeminiError.quotaExhausted
                        continue
                    }
                    throw GeminiError.httpError(http.statusCode, bodyStr)
                }

                let text = try parseResponse(data)
                let lines = text.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .map { line in
                        // Strip leading numbering like "1.", "1)", "- " etc.
                        var cleaned = line
                            .replacingOccurrences(of: #"^\d+[\.\)]\s*"#, with: "", options: .regularExpression)
                            .replacingOccurrences(of: #"^[-•]\s*"#, with: "", options: .regularExpression)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        // Ensure every question ends with a question mark
                        if !cleaned.isEmpty && !cleaned.hasSuffix("?") {
                            cleaned += "?"
                        }
                        return cleaned
                    }
                    .filter { !$0.isEmpty }

                return Array(lines.prefix(4))
            } catch GeminiError.quotaExhausted {
                lastError = GeminiError.quotaExhausted
                continue
            } catch {
                throw error
            }
        }

        throw lastError
    }

    /// Generate a random JAM topic and speaking hints using Gemini.
    /// Returns a tuple of (topic, [hints]). One-shot — does NOT affect conversation history.
    func generateJamTopic() async throws -> (topic: String, hints: [String]) {
        guard let apiKey = GeminiAPIKeyManager.shared.getAPIKey() else {
            throw GeminiError.noAPIKey
        }

        let prompt = """
        You are a creative topic generator for an English speaking practice app called "2-Minute JAM". \
        The user will speak about the topic for 2 minutes to practice fluency.

        Generate 1 interesting, specific topic and 6 short hint phrases to help the speaker.

        Rules:
        - The topic should be engaging, thought-provoking, and accessible to intermediate English learners.
        - Avoid generic topics like "Technology" — be specific, e.g. "How Social Media Changed Friendships".
        - Each hint should be 2-5 words — a quick talking point, NOT a full sentence.
        - Return EXACTLY this format (no extra text, no numbering, no bullets):

        TOPIC: <topic here>
        HINT: <hint 1>
        HINT: <hint 2>
        HINT: <hint 3>
        HINT: <hint 4>
        HINT: <hint 5>
        HINT: <hint 6>
        """

        let body = buildOneShotBody(prompt: prompt)
        var lastError: Error = GeminiError.emptyResponse

        for offset in 0..<modelCandidates.count {
            let modelIndex = (currentModelIndex + offset) % modelCandidates.count
            let model = modelCandidates[modelIndex]

            let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
            guard let url = URL(string: urlString) else { throw GeminiError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    let bodyStr = String(data: data, encoding: .utf8) ?? ""
                    if http.statusCode == 429 && (bodyStr.contains("limit: 0") || bodyStr.contains("RESOURCE_EXHAUSTED")) {
                        lastError = GeminiError.quotaExhausted
                        continue
                    }
                    throw GeminiError.httpError(http.statusCode, bodyStr)
                }

                let text = try parseResponse(data)
                return parseJamTopicResponse(text)
            } catch GeminiError.quotaExhausted {
                lastError = GeminiError.quotaExhausted
                continue
            } catch {
                throw error
            }
        }

        throw lastError
    }

    /// Parse the structured TOPIC:/HINT: response from Gemini.
    private func parseJamTopicResponse(_ text: String) -> (topic: String, hints: [String]) {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var topic = "Interesting Ideas"
        var hints: [String] = []

        for line in lines {
            if line.uppercased().hasPrefix("TOPIC:") {
                topic = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.uppercased().hasPrefix("HINT:") {
                let hint = String(line.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !hint.isEmpty { hints.append(hint) }
            }
        }

        // Ensure we have at least some hints
        if hints.isEmpty {
            hints = ["key challenges", "real-world examples", "personal experience",
                     "future outlook", "common opinions", "surprising facts"]
        }

        return (topic, Array(hints.prefix(6)))
    }

    private func buildOneShotBody(prompt: String) -> [String: Any] {
        return [
            "contents": [
                ["role": "user", "parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.9,
                "maxOutputTokens": 200
            ]
        ]
    }

    private func buildOneShotBody(prompt: String, maxTokens: Int) -> [String: Any] {
        return [
            "contents": [
                ["role": "user", "parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": maxTokens
            ]
        ]
    }

    // MARK: - JAM Feedback Analysis

    /// Analyze a user's speech transcript and return structured feedback.
    /// One-shot call — does NOT affect conversation history.
    func generateJamFeedback(transcript: String, topic: String, durationSeconds: Double) async throws -> Feedback {
        guard let apiKey = GeminiAPIKeyManager.shared.getAPIKey() else {
            throw GeminiError.noAPIKey
        }

        let prompt = """
        You are an expert English speech coach. A language learner just spoke about "\(topic)" for \(Int(durationSeconds)) seconds.

        Here is their transcript:
        ---
        \(transcript)
        ---

        Analyze their speech and return your analysis in EXACTLY this format (no markdown, no extra text):

        RATING: <excellent|good|average|poor>
        WORDS_PER_MINUTE: <number>
        TOTAL_WORDS: <number>
        FILLER_WORDS: <number of filler words like um, uh, like, you know>
        PAUSES: <estimated pauses>
        COMMENTS: <1-2 sentence overall feedback>
        MISTAKE: <what they said> ||| <correction> ||| <brief explanation>
        MISTAKE: <what they said> ||| <correction> ||| <brief explanation>
        MISTAKE: <what they said> ||| <correction> ||| <brief explanation>
        SUMMARY: <2-3 sentence detailed feedback on fluency, grammar, vocabulary, and confidence>

        Rules:
        - List 0-5 MISTAKE lines. Only include real grammar/vocabulary/pronunciation issues found in the transcript.
        - If the transcript is very short or empty, rate as "poor" and note that the user should try speaking more.
        - WORDS_PER_MINUTE should be calculated from TOTAL_WORDS and the duration.
        - Be encouraging but honest.
        """

        let body = buildOneShotBody(prompt: prompt, maxTokens: 600)
        var lastError: Error = GeminiError.emptyResponse

        for offset in 0..<modelCandidates.count {
            let modelIndex = (currentModelIndex + offset) % modelCandidates.count
            let model = modelCandidates[modelIndex]

            let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
            guard let url = URL(string: urlString) else { throw GeminiError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 20
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    let bodyStr = String(data: data, encoding: .utf8) ?? ""
                    if http.statusCode == 429 && (bodyStr.contains("limit: 0") || bodyStr.contains("RESOURCE_EXHAUSTED")) {
                        lastError = GeminiError.quotaExhausted
                        continue
                    }
                    throw GeminiError.httpError(http.statusCode, bodyStr)
                }

                let text = try parseResponse(data)
                return parseJamFeedbackResponse(text, transcript: transcript, durationSeconds: durationSeconds)
            } catch GeminiError.quotaExhausted {
                lastError = GeminiError.quotaExhausted
                continue
            } catch {
                throw error
            }
        }

        throw lastError
    }

    /// Parse the structured feedback response from Gemini.
    private func parseJamFeedbackResponse(_ text: String, transcript: String, durationSeconds: Double) -> Feedback {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var rating: SessionFeedbackRating = .average
        var wpm: Double = 0
        var totalWords: Int = 0
        var fillerWords: Int = 0
        var pauses: Int = 0
        var comments = "Keep practicing!"
        var mistakes: [SpeechMistake] = []
        var summary = ""

        for line in lines {
            let upper = line.uppercased()
            if upper.hasPrefix("RATING:") {
                let val = String(line.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                rating = SessionFeedbackRating(rawValue: val) ?? .average
            } else if upper.hasPrefix("WORDS_PER_MINUTE:") {
                wpm = Double(String(line.dropFirst(17)).trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            } else if upper.hasPrefix("TOTAL_WORDS:") {
                totalWords = Int(String(line.dropFirst(12)).trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            } else if upper.hasPrefix("FILLER_WORDS:") {
                fillerWords = Int(String(line.dropFirst(13)).trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            } else if upper.hasPrefix("PAUSES:") {
                pauses = Int(String(line.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            } else if upper.hasPrefix("COMMENTS:") {
                comments = String(line.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if upper.hasPrefix("MISTAKE:") {
                let parts = String(line.dropFirst(8))
                    .components(separatedBy: "|||")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                if parts.count >= 3 {
                    mistakes.append(SpeechMistake(
                        original: parts[0],
                        correction: parts[1],
                        explanation: parts[2]
                    ))
                }
            } else if upper.hasPrefix("SUMMARY:") {
                summary = String(line.dropFirst(8)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Fallback calculations
        if totalWords == 0 {
            totalWords = transcript.split(separator: " ").count
        }
        if wpm == 0 && durationSeconds > 0 {
            wpm = Double(totalWords) / (durationSeconds / 60.0)
        }

        return Feedback(
            comments: comments,
            rating: rating,
            wordsPerMinute: wpm,
            durationInSeconds: durationSeconds,
            totalWords: totalWords,
            transcript: transcript,
            fillerWordCount: fillerWords,
            pauseCount: pauses,
            mistakes: mistakes,
            aiFeedbackSummary: summary.isEmpty ? nil : summary
        )
    }

    // MARK: - Private — Network

    private func callGemini(model: String, apiKey: String, attempt: Int = 0) async throws -> String {
        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = buildRequestBody()
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiError.networkError(error)
        }

        // Handle HTTP errors
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""

            if http.statusCode == 429 {
                // Distinguish hard quota exhaustion (limit: 0) from transient rate limits
                if bodyStr.contains("limit: 0") || bodyStr.contains("RESOURCE_EXHAUSTED") && bodyStr.contains("limit: 0") {
                    throw GeminiError.quotaExhausted
                }

                // Transient rate limit — retry with exponential backoff
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt)) // 1s, 2s
                    print("⏳ Rate limited, retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries))")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await callGemini(model: model, apiKey: apiKey, attempt: attempt + 1)
                }

                throw GeminiError.rateLimited
            }

            // 400 with "not found" likely means the model name is invalid for this API version
            if http.statusCode == 404 || (http.statusCode == 400 && bodyStr.contains("not found")) {
                throw GeminiError.quotaExhausted  // triggers fallback to next model
            }

            throw GeminiError.httpError(http.statusCode, bodyStr)
        }

        return try parseResponse(data)
    }

    // MARK: - Private — Request Body

    private func buildRequestBody() -> [String: Any] {
        var contents: [[String: Any]] = []

        // Inject system instruction as the first user/model exchange
        // since the v1 endpoint doesn't support the systemInstruction field.
        contents.append([
            "role": "user",
            "parts": [["text": systemInstruction]]
        ])
        contents.append([
            "role": "model",
            "parts": [["text": "Understood! I'm ready to chat. How are you doing today?"]]
        ])

        for message in conversationHistory {
            contents.append([
                "role": message.role.rawValue,
                "parts": [["text": message.text]]
            ])
        }

        let body: [String: Any] = [
            "contents": contents,
            "safetySettings": [
                ["category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"],
                ["category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"],
                ["category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"],
                ["category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topP": 0.9,
                "topK": 40,
                "maxOutputTokens": 200
            ]
        ]

        return body
    }

    // MARK: - Private — Response Parsing

    private func parseResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiError.decodingError("Invalid JSON")
        }

        if let promptFeedback = json["promptFeedback"] as? [String: Any],
           let blockReason = promptFeedback["blockReason"] as? String {
            throw GeminiError.blocked(blockReason)
        }

        guard let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first else {
            throw GeminiError.emptyResponse
        }

        if let finishReason = first["finishReason"] as? String,
           finishReason == "SAFETY" {
            throw GeminiError.blocked("Safety filter triggered")
        }

        guard let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let textPart = parts.first,
              let text = textPart["text"] as? String,
              !text.isEmpty else {
            throw GeminiError.emptyResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
