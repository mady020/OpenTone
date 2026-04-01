import Foundation

final class OnDeviceFeedbackEngine: FeedbackEngine {

    private let fillers: [String] = [
        "um", "uh", "like", "you know", "i mean", "sort of", "kind of", "actually", "basically"
    ]

    func analyze(_ input: FeedbackEngineInput) async -> SpeechAnalysisResponse {
        let cleanedTranscript = normalizeWhitespace(input.transcript)

        let metrics = buildMetrics(from: cleanedTranscript, durationS: input.durationS, turnSummaries: input.turnSummaries)
        let profileBefore = loadProfile(for: input.userId)
        let pronunciationInsights = OnDevicePronunciationAnalyzer.shared.analyze(transcript: cleanedTranscript)
        let analysis = classify(transcript: cleanedTranscript, metrics: metrics, pronunciationIssueCount: pronunciationInsights.count)

        let coaching = buildCoaching(
            analysis: analysis,
            metrics: metrics,
            mode: input.mode,
            userId: input.userId,
            pronunciationInsights: pronunciationInsights
        )
        let progress = buildProgress(current: metrics, currentScores: coaching.scores, previous: profileBefore)

        let updatedProfile = profileBefore.updated(with: metrics, overallScore: coaching.scores.overall)
        saveProfile(updatedProfile, for: input.userId)

        return SpeechAnalysisResponse(
            transcript: cleanedTranscript,
            metrics: metrics,
            coaching: coaching,
            progress: progress
        )
    }

    private func buildMetrics(from transcript: String, durationS: Double, turnSummaries: [SessionTurnSummary]) -> SpeechMetrics {
        if !turnSummaries.isEmpty {
            return aggregateMetrics(from: transcript, durationS: durationS, turnSummaries: turnSummaries)
        }

        let words = tokenizedWords(from: transcript)
        let duration = max(durationS, 1)
        let totalWords = words.count
        let wpm = totalWords > 0 ? Double(totalWords) / (duration / 60.0) : 0

        let fillerMatches = detectFillerMatches(in: transcript, totalDuration: duration)
        let repetitions = countAdjacentRepetitions(in: words)

        let speakingEstimateS = Double(totalWords) / 145.0 * 60.0
        let inferredSilenceS = max(0.0, duration - speakingEstimateS)

        let punctuationBoundaries = transcript.filter { ",.;:?!".contains($0) }.count
        let inferredPauses = max(0, Int((inferredSilenceS / 1.15).rounded()) + (punctuationBoundaries / 3))
        let pauses = min(inferredPauses, max(totalWords / 3, 0))

        let avgPauseS: Double
        if pauses > 0 {
            avgPauseS = inferredSilenceS > 0 ? inferredSilenceS / Double(pauses) : 0.8
        } else {
            avgPauseS = 0
        }

        let veryLongPauses = max(0, min(pauses, Int((inferredSilenceS / 2.8).rounded())))
        let pauseExamples = makePauseExamples(pauses: pauses, totalDuration: duration, transcript: transcript)

        return SpeechMetrics(
            wpm: wpm,
            totalWords: totalWords,
            durationS: duration,
            fillerRatePerMin: duration > 0 ? Double(fillerMatches.count) / duration * 60.0 : 0,
            fillers: fillerMatches.count,
            pauses: pauses,
            avgPauseS: avgPauseS,
            veryLongPauses: veryLongPauses,
            repetitions: repetitions,
            fillerExamples: Array(fillerMatches.prefix(8)),
            pauseExamples: Array(pauseExamples.prefix(8))
        )
    }

