import XCTest
@testable import OpenTone

final class OnDeviceFeedbackEngineTests: XCTestCase {

    func testPauseHandlingTreatsNaturalPausesAsNonCritical() async {
        let engine = OnDeviceFeedbackEngine()
        let input = FeedbackEngineInput(
            transcript: "I enjoy teaching music, and I like helping beginners build confidence.",
            topic: "Music",
            durationS: 32,
            userId: "u1",
            sessionId: "s1",
            mode: .jam,
            turnSummaries: []
        )

        let response = await engine.analyze(input)

        XCTAssertLessThanOrEqual(response.metrics.avgPauseS, 1.6)
        XCTAssertNotEqual(response.coaching.primaryIssueTitle, "Disfluency Recovery")
    }

    func testMistakeClassificationFlagsDisfluencyAndRecovery() async {
        let engine = OnDeviceFeedbackEngine()
        let turns = [
            SessionTurnSummary(
                transcript: "um um I I think",
                totalWords: 5,
                durationS: 8,
                fillers: 2,
                pauses: 2,
                avgPauseS: 1.4,
                veryLongPauses: 1,
                repetitions: 2,
                fillerExamples: [FillerExample(word: "um", timestamp: 1.1)],
                pauseExamples: [PauseExample(start: 2.0, end: 3.4, duration: 1.4)]
            ),
            SessionTurnSummary(
                transcript: "I think practice helps me improve faster",
                totalWords: 7,
                durationS: 8,
                fillers: 0,
                pauses: 0,
                avgPauseS: 0,
                veryLongPauses: 0,
                repetitions: 0,
                fillerExamples: [],
                pauseExamples: []
            )
        ]

        let response = await engine.analyze(
            FeedbackEngineInput(
                transcript: "um um I I think I think practice helps me improve faster",
                topic: "Practice",
                durationS: 16,
                userId: "u2",
                sessionId: "s2",
                mode: .aiCall,
                turnSummaries: turns
            )
        )

        XCTAssertGreaterThan(response.metrics.repetitions, 0)
        XCTAssertFalse(response.coaching.suggestions.isEmpty)
        XCTAssertTrue(response.coaching.primaryIssueTitle == "Disfluency Recovery" || response.coaching.primaryIssueTitle == "Pause and Hesitation Control")
    }

    func testTextOnlyPronunciationHintsDoNotClaimPhonemeEvidence() async {
        let engine = OnDeviceFeedbackEngine()
        let response = await engine.analyze(
            FeedbackEngineInput(
                transcript: "I tink dis is bery useful",
                topic: "Practice",
                durationS: 12,
                userId: "u4",
                sessionId: "s4",
                mode: .jam,
                turnSummaries: []
            )
        )

        XCTAssertFalse(response.coaching.evidence.contains(where: { $0.type == "phoneme" }))
        XCTAssertTrue(response.coaching.evidence.contains(where: { $0.type == "pronunciation_hint" }))
    }
}
