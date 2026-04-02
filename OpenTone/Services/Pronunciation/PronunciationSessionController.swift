import Foundation
import AVFoundation

/// Manages the lifecycle of a pronunciation practice session.
/// Coordinates recording, transcription, scoring, and result delivery.
@MainActor
final class PronunciationSessionController {

    // MARK: - State

    enum SessionState: Equatable {
        case idle
        case recording
        case analyzing
        case results
        case error(String)
    }

    // MARK: - Delegate

    protocol Delegate: AnyObject {
        func sessionStateDidChange(_ state: SessionState)
        func sessionDidReceiveTranscript(_ transcript: String, isFinal: Bool)
        func sessionDidCompleteAssessment(_ result: PronunciationAssessmentResult, feedback: PronunciationFeedbackEngine.FeedbackOutput)
        func sessionDidFail(_ error: Error)
    }

    // MARK: - Properties

    weak var delegate: Delegate?

    private(set) var state: SessionState = .idle {
        didSet {
            delegate?.sessionStateDidChange(state)
        }
    }

    private(set) var expectedText: String = ""
    private(set) var lastResult: PronunciationAssessmentResult?
    private(set) var lastFeedback: PronunciationFeedbackEngine.FeedbackOutput?

    private let scoringService: PronunciationScoringService
    private let feedbackEngine: PronunciationFeedbackEngine
    private let audioManager: AudioManager

    // MARK: - Init

    init(
        scoringService: PronunciationScoringService? = nil,
        feedbackEngine: PronunciationFeedbackEngine? = nil,
        audioManager: AudioManager? = nil
    ) {
        self.scoringService = scoringService ?? .shared
        self.feedbackEngine = feedbackEngine ?? PronunciationFeedbackEngine()
        self.audioManager = audioManager ?? .shared
    }

    // MARK: - Session Lifecycle

    func prepareSession(expectedText: String) {
        self.expectedText = expectedText
        self.lastResult = nil
        self.lastFeedback = nil
        self.state = .idle
    }

    func startRecording() {
        guard state == .idle || state == .results else { return }

        lastResult = nil
        lastFeedback = nil

        audioManager.startRecording { [weak self] started in
            guard let self else { return }
            if started {
                self.state = .recording
            } else {
                let error = PronunciationError.microphoneAccessDenied
                self.state = .error(error.localizedDescription)
                self.delegate?.sessionDidFail(error)
            }
        }
    }

    func stopRecordingAndAnalyze() {
        guard state == .recording else { return }

        audioManager.stopRecording(autoTranscribe: false)
        state = .analyzing

        guard let audioURL = audioManager.lastRecordingURL else {
            let error = PronunciationError.audioTooShort
            state = .error(error.localizedDescription)
            delegate?.sessionDidFail(error)
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.scoringService.assess(
                    audioURL: audioURL,
                    expectedText: self.expectedText
                )

                let feedback = self.feedbackEngine.generateFeedback(from: result)

                self.lastResult = result
                self.lastFeedback = feedback
                self.state = .results
                self.delegate?.sessionDidCompleteAssessment(result, feedback: feedback)

            } catch {
                self.state = .error(error.localizedDescription)
                self.delegate?.sessionDidFail(error)
            }
        }
    }

    func cancelRecording() {
        if state == .recording {
            audioManager.stopRecording(autoTranscribe: false)
        }
        state = .idle
    }

    func reset() {
        cancelRecording()
        lastResult = nil
        lastFeedback = nil
        state = .idle
    }
}

// MARK: - Default Phrases

extension PronunciationSessionController {

    /// Curated practice phrases for pronunciation practice.
    static let defaultPhrases: [String] = [
        "The weather is beautiful today.",
        "She sells seashells by the seashore.",
        "I think this is very interesting.",
        "Could you please repeat that?",
        "Three thousand three hundred thirty three.",
        "The red lorry ran along the road.",
        "How much wood would a woodchuck chuck?",
        "Peter Piper picked a peck of pickled peppers.",
        "I would like a cup of coffee, please.",
        "The quick brown fox jumps over the lazy dog.",
        "We need to schedule a meeting for Thursday.",
        "Can you describe your experience with this?",
        "Technology is changing the way we communicate.",
        "I appreciate your patience and understanding.",
        "The economy has shown significant improvement.",
        "Environmental awareness is crucial for our future.",
    ]

    static func randomPhrase() -> String {
        defaultPhrases.randomElement() ?? defaultPhrases[0]
    }
}
