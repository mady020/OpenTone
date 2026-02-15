import Foundation

/// Production-grade Gemini API service using the REST API.
/// Maintains conversation history and handles multi-turn chat.
/// Uses gemini-1.5-flash on the stable v1 endpoint for best free-tier compatibility.
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
