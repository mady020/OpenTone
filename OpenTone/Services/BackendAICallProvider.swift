import Foundation

final class BackendAICallProvider: AICallLLMProvider {

    let id: AICallProviderID = .backend

    func isAvailable() -> Bool {
        true
    }

    func startSession(_ input: AICallStartInput) async throws -> AICallStartResult {
        let response = try await BackendSpeechService.shared.chat(messages: [
            BackendChatMessage(role: "system", content: systemPrompt(scenario: input.scenario, difficulty: input.difficulty)),
            BackendChatMessage(role: "user", content: "Start the conversation with a short greeting and one follow-up question.")
        ])
        return AICallStartResult(assistantText: response.text, provider: id)
    }

    func generateTurn(_ input: AICallTurnInput) async throws -> AICallTurnResult {
        var messages: [BackendChatMessage] = [
            BackendChatMessage(role: "system", content: systemPrompt(scenario: input.scenario, difficulty: input.difficulty))
        ]

        messages.append(contentsOf: input.conversationHistory.compactMap { item in
            guard let role = item["role"], let content = item["content"], !content.isEmpty else {
                return nil
            }
            let normalizedRole = role == "assistant" ? "assistant" : "user"
            return BackendChatMessage(role: normalizedRole, content: content)
        })

        messages.append(BackendChatMessage(role: "user", content: input.transcript))

        let response = try await BackendSpeechService.shared.chat(messages: messages)

        let aiText = response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Could you say that again?"
            : response.text

        let correctedAssistantText = UtteranceCorrectionService.shared.applyCorrectionIfNeeded(
            userText: input.transcript,
            assistantText: aiText
        )

        return AICallTurnResult(
            userTranscript: input.transcript,
            assistantText: correctedAssistantText,
            metrics: nil,
            provider: id
        )
    }

    private func systemPrompt(scenario: String, difficulty: String) -> String {
        """
        You are a friendly and encouraging English conversation partner in the OpenTone app.
        Scenario: \(scenario).
        Difficulty: \(difficulty).
        Keep responses to 1-2 short spoken-friendly sentences.
        Gently correct grammar by natural rephrasing and ask follow-up questions to continue the conversation.
        Do not use markdown or emojis.
        """
    }
}
