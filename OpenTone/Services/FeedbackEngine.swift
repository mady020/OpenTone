import Foundation

enum FeedbackSessionMode: String {
    case jam
    case aiCall
    case roleplay
}

struct FeedbackEngineInput {
    let transcript: String
    let topic: String
    let durationS: Double
    let userId: String
    let sessionId: String
    let mode: FeedbackSessionMode
    let turnSummaries: [SessionTurnSummary]
    /// Optional audio URL for acoustic pronunciation analysis
    var audioURL: URL?
    /// Optional expected text for pronunciation scoring (when known)
    var expectedText: String?
}

protocol FeedbackEngine {
    func analyze(_ input: FeedbackEngineInput) async -> SpeechAnalysisResponse
}

protocol RemoteFeedbackProvider {
    var name: String { get }
    func isAvailable() -> Bool
    func enhance(_ base: SpeechAnalysisResponse, input: FeedbackEngineInput) async throws -> SpeechAnalysisResponse
}

struct FeedbackEnginePolicy {
    static func fromConfig() -> FeedbackEnginePolicy {
        FeedbackEnginePolicy()
    }
}

final class FeedbackEngineCoordinator: FeedbackEngine {

    private let coreEngine: FeedbackEngine
    private let remoteProviders: [RemoteFeedbackProvider]

    init(coreEngine: FeedbackEngine, remoteProviders: [RemoteFeedbackProvider]) {
        self.coreEngine = coreEngine
        self.remoteProviders = remoteProviders
    }

    func analyze(_ input: FeedbackEngineInput) async -> SpeechAnalysisResponse {
        var response = await coreEngine.analyze(input)

        for provider in remoteProviders where provider.isAvailable() {
            do {
                response = try await provider.enhance(response, input: input)
            } catch {
                continue
            }
        }

        return response
    }
}

enum FeedbackEngineFactory {

    static func makeDefault(aiFeedbackEnabled: Bool = true) -> FeedbackEngine {
        let _ = FeedbackEnginePolicy.fromConfig()
        let providers: [RemoteFeedbackProvider] = aiFeedbackEnabled ? [] : []
        return FeedbackEngineCoordinator(coreEngine: OnDeviceFeedbackEngine(), remoteProviders: providers)
    }
}
