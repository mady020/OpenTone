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
            }
        }
    }

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

    private let modelName = "gemini-2.0-flash"

    private init() {}

    // MARK: - Public API

    /// Send a user message and get an AI response.
    /// Manages conversation history automatically.
    func sendMessage(_ text: String) async throws -> String {
        guard let apiKey = GeminiAPIKeyManager.shared.getAPIKey() else {
            throw GeminiError.noAPIKey
        }

        // Add user message to history
        conversationHistory.append(Message(role: .user, text: text))

        // Build the request
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = buildRequestBody()
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Make the request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiError.networkError(error)
        }

        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            let bodyStr = String(data: data, encoding: .utf8) ?? "No body"
            throw GeminiError.httpError(httpResponse.statusCode, bodyStr)
        }

        // Parse the response
        let replyText = try parseResponse(data)

        // Add model response to history
        conversationHistory.append(Message(role: .model, text: replyText))

        return replyText
    }

    /// Clear conversation history and start fresh.
    func resetConversation() {
        conversationHistory.removeAll()
    }

    // MARK: - Private

    private func buildRequestBody() -> [String: Any] {
        // Build contents array from conversation history
        var contents: [[String: Any]] = []
        for message in conversationHistory {
            contents.append([
                "role": message.role.rawValue,
                "parts": [["text": message.text]]
            ])
        }

        var body: [String: Any] = [
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

        // Add system instruction
        body["systemInstruction"] = [
            "parts": [["text": systemInstruction]]
        ]

        return body
    }

    private func parseResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiError.decodingError("Invalid JSON")
        }

        // Check for block reason
        if let promptFeedback = json["promptFeedback"] as? [String: Any],
           let blockReason = promptFeedback["blockReason"] as? String {
            throw GeminiError.blocked(blockReason)
        }

        // Extract text from candidates
        guard let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first else {
            throw GeminiError.emptyResponse
        }

        // Check finish reason
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