    private func aggregateMetrics(from transcript: String, durationS: Double, turnSummaries: [SessionTurnSummary]) -> SpeechMetrics {
        let totalWords = turnSummaries.reduce(0) { $0 + $1.totalWords }
        let totalFillers = turnSummaries.reduce(0) { $0 + $1.fillers }
        let totalPauses = turnSummaries.reduce(0) { $0 + $1.pauses }
        let totalVeryLongPauses = turnSummaries.reduce(0) { $0 + $1.veryLongPauses }
        let totalRepetitions = turnSummaries.reduce(0) { $0 + $1.repetitions }

        let duration = max(durationS, turnSummaries.reduce(0.0) { $0 + $1.durationS }, 1)
        let wpm = duration > 0 ? Double(totalWords) / (duration / 60.0) : 0
        let fillerRate = duration > 0 ? Double(totalFillers) / duration * 60.0 : 0

        let pauseTurns = turnSummaries.filter { $0.pauses > 0 }
        let avgPauseS = pauseTurns.isEmpty ? 0.0 : pauseTurns.reduce(0.0) { $0 + $1.avgPauseS } / Double(pauseTurns.count)

        var pauseExamples: [PauseExample] = []
        var fillerExamples: [FillerExample] = []
        var cursor = 0.0

        for turn in turnSummaries {
            pauseExamples.append(contentsOf: turn.pauseExamples.prefix(2).map {
                PauseExample(start: $0.start + cursor, end: $0.end + cursor, duration: $0.duration)
            })
            fillerExamples.append(contentsOf: turn.fillerExamples.prefix(2).map {
                FillerExample(word: $0.word, timestamp: $0.timestamp + cursor)
            })
            cursor += turn.durationS
        }

        return SpeechMetrics(
            wpm: wpm,
            totalWords: totalWords,
            durationS: duration,
            fillerRatePerMin: fillerRate,
            fillers: totalFillers,
            pauses: totalPauses,
            avgPauseS: avgPauseS,
            veryLongPauses: totalVeryLongPauses,
            repetitions: totalRepetitions,
            fillerExamples: Array(fillerExamples.prefix(8)),
            pauseExamples: Array(pauseExamples.prefix(8))
        )
    }

    private struct AnalysisResult {
        let primaryIssueKey: String
        let secondaryIssueKeys: [String]
        let strengths: [String]
        let recoveryDetected: Bool
        let incompletePhrase: Bool
        let lowConfidenceCapture: Bool
    }

    private func classify(transcript: String, metrics: SpeechMetrics, pronunciationIssueCount: Int) -> AnalysisResult {
        let words = tokenizedWords(from: transcript)

        let tooSlow = metrics.wpm > 0 && metrics.wpm < 105
        let tooFast = metrics.wpm > 180
        let hesitation = metrics.avgPauseS >= 1.2 || metrics.fillerRatePerMin > 6.0
        let trueDisfluency = metrics.repetitions >= 3 || metrics.veryLongPauses >= 2
        let lowConfidenceCapture = words.count < 12 && metrics.durationS >= 20

        let lastLower = transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let incompletePhrase = lastLower.hasSuffix("and") || lastLower.hasSuffix("because") || lastLower.hasSuffix("but")

        let firstHalf = String(transcript.prefix(transcript.count / 2))
        let secondHalf = String(transcript.suffix(transcript.count / 2))
        let firstHalfFillers = detectFillerMatches(in: firstHalf, totalDuration: max(metrics.durationS / 2.0, 1)).count
        let secondHalfFillers = detectFillerMatches(in: secondHalf, totalDuration: max(metrics.durationS / 2.0, 1)).count
        let recoveryDetected = firstHalfFillers >= secondHalfFillers + 2 && words.count >= 20

        var issueScores: [(String, Int)] = []
        if hesitation { issueScores.append(("hesitation", Int(metrics.avgPauseS * 10) + Int(metrics.fillerRatePerMin))) }
        if trueDisfluency { issueScores.append(("mistakes", metrics.repetitions * 4 + metrics.veryLongPauses * 6)) }
        if tooSlow || tooFast { issueScores.append(("timing", Int(abs(metrics.wpm - 140) / 5.0))) }
        if incompletePhrase { issueScores.append(("incomplete", 10)) }
        if lowConfidenceCapture { issueScores.append(("low_confidence", 12)) }
        if pronunciationIssueCount > 0 { issueScores.append(("pronunciation", 7 + (pronunciationIssueCount * 3))) }

        let primaryIssueKey = issueScores.sorted { $0.1 > $1.1 }.first?.0 ?? "variation"
        let secondaryIssueKeys = issueScores.sorted { $0.1 > $1.1 }.dropFirst().map { $0.0 }

        var strengths: [String] = []
        if metrics.wpm >= 115 && metrics.wpm <= 170 {
            strengths.append("Your pace stayed conversational.")
        }
        if metrics.fillerRatePerMin <= 4 {
            strengths.append("You kept filler words mostly under control.")
        }
        if recoveryDetected {
            strengths.append("You recovered smoothly after early hesitation.")
        }
        if metrics.totalWords >= 60 {
            strengths.append("You sustained your idea long enough to practice flow.")
        }
        if strengths.isEmpty {
            strengths.append("You completed the session and kept building momentum.")
        }

        return AnalysisResult(
            primaryIssueKey: primaryIssueKey,
            secondaryIssueKeys: Array(secondaryIssueKeys.prefix(3)),
            strengths: strengths,
            recoveryDetected: recoveryDetected,
            incompletePhrase: incompletePhrase,
            lowConfidenceCapture: lowConfidenceCapture
        )
    }

