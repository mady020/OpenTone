import Foundation

final class AICallOrchestrator {

    private let policy: AICallProviderPolicy
    private let providers: [AICallProviderID: AICallLLMProvider]

    init(policy: AICallProviderPolicy, providers: [AICallProviderID: AICallLLMProvider]) {
        self.policy = policy
        self.providers = providers
    }

    func startSession(input: AICallStartInput) async throws -> AICallStartResult {
        let order = providerOrder()

        guard let primaryProvider = providers[policy.primary], primaryProvider.isAvailable() else {
            if policy.requirePrimary && !policy.allowFallbackOnPrimaryFailure {
                throw AICallOrchestratorError.providerUnavailable(policy.primary)
            }
            return try await tryFallbackStartSession(input: input, order: Array(order.dropFirst()))
        }

        do {
            return try await primaryProvider.startSession(input)
        } catch {
            if policy.requirePrimary && !policy.allowFallbackOnPrimaryFailure {
                throw AICallOrchestratorError.providerFailed(policy.primary, error.localizedDescription)
            }
            return try await tryFallbackStartSession(input: input, order: Array(order.dropFirst()))
        }
    }

    func generateTurn(input: AICallTurnInput) async throws -> AICallTurnResult {
        let order = providerOrder()

        guard let primaryProvider = providers[policy.primary], primaryProvider.isAvailable() else {
            if policy.requirePrimary && !policy.allowFallbackOnPrimaryFailure {
                throw AICallOrchestratorError.providerUnavailable(policy.primary)
            }
            return try await tryFallbackTurn(input: input, order: Array(order.dropFirst()))
        }

        do {
            return try await primaryProvider.generateTurn(input)
        } catch {
            if policy.requirePrimary && !policy.allowFallbackOnPrimaryFailure {
                throw AICallOrchestratorError.providerFailed(policy.primary, error.localizedDescription)
            }
            return try await tryFallbackTurn(input: input, order: Array(order.dropFirst()))
        }
    }

    private func providerOrder() -> [AICallProviderID] {
        [policy.primary] + policy.fallbacks
    }

    private func tryFallbackStartSession(input: AICallStartInput, order: [AICallProviderID]) async throws -> AICallStartResult {
        for providerId in order {
            guard let provider = providers[providerId], provider.isAvailable() else { continue }
            do {
                return try await provider.startSession(input)
            } catch {
                continue
            }
        }
        throw AICallOrchestratorError.providerUnavailable(policy.primary)
    }

    private func tryFallbackTurn(input: AICallTurnInput, order: [AICallProviderID]) async throws -> AICallTurnResult {
        for providerId in order {
            guard let provider = providers[providerId], provider.isAvailable() else { continue }
            do {
                return try await provider.generateTurn(input)
            } catch {
                continue
            }
        }
        throw AICallOrchestratorError.providerUnavailable(policy.primary)
    }
}
