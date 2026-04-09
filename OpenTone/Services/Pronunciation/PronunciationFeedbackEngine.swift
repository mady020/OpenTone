import Foundation

/// Merges pronunciation scoring results into actionable user-facing feedback
/// while keeping detailed internal diagnostics separate.
final class PronunciationFeedbackEngine {

    // MARK: - Output Types

    struct FeedbackOutput {
        let userFeedback: [UserFeedbackItem]
        let diagnostics: InternalDiagnosticReport
        let pronunciationInsights: [PronunciationInsight]
        let pronunciationScore: Float
    }

    struct UserFeedbackItem {
        let level: FeedbackLevel
        let message: String
        let actionTip: String?
        let word: String?
        let phonemeHint: String?
    }

    enum FeedbackLevel: Int, Comparable {
        case info = 0
        case suggestion = 1
        case warning = 2
        case critical = 3

        static func < (lhs: FeedbackLevel, rhs: FeedbackLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    struct InternalDiagnosticReport {
        let allPhoneScores: [PhoneScore]
        let wordBreakdown: [WordPronunciationScore]
        let prosody: ProsodyResult
        let alignmentQuality: Float
        let modelUsed: String
        let processingTimeMs: Double
        let suppressedIssues: [SuppressedIssue]
    }

    struct SuppressedIssue {
        let reason: String
        let detail: String
    }

    // MARK: - Public API

    func generateFeedback(from result: PronunciationAssessmentResult) -> FeedbackOutput {
        var rawItems: [UserFeedbackItem] = []
        var suppressedIssues: [SuppressedIssue] = []
        let estimateOnly = isEstimateOnly(result)

        if estimateOnly {
            rawItems.append(contentsOf: generateEstimateOnlyWordFeedback(result: result))
            rawItems.append(UserFeedbackItem(
                level: .info,
                message: "Detailed sound-level scoring is unavailable in this build.",
                actionTip: "Use the top words below for focused repeats.",
                word: nil,
                phonemeHint: nil
            ))
        } else {
            // Phone-level feedback
            let (phoneItems, phoneSuppressed) = generatePhoneFeedback(result: result)
            rawItems.append(contentsOf: phoneItems)
            suppressedIssues.append(contentsOf: phoneSuppressed)

            // Prosody feedback
            let (prosodyItems, prosodySuppressed) = generateProsodyFeedback(result: result)
            rawItems.append(contentsOf: prosodyItems)
            suppressedIssues.append(contentsOf: prosodySuppressed)
        }

        // Overall summary feedback
        rawItems.append(contentsOf: generateSummaryFeedback(result: result, estimateOnly: estimateOnly))

        // Sort by severity (critical first) and limit to avoid overwhelming
        let sortedItems = rawItems.sorted { $0.level > $1.level }
        let dedupedItems = dedupeFeedbackItems(sortedItems)
        let limitedItems = Array(dedupedItems.prefix(estimateOnly ? 4 : 5))

        // Convert to legacy PronunciationInsight format for backward compatibility
        let insights = limitedItems.compactMap { item -> PronunciationInsight? in
            guard let word = item.word else { return nil }
            return PronunciationInsight(
                observedFragment: word,
                expectedFragment: word,
                phonemeHint: item.phonemeHint ?? "",
                coachingTip: item.actionTip ?? item.message
            )
        }

        let diagnostics = InternalDiagnosticReport(
            allPhoneScores: result.phoneScores,
            wordBreakdown: result.wordScores,
            prosody: result.prosody,
            alignmentQuality: result.diagnostics.expectedPhonemeCount > 0
                ? Float(result.diagnostics.alignedPhonemeCount) / Float(result.diagnostics.expectedPhonemeCount) * 100
                : 0,
            modelUsed: result.diagnostics.acousticModelUsed,
            processingTimeMs: result.diagnostics.processingTimeMs,
            suppressedIssues: suppressedIssues
        )

        return FeedbackOutput(
            userFeedback: limitedItems,
            diagnostics: diagnostics,
            pronunciationInsights: insights,
            pronunciationScore: result.overallScore
        )
    }

    private func isEstimateOnly(_ result: PronunciationAssessmentResult) -> Bool {
        let model = result.diagnostics.acousticModelUsed.lowercased()
        return model.contains("estimate-only") || model.contains("placeholder") || model.contains("heuristic")
    }

    private func dedupeFeedbackItems(_ items: [UserFeedbackItem]) -> [UserFeedbackItem] {
        var unique: [UserFeedbackItem] = []
        var seen: Set<String> = []

        for item in items {
            let key = "\(item.word?.lowercased() ?? "")|\(item.message.lowercased())|\(item.actionTip?.lowercased() ?? "")"
            if seen.contains(key) {
                continue
            }
            seen.insert(key)
            unique.append(item)
        }

        return unique
    }

    private func generateEstimateOnlyWordFeedback(result: PronunciationAssessmentResult) -> [UserFeedbackItem] {
        let weakWords = result.wordScores
            .filter { $0.hasIssue }
            .sorted { $0.score < $1.score }
            .prefix(2)

        return weakWords.map { wordScore in
            UserFeedbackItem(
                level: .suggestion,
                message: "Focus on '\(wordScore.word)' with one slow and one natural-speed repeat.",
                actionTip: wordScore.primaryIssue ?? "Replay this word once, then repeat clearly.",
                word: wordScore.word,
                phonemeHint: nil
            )
        }
    }

    // MARK: - Phone-Level Feedback

    private func generatePhoneFeedback(
        result: PronunciationAssessmentResult
    ) -> ([UserFeedbackItem], [SuppressedIssue]) {
        var items: [UserFeedbackItem] = []
        var suppressed: [SuppressedIssue] = []

        // Group issues by word
        var wordIssues: [String: [(PhoneScore, WordPronunciationScore)]] = [:]
        for wordScore in result.wordScores where wordScore.hasIssue {
            let problematic = wordScore.phoneScores.filter { $0.severity >= .moderate }
            for phone in problematic {
                wordIssues[wordScore.word, default: []].append((phone, wordScore))
            }
        }

        for (word, issues) in wordIssues {
            for (phone, _) in issues {
                // Confidence-aware suppression
                if phone.confidence == .low {
                    suppressed.append(SuppressedIssue(
                        reason: "low_confidence",
                        detail: "Suppressed /\(phone.phone.phone.ipaSymbol)/ issue in '\(word)' — acoustic evidence too weak"
                    ))
                    continue
                }

                switch phone.category {
                case .substituted:
                    guard let sub = phone.substitutedWith else { continue }
                    let expected = phone.phone.phone
                    let tip = articulationTip(expected: expected, actual: sub)

                    items.append(UserFeedbackItem(
                        level: phone.severity == .critical ? .critical : .warning,
                        message: "In '\(word)', the /\(expected.ipaSymbol)/ sound came through as /\(sub.ipaSymbol)/.",
                        actionTip: tip,
                        word: word,
                        phonemeHint: "/\(expected.ipaSymbol)/ → /\(sub.ipaSymbol)/"
                    ))

                case .missing:
                    items.append(UserFeedbackItem(
                        level: .warning,
                        message: "The /\(phone.phone.phone.ipaSymbol)/ in '\(word)' wasn't clearly heard.",
                        actionTip: "Try saying '\(word)' slowly, making sure each sound is distinct.",
                        word: word,
                        phonemeHint: "/\(phone.phone.phone.ipaSymbol)/ missing"
                    ))

                case .weak:
                    items.append(UserFeedbackItem(
                        level: .suggestion,
                        message: "The /\(phone.phone.phone.ipaSymbol)/ in '\(word)' was a bit unclear.",
                        actionTip: "Hold the /\(phone.phone.phone.ipaSymbol)/ slightly longer for clarity.",
                        word: word,
                        phonemeHint: "/\(phone.phone.phone.ipaSymbol)/ weak"
                    ))

                default:
                    break
                }
            }
        }

        return (items, suppressed)
    }

    // MARK: - Prosody Feedback

    private func generateProsodyFeedback(
        result: PronunciationAssessmentResult
    ) -> ([UserFeedbackItem], [SuppressedIssue]) {
        var items: [UserFeedbackItem] = []
        var suppressed: [SuppressedIssue] = []

        for issue in result.prosody.issues {
            // Suppress low-confidence prosody findings
            if issue.confidence == .low {
                suppressed.append(SuppressedIssue(
                    reason: "low_confidence_prosody",
                    detail: "Suppressed \(issue.type.rawValue): \(issue.description)"
                ))
                continue
            }

            let level: FeedbackLevel
            switch issue.severity {
            case .none: continue
            case .minor: level = .suggestion
            case .moderate: level = .warning
            case .critical: level = .critical
            }

            let tip: String
            switch issue.type {
            case .weakStress:
                let word = issue.wordIndex.flatMap { idx in
                    result.wordScores.first(where: { $0.wordIndex == idx })?.word
                } ?? ""
                tip = !word.isEmpty
                    ? "Try emphasizing the stressed syllable in '\(word)' a bit more."
                    : "Try giving stressed syllables a bit more emphasis."
            case .compressedStress:
                tip = "Vary your emphasis more between stressed and unstressed syllables."
            case .flatDelivery:
                tip = "Try adding some pitch variation to make your speech sound more natural."
            case .risingIntonation:
                tip = "Try ending statements with a falling pitch instead of rising."
            case .unnaturalPacing:
                tip = "Try to keep a more even pace, with natural pauses between phrases."
            }

            items.append(UserFeedbackItem(
                level: level,
                message: issue.description,
                actionTip: tip,
                word: nil,
                phonemeHint: nil
            ))
        }

        return (items, suppressed)
    }

    // MARK: - Summary Feedback

    private func generateSummaryFeedback(result: PronunciationAssessmentResult, estimateOnly: Bool) -> [UserFeedbackItem] {
        var items: [UserFeedbackItem] = []

        if result.overallScore >= 85 {
            items.append(UserFeedbackItem(
                level: .info,
                message: "Excellent pronunciation! Your sounds were clear and well-articulated.",
                actionTip: estimateOnly ? "Keep building consistency with the same phrase once more." : nil,
                word: nil,
                phonemeHint: nil
            ))
        } else if result.overallScore >= 70 {
            items.append(UserFeedbackItem(
                level: .info,
                message: "Good pronunciation overall. A few sounds could be clearer.",
                actionTip: "Focus on the highlighted words and practice them at a slower pace.",
                word: nil,
                phonemeHint: nil
            ))
        } else if result.overallScore >= 50 {
            items.append(UserFeedbackItem(
                level: .suggestion,
                message: "Some sounds need attention. Try the phrase again more slowly.",
                actionTip: "Break the phrase into smaller chunks and practice each part separately.",
                word: nil,
                phonemeHint: nil
            ))
        } else {
            items.append(UserFeedbackItem(
                level: .warning,
                message: "Almost there. Start with one short chunk and make it clean first.",
                actionTip: "Tap the weakest word, replay it, then do one focused retry.",
                word: nil,
                phonemeHint: nil
            ))
        }

        return items
    }

    // MARK: - Articulation Tips

    private func articulationTip(expected: ARPAPhone, actual: ARPAPhone) -> String {
        // Specific tips for common confusions
        let pair = Set([expected, actual])

        if pair == Set([.V, .W]) {
            return "For /v/, touch your lower lip to upper teeth. For /w/, round both lips without touching teeth."
        }
        if pair == Set([.L, .R]) {
            return "For /l/, touch the tongue tip to the roof of your mouth. For /r/, curl the tongue back without touching."
        }
        if pair == Set([.TH, .T]) || pair == Set([.TH, .S]) {
            return "For /θ/, place your tongue lightly between your teeth and blow air gently."
        }
        if pair == Set([.DH, .D]) || pair == Set([.DH, .Z]) {
            return "For /ð/, place your tongue between your teeth and add voice."
        }
        if pair == Set([.S, .SH]) {
            return "For /s/, keep the tongue behind the teeth. For /sh/, pull it back slightly."
        }
        if pair == Set([.B, .P]) {
            return "Both use the same lip position, but /b/ is voiced (vocal cords vibrate) and /p/ is voiceless."
        }
        if pair == Set([.IY, .IH]) {
            return "For /i:/, stretch the sound longer. For /ɪ/, keep it short and relaxed."
        }
        if pair == Set([.AE, .EH]) {
            return "For /æ/, open your mouth wider and pull the tongue forward."
        }

        // Generic tip
        return "Practice saying the /\(expected.ipaSymbol)/ sound slowly, then build up to natural speed."
    }
}
