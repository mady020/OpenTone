import XCTest
@testable import OpenTone

final class PronunciationFeedbackEngineTests: XCTestCase {

    func testEstimateOnlyAssessmentShowsDisclosureAndWordLevelCoaching() {
        let engine = PronunciationFeedbackEngine()

        let result = PronunciationAssessmentResult(
            overallScore: 58,
            phoneScores: [],
            wordScores: [
                WordPronunciationScore(
                    word: "weather",
                    wordIndex: 0,
                    score: 44,
                    phoneScores: [],
                    hasIssue: true,
                    primaryIssue: "This word did not match clearly. Listen once, then repeat slowly."
                ),
                WordPronunciationScore(
                    word: "today",
                    wordIndex: 1,
                    score: 72,
                    phoneScores: [],
                    hasIssue: false,
                    primaryIssue: nil
                )
            ],
            prosody: ProsodyResult(
                overallScore: 66,
                confidence: .low,
                wordStress: [],
                issues: []
            ),
            expectedText: "The weather is beautiful today.",
            transcribedText: "the wedder is beautiful today",
            diagnostics: PronunciationDiagnostics(
                expectedPhonemeCount: 22,
                alignedPhonemeCount: 0,
                missingPhonemeCount: 0,
                substitutionCount: 0,
                insertionCount: 0,
                acceptableVariationCount: 0,
                acousticModelUsed: "Placeholder (spectral heuristic) (estimate-only)",
                processingTimeMs: 12
            )
        )

        let output = engine.generateFeedback(from: result)

        XCTAssertTrue(output.userFeedback.contains(where: {
            $0.message.contains("Detailed sound-level scoring is unavailable")
        }))
        XCTAssertTrue(output.userFeedback.contains(where: {
            $0.word?.lowercased() == "weather"
        }))
    }

    func testLowScoreAlwaysIncludesActionableSummary() {
        let engine = PronunciationFeedbackEngine()

        let result = PronunciationAssessmentResult(
            overallScore: 41,
            phoneScores: [
                PhoneScore(
                    phone: StressedPhone(phone: .TH, stress: .none),
                    score: 25,
                    category: .substituted,
                    severity: .critical,
                    confidence: .high,
                    wordIndex: 0,
                    word: "think",
                    substitutedWith: .T,
                    diagnosticNote: "Substitution"
                )
            ],
            wordScores: [
                WordPronunciationScore(
                    word: "think",
                    wordIndex: 0,
                    score: 40,
                    phoneScores: [],
                    hasIssue: true,
                    primaryIssue: "One sound was swapped"
                )
            ],
            prosody: ProsodyResult(
                overallScore: 55,
                confidence: .medium,
                wordStress: [],
                issues: []
            ),
            expectedText: "Think clearly",
            transcribedText: "tink clearly",
            diagnostics: PronunciationDiagnostics(
                expectedPhonemeCount: 10,
                alignedPhonemeCount: 10,
                missingPhonemeCount: 1,
                substitutionCount: 1,
                insertionCount: 0,
                acceptableVariationCount: 0,
                acousticModelUsed: "Wav2Vec2",
                processingTimeMs: 30
            )
        )

        let output = engine.generateFeedback(from: result)

        XCTAssertTrue(output.userFeedback.contains(where: {
            $0.message.contains("Almost there")
        }))
    }
}