    private func buildCoaching(
        analysis: AnalysisResult,
        metrics: SpeechMetrics,
        mode: FeedbackSessionMode,
        userId: String,
        pronunciationInsights: [PronunciationInsight]
    ) -> SpeechCoaching {
        let scores = coachingScores(metrics: metrics, analysis: analysis)

        var suggestions = suggestionTemplates(for: analysis.primaryIssueKey, metrics: metrics)
        for key in analysis.secondaryIssueKeys {
            suggestions.append(contentsOf: suggestionTemplates(for: key, metrics: metrics))
        }

        if analysis.recoveryDetected {
            suggestions.append("You recovered well. Next step: keep that reset speed by taking one intentional breath after each key point.")
        }

        if analysis.incompletePhrase {
            suggestions.append("End your final thought with one short conclusion sentence so your message feels complete.")
        }

        if analysis.lowConfidenceCapture {
            suggestions.append("Some parts were hard to capture clearly. Try speaking slightly louder and facing the mic directly.")
        }

        if !pronunciationInsights.isEmpty {
            suggestions.append(contentsOf: OnDevicePronunciationAnalyzer.shared.suggestions(from: pronunciationInsights))
        }

        suggestions = Array(suggestions.uniquedPreservingOrder().prefix(6))
        suggestions = dedupeWithRecentHistory(suggestions, userId: userId)

        var evidence = makeEvidence(metrics: metrics, primaryIssue: analysis.primaryIssueKey)
        evidence.append(contentsOf: OnDevicePronunciationAnalyzer.shared.evidenceItems(from: pronunciationInsights))

        return SpeechCoaching(
            scores: scores,
            primaryIssue: primaryIssueDescription(for: analysis.primaryIssueKey, metrics: metrics),
            primaryIssueTitle: primaryIssueTitle(for: analysis.primaryIssueKey),
            secondaryIssues: analysis.secondaryIssueKeys.map { primaryIssueDescription(for: $0, metrics: metrics) },
            strengths: analysis.strengths,
            suggestions: suggestions,
            evidence: evidence,
            llmCoaching: nil
        )
    }

    private func coachingScores(metrics: SpeechMetrics, analysis: AnalysisResult) -> CoachingScores {
        let fluencyPenalty = metrics.fillerRatePerMin * 3.5 + Double(metrics.repetitions) * 4.0 + max(0.0, metrics.avgPauseS - 0.8) * 22.0
        let confidencePenalty = abs(metrics.wpm - 140) * 0.9 + Double(metrics.veryLongPauses) * 6.0 + (analysis.lowConfidenceCapture ? 8.0 : 0.0)
        let clarityPenalty = Double(metrics.veryLongPauses) * 8.0 + Double(max(metrics.pauses - 3, 0)) * 2.0 + (analysis.incompletePhrase ? 8.0 : 0.0)

        return CoachingScores(
            fluency: clamp(100.0 - fluencyPenalty, min: 25, max: 100),
            confidence: clamp(100.0 - confidencePenalty, min: 20, max: 100),
            clarity: clamp(100.0 - clarityPenalty, min: 20, max: 100)
        )
    }

    private func suggestionTemplates(for issue: String, metrics: SpeechMetrics) -> [String] {
        switch issue {
        case "hesitation":
            return [
                "Swap fillers with silent half-second breaths before your next phrase.",
                "Use a simple structure: point, example, wrap-up. It reduces mid-sentence hesitation.",
                "Practice one 30-second run where you intentionally avoid \"um\" and \"like\"."
            ]
        case "mistakes":
            return [
                "When a phrase breaks, restart from the previous keyword instead of repeating from the start.",
                "Shorten sentence length for the next attempt to improve clean delivery.",
                "Do one slow rehearsal pass, then one natural-speed pass to lock accuracy."
            ]
        case "timing":
            if metrics.wpm < 105 {
                return [
                    "Aim for 120-150 WPM by grouping words into short thought chunks.",
                    "Reduce long gaps by preparing your next keyword while finishing the current sentence.",
                    "Use one clear example early so your pace picks up naturally."
                ]
            }
            return [
                "Slow down slightly on key words so listeners can follow your main point.",
                "Insert one short pause between ideas to avoid rushing transitions.",
                "Keep sentence openings steady; speed up only after the first clause."
            ]
        case "incomplete":
            return [
                "Finish with a final sentence that answers: So what is my main point?",
                "Avoid ending on connectors like \"and\" or \"because\" without a closure.",
                "Use a closing frame: \"In short...\" to complete your idea clearly."
            ]
        case "low_confidence":
            return [
                "Keep the microphone 10-15 cm away and speak straight toward it.",
                "Use slightly stronger volume on sentence beginnings for clearer capture.",
                "Record one short test sentence before the full jam to confirm audio quality."
            ]
        case "pronunciation":
            return [
                "Repeat key words at a slower tempo and keep vowels clearly separated.",
                "Use minimal-pair drills for common confusions like /v/ vs /w/ and /l/ vs /r/.",
                "Record one sentence twice: first carefully, then naturally, while keeping target sounds stable."
            ]
        default:
            return [
                "Your variation was mostly natural. Keep building consistency over the next two sessions.",
                "Choose one improvement focus each session so feedback remains actionable.",
                "Repeat this topic once more and compare your filler and pause counts."
            ]
        }
    }

    private func primaryIssueTitle(for key: String) -> String {
        switch key {
        case "hesitation": return "Pause and Hesitation Control"
        case "mistakes": return "Disfluency Recovery"
        case "timing": return "Timing Drift"
        case "incomplete": return "Incomplete Phrases"
        case "low_confidence": return "Low-Confidence Capture"
        case "pronunciation": return "Pronunciation Precision"
        default: return "Harmless Variation"
        }
    }

    private func primaryIssueDescription(for key: String, metrics: SpeechMetrics) -> String {
        switch key {
        case "hesitation":
            return "Frequent hesitation signals appeared (\(metrics.fillers) fillers, avg pause \(String(format: "%.1f", metrics.avgPauseS))s)."
        case "mistakes":
            return "Delivery broke flow at several points (\(metrics.repetitions) repetitions, \(metrics.veryLongPauses) very long pauses)."
        case "timing":
            return "Your pacing drifted from the conversational range at \(Int(metrics.wpm.rounded())) WPM."
        case "incomplete":
            return "Some ideas ended before completion, reducing clarity of your message."
        case "low_confidence":
            return "Audio confidence looked low for parts of the session, so interpretation should be cautious."
        case "pronunciation":
            return "Some word-level sound substitutions were detected; targeted phoneme practice can improve clarity."
        default:
            return "Variation looked mostly natural and not a critical speaking error."
        }
    }

    private func makeEvidence(metrics: SpeechMetrics, primaryIssue: String) -> [EvidenceItem] {
        var evidence: [EvidenceItem] = []

        for filler in metrics.fillerExamples.prefix(3) {
            evidence.append(EvidenceItem(
                type: "filler",
                timestamp: filler.timestamp,
                text: "\(timestampString(filler.timestamp)) - \"\(filler.word)\""
            ))
        }

        for pause in metrics.pauseExamples.prefix(3) {
            evidence.append(EvidenceItem(
                type: "pause",
                timestamp: pause.start,
                text: "\(timestampString(pause.start)) - pause \(String(format: "%.1f", pause.duration))s"
            ))
        }

        if primaryIssue == "mistakes" && metrics.repetitions > 0 {
            evidence.append(EvidenceItem(
                type: "repetition",
                timestamp: 0,
                text: "Detected \(metrics.repetitions) repeated word or restart patterns"
            ))
        }

        return evidence
    }

    private func buildProgress(current: SpeechMetrics, currentScores: CoachingScores, previous: LocalProfile) -> SpeechProgress {
        let previousWpm = previous.avgWpm
        let previousFillers = previous.avgFillerRate
        let previousPauses = previous.avgPause

        let deltas = Deltas(
            wpm: current.wpm - previousWpm,
            fillers: previousFillers - current.fillerRatePerMin,
            pauses: previousPauses - current.avgPauseS
        )

        let positiveSignals = [deltas.wpm > 0, deltas.fillers > 0, deltas.pauses > 0].filter { $0 }.count
        let direction: String
        if previous.sessionsCount == 0 {
            direction = "mixed"
        } else if positiveSignals >= 2 {
            direction = "improving"
        } else if positiveSignals == 0 {
            direction = "declining"
        } else {
            direction = "mixed"
        }

        let summary: String
        if previous.sessionsCount == 0 {
            summary = "Baseline set. Focus on one timing goal and one fluency goal next session."
        } else if direction == "improving" {
            summary = "You are trending upward. Keep reinforcing this pacing and pause control pattern."
        } else if direction == "declining" {
            summary = "This session was tougher than your recent baseline. Slow down and rebuild clean phrases."
        } else {
            summary = "Mixed trend this session. Lock one improvement target before your next jam."
        }

        return SpeechProgress(deltas: deltas, overallDirection: direction, weeklySummary: summary)
    }

    private struct LocalProfile: Codable {
        var avgWpm: Double
        var avgFillerRate: Double
        var avgPause: Double
        var sessionsCount: Int
        var recentScores: [Double]

        static let empty = LocalProfile(avgWpm: 0, avgFillerRate: 0, avgPause: 0, sessionsCount: 0, recentScores: [])

        func updated(with metrics: SpeechMetrics, overallScore: Double) -> LocalProfile {
            let alpha = 0.35
            if sessionsCount == 0 {
                return LocalProfile(
                    avgWpm: metrics.wpm,
                    avgFillerRate: metrics.fillerRatePerMin,
                    avgPause: metrics.avgPauseS,
                    sessionsCount: 1,
                    recentScores: [overallScore]
                )
            }

            var nextScores = recentScores
            nextScores.append(overallScore)
            if nextScores.count > 8 {
                nextScores.removeFirst(nextScores.count - 8)
            }

            return LocalProfile(
                avgWpm: (alpha * metrics.wpm) + ((1 - alpha) * avgWpm),
                avgFillerRate: (alpha * metrics.fillerRatePerMin) + ((1 - alpha) * avgFillerRate),
                avgPause: (alpha * metrics.avgPauseS) + ((1 - alpha) * avgPause),
                sessionsCount: sessionsCount + 1,
                recentScores: nextScores
            )
        }
    }

    private func loadProfile(for userId: String) -> LocalProfile {
        let key = "opentone.feedback.profile.\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key) else { return .empty }
        return (try? JSONDecoder().decode(LocalProfile.self, from: data)) ?? .empty
    }

    private func saveProfile(_ profile: LocalProfile, for userId: String) {
        let key = "opentone.feedback.profile.\(userId)"
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func dedupeWithRecentHistory(_ suggestions: [String], userId: String) -> [String] {
        let historyKey = "opentone.feedback.recentSuggestions.\(userId)"
        let recent = UserDefaults.standard.stringArray(forKey: historyKey) ?? []

        var filtered = suggestions.filter { !recent.contains($0) }
        if filtered.count < 3 {
            filtered.append(contentsOf: suggestions.filter { !filtered.contains($0) })
        }

        let nextRecent = Array((recent + filtered).suffix(8))
        UserDefaults.standard.set(nextRecent, forKey: historyKey)

        return Array(filtered.prefix(4))
    }

    private func detectFillerMatches(in transcript: String, totalDuration: Double) -> [FillerExample] {
        let normalized = transcript.lowercased()
        var matches: [FillerExample] = []

        for filler in fillers {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: filler))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(location: 0, length: (normalized as NSString).length)
            let hits = regex.matches(in: normalized, options: [], range: range)
            for hit in hits {
                let ratio = (Double(hit.range.location) / Double(max((normalized as NSString).length, 1)))
                let timestamp = ratio * totalDuration
                matches.append(FillerExample(word: filler, timestamp: timestamp))
            }
        }

        return matches.sorted { $0.timestamp < $1.timestamp }
    }

    private func makePauseExamples(pauses: Int, totalDuration: Double, transcript: String) -> [PauseExample] {
        guard pauses > 0 else { return [] }

        let punctuationIndices = transcript.enumerated().compactMap { idx, char -> Int? in
            ",.;?!".contains(char) ? idx : nil
        }

        var examples: [PauseExample] = []
        let sampleCount = min(pauses, 5)
        for i in 0..<sampleCount {
            let ratio: Double
            if i < punctuationIndices.count {
                ratio = Double(punctuationIndices[i]) / Double(max(transcript.count, 1))
            } else {
                ratio = Double(i + 1) / Double(sampleCount + 1)
            }

            let start = ratio * totalDuration
            let estimatedDuration = clamp((totalDuration / Double(max(pauses, 1))) * 0.9, min: 0.7, max: 2.8)
            examples.append(PauseExample(start: start, end: start + estimatedDuration, duration: estimatedDuration))
        }

        return examples
    }

    private func countAdjacentRepetitions(in words: [String]) -> Int {
        guard words.count > 1 else { return 0 }
        let ignored: Set<String> = ["the", "a", "an", "to", "and", "of"]

        var repetitions = 0
        for i in 1..<words.count {
            if words[i] == words[i - 1] && !ignored.contains(words[i]) {
                repetitions += 1
            }
        }

        return repetitions
    }

    private func tokenizedWords(from transcript: String) -> [String] {
        transcript
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func normalizeWhitespace(_ input: String) -> String {
        input
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func timestampString(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}

private extension Array where Element: Hashable {
    func uniquedPreservingOrder() -> [Element] {
        var seen: Set<Element> = []
        var result: [Element] = []
        for element in self where !seen.contains(element) {
            seen.insert(element)
            result.append(element)
        }
        return result
    }
}
