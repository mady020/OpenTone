//
//  FeedbackCollectionViewController.swift
//  OpenTone
//
//  Created by M S on 26/02/26.
//  Rebuilt: Phase 1 — real feedback screen backed by BackendSpeechService.
//

import UIKit

extension Notification.Name {
    static let roleplayFeedbackCompleted = Notification.Name("OpenTone.roleplayFeedbackCompleted")
}

// MARK: - Section model

private enum FeedbackSection: Int, CaseIterable {
    case loading = 0   // spinner while we wait for the backend
    case scores        // performance snapshot cards
    case metrics       // speaking signals
    case coaching      // action plan
    case transcript    // transcript with in-place mistake annotations
    case progress      // deltas vs. previous session
}

private let scoreCellId      = "ScoreCell"
private let metricCellId     = "MetricCell"
private let coachingCellId   = "CoachingCell"
private let progressCellId   = "ProgressCell"
private let loadingCellId    = "LoadingCell"
private let headerKind       = UICollectionView.elementKindSectionHeader
private let headerReuseId    = "FeedbackHeader"

// MARK: - Controller

class FeedbackCollectionViewController: UIViewController {

    // ---- Public properties set by the pushing screen (StartJamVC) ----------

    var transcript: String?
    var topic: String?
    var speakingDuration: Double = 30
    var sessionId: String = ""
    var userId: String = "demo"
    var audioURL: String?          // local file:// or remote URL
    var sessionMode: FeedbackSessionMode = .jam
    var activityType: ActivityType = .jam
    var feedbackEngine: FeedbackEngine = FeedbackEngineFactory.makeDefault()
    var aiFeedbackEnabled: Bool?

    /// Pre-fetched response — if set, the VC skips its own network call.
    /// Used by AI Call and Roleplay to inject the already-fetched analysis.
    var preloadedResponse: SpeechAnalysisResponse?

    // ---- Private state -----------------------------------------------------

    private var feedback: Feedback?
    private var analysisResponse: SpeechAnalysisResponse?
    private var isLoading = true
    private var errorMessage: String?
    private var hasPresentedDailyGoalAchievement = false
    private var hasCommittedSessionProgress = false
    private var shouldCommitProgressWhenVisible = false

    private var collectionView: UICollectionView!

    private var effectiveAIFeedbackEnabled: Bool {
        if let aiFeedbackEnabled {
            return aiFeedbackEnabled
        }
        return UserDataModel.shared.getCurrentUser()?.aiFeedbackEnabled ?? false
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Session Feedback"
        view.backgroundColor = AppColors.screenBackground
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done", style: .done, target: self, action: #selector(doneTapped)
        )

        configureCollectionView()
        fetchAnalysis()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        commitSessionProgressIfPossible()
    }

    // MARK: - Layout

    private func configureCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = AppColors.screenBackground
        collectionView.dataSource = self
        collectionView.delegate = self

        // Register cells
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: loadingCellId)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: scoreCellId)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: metricCellId)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: coachingCellId)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: progressCellId)
        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: headerKind,
            withReuseIdentifier: headerReuseId
        )

        view.addSubview(collectionView)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, env in
            let section: FeedbackSection
            if self?.isLoading == true || self?.errorMessage != nil {
                section = .loading
            } else {
                section = FeedbackSection(rawValue: sectionIndex + 1) ?? .scores
            }
            switch section {
            case .loading:      return Self.listSection()
            case .scores:       return Self.scoreGridSection()
            case .metrics:      return Self.listSection()
            case .coaching:     return Self.listSection()
            case .transcript:   return Self.listSection()
            case .progress:     return Self.listSection()
            }
        }
    }

    private static func listSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(56))
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(56)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 8, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 8
        section.boundarySupplementaryItems = [headerItem()]
        return section
    }

    private static func scoreGridSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(100))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100)),
            subitems: [item, item]
        )
        group.interItemSpacing = .fixed(12)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 8, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 12
        section.boundarySupplementaryItems = [headerItem()]
        return section
    }

    private static func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        return .init(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(36)),
            elementKind: headerKind,
            alignment: .top
        )
    }

    // MARK: - Analysis

    private func fetchAnalysis() {
        // If the caller already provided an analysis, don't refetch
        if let preloaded = preloadedResponse {
            let sanitized = sanitizedResponseForDisplay(preloaded)
            self.analysisResponse = sanitized
            self.feedback = FeedbackMapper.toFeedback(sanitized)
            self.isLoading = false
            self.collectionView.reloadData()
            self.persistFeedbackToHistory(sanitized)
            prepareSessionProgressCommit()
            return
        }

        Task {
            let response: SpeechAnalysisResponse
            var resolvedTranscript = transcript ?? ""

                     // Prefer extracting transcription locally from the recorded file.
                if let urlString = audioURL,
                   let fileURL = URL(string: urlString),
                   FileManager.default.fileExists(atPath: fileURL.path) {

                    resolvedTranscript = await withCheckedContinuation { continuation in
                        AudioManager.shared.transcribeFile(at: fileURL) { text in
                            continuation.resume(returning: text ?? "")
                        }
                    }
                }

                self.transcript = resolvedTranscript

                // Analyze via feedback engine (on-device core + optional enhancement provider).
                let input = FeedbackEngineInput(
                    transcript: resolvedTranscript,
                    topic: topic ?? "",
                    durationS: speakingDuration > 0 ? speakingDuration : 30.0,
                    userId: userId,
                    sessionId: sessionId,
                    mode: sessionMode,
                    turnSummaries: []
                )
                response = await feedbackEngine.analyze(input)

            let sanitized = self.sanitizedResponseForDisplay(response)
            self.analysisResponse = sanitized
            self.feedback = FeedbackMapper.toFeedback(sanitized)
            self.isLoading = false
            await MainActor.run {
                self.collectionView.reloadData()
            }
            self.persistFeedbackToHistory(sanitized)
            self.prepareSessionProgressCommit()
        }
    }

    private func prepareSessionProgressCommit() {
        shouldCommitProgressWhenVisible = true
        DispatchQueue.main.async { [weak self] in
            self?.commitSessionProgressIfPossible()
        }
    }

    private func commitSessionProgressIfPossible() {
        guard shouldCommitProgressWhenVisible, !hasCommittedSessionProgress else { return }
        guard isViewLoaded, view.window != nil else { return }

        let durationSeconds = speakingDuration
        guard durationSeconds >= minimumDurationSeconds(for: sessionMode) else {
            print("[Feedback] Skipping progress commit: duration below threshold.")
            shouldCommitProgressWhenVisible = false
            return
        }

        guard hasActivityEvidence() else {
            print("[Feedback] Skipping progress commit: no activity evidence.")
            shouldCommitProgressWhenVisible = false
            return
        }

        let minutes = max(1, Int(ceil(durationSeconds / 60.0)))
        let trimmedTopic = topic?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let resolvedTopic = trimmedTopic.isEmpty ? sessionProgressType(for: sessionMode).title : trimmedTopic
        SessionProgressManager.shared.markCompleted(
            sessionProgressType(for: sessionMode),
            topic: resolvedTopic,
            actualDurationMinutes: minutes
        )

        hasCommittedSessionProgress = true
        shouldCommitProgressWhenVisible = false
    }

    private func minimumDurationSeconds(for mode: FeedbackSessionMode) -> Double {
        switch mode {
        case .aiCall, .roleplay:
            return 30
        case .jam:
            return 20
        }
    }

    private func sessionProgressType(for mode: FeedbackSessionMode) -> SessionProgressManager.SessionType {
        switch mode {
        case .aiCall:
            return .aiCall
        case .jam:
            return .twoMinJam
        case .roleplay:
            return .roleplay
        }
    }

    private func hasActivityEvidence() -> Bool {
        let directTranscript = (transcript ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !directTranscript.isEmpty {
            return true
        }

        let analyzedTranscript = (analysisResponse?.transcript ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !analyzedTranscript.isEmpty
    }

    private func sanitizedResponseForDisplay(_ response: SpeechAnalysisResponse) -> SpeechAnalysisResponse {
        guard !effectiveAIFeedbackEnabled, response.coaching.llmCoaching != nil else {
            return response
        }

        let coaching = SpeechCoaching(
            scores: response.coaching.scores,
            primaryIssue: response.coaching.primaryIssue,
            primaryIssueTitle: response.coaching.primaryIssueTitle,
            secondaryIssues: response.coaching.secondaryIssues,
            strengths: response.coaching.strengths,
            suggestions: response.coaching.suggestions,
            evidence: response.coaching.evidence,
            llmCoaching: nil
        )

        return SpeechAnalysisResponse(
            transcript: response.transcript,
            metrics: response.metrics,
            coaching: coaching,
            progress: response.progress
        )
    }

    /// Persist the analysis result as a SessionFeedback on the most recent matching activity.
    private func persistFeedbackToHistory(_ response: SpeechAnalysisResponse) {
        let sid = UUID(uuidString: sessionId) ?? UUID()
        let sessionFeedback = FeedbackMapper.toSessionFeedback(response, sessionId: sid)

        // Attach to the latest activity for this session type.
        HistoryDataModel.shared.attachFeedbackToLatestActivity(
            type: activityType,
            feedback: sessionFeedback
        )

        handleFeedbackLifecycleUpdate()
    }

    private func handleFeedbackLifecycleUpdate() {
        NotificationCenter.default.post(name: SessionProgressManager.progressDataUpdatedNotification, object: nil)
        maybePresentDailyGoalAchievement()
    }

    private func maybePresentDailyGoalAchievement() {
        guard !hasPresentedDailyGoalAchievement else { return }
        guard shouldPresentDailyGoalAchievement() else { return }

        hasPresentedDailyGoalAchievement = true
        markDailyGoalAchievementShown()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let achievementVC = DailyGoalAchievementViewController()
            achievementVC.modalPresentationStyle = .overFullScreen
            self.present(achievementVC, animated: true)
        }
    }

    private func shouldPresentDailyGoalAchievement() -> Bool {
        let todayMinutes = StreakDataModel.shared.totalMinutes(for: Date())
        let goal = StreakDataModel.shared.getStreak()?.commitment ?? 0
        guard goal > 0, todayMinutes >= goal else { return false }

        let key = dailyGoalAchievementKey()
        return !UserDefaults.standard.bool(forKey: key)
    }

    private func markDailyGoalAchievementShown() {
        UserDefaults.standard.set(true, forKey: dailyGoalAchievementKey())
    }

    private func dailyGoalAchievementKey() -> String {
        let userKey = UserDataModel.shared.getCurrentUser()?.id.uuidString ?? "anonymous"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dayKey = formatter.string(from: Date())
        return "opentone.dailyGoalAchievement.\(userKey).\(dayKey)"
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        NotificationCenter.default.post(name: SessionProgressManager.progressDataUpdatedNotification, object: nil)

        if sessionMode == .roleplay {
            routeAfterRoleplayFeedbackDone()
            return
        }

        // If presented modally (e.g. from AI Call), dismiss the entire nav stack
        if presentingViewController != nil || navigationController?.presentingViewController != nil {
            dismiss(animated: true)
        } else {
            // Pushed on a navigation stack (e.g. from Jam session)
            navigationController?.popToRootViewController(animated: true)
        }
    }

    private func routeAfterRoleplayFeedbackDone() {
        let presenter = navigationController?.presentingViewController ?? presentingViewController

        dismiss(animated: true) {
            NotificationCenter.default.post(name: .roleplayFeedbackCompleted, object: nil)

            // Preferred: return to roleplay root/info screen rather than reopening the last chat state.
            if let roleplayChat = presenter as? RoleplayChatViewController {
                roleplayChat.tabBarController?.tabBar.isHidden = false
                roleplayChat.navigationController?.popToRootViewController(animated: true)
                return
            }

            if let nav = presenter as? UINavigationController,
               let roleplayChat = nav.topViewController as? RoleplayChatViewController {
                roleplayChat.tabBarController?.tabBar.isHidden = false
                roleplayChat.navigationController?.popToRootViewController(animated: true)
                return
            }

            // Fallback: route user to Home tab if available.
            if let tabBar = presenter?.tabBarController {
                tabBar.tabBar.isHidden = false
                tabBar.selectedIndex = 0
            }
        }
    }

    // MARK: - Cell helpers

    private func makeCard(_ cell: UICollectionViewCell) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 14
        cell.contentView.clipsToBounds = true
    }

    private func addLabel(to cell: UICollectionViewCell, text: String, font: UIFont = .systemFont(ofSize: 15),
                          color: UIColor = .label, lines: Int = 0, insets: UIEdgeInsets = .init(top: 12, left: 14, bottom: 12, right: 14)) {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = font
        lbl.textColor = color
        lbl.numberOfLines = lines
        lbl.adjustsFontForContentSizeCategory = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: insets.top),
            lbl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: insets.left),
            lbl.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -insets.right),
            lbl.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -insets.bottom),
        ])
    }

    private func addAttributedLabel(to cell: UICollectionViewCell,
                                    attributedText: NSAttributedString,
                                    insets: UIEdgeInsets = .init(top: 12, left: 14, bottom: 12, right: 14)) {
        let lbl = UILabel()
        lbl.attributedText = attributedText
        lbl.numberOfLines = 0
        lbl.adjustsFontForContentSizeCategory = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: insets.top),
            lbl.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: insets.left),
            lbl.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -insets.right),
            lbl.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -insets.bottom),
        ])
    }

    private func coachingSuggestions(from response: SpeechAnalysisResponse, feedback: Feedback) -> [String] {
        let llmSuggestions = response.coaching.llmCoaching?.suggestions ?? []
        if !llmSuggestions.isEmpty {
            return Array(llmSuggestions.prefix(4))
        }
        return Array((feedback.coaching?.suggestions ?? []).prefix(4)).enumerated().map { index, suggestion in
            "Step \(index + 1): \(suggestion)"
        }
    }

    private func coachingFocus(from response: SpeechAnalysisResponse, feedback: Feedback) -> String {
        let llmPrimary = response.coaching.llmCoaching?.primaryIssue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !llmPrimary.isEmpty {
            return "\(severityPrefix(from: response.coaching.scores)) \(llmPrimary)"
        }
        let focus = feedback.coaching?.primaryIssueTitle ?? "Good job"
        let detail = response.coaching.primaryIssue
        return "\(severityPrefix(from: response.coaching.scores)) \(focus): \(detail)"
    }

    private func severityPrefix(from scores: CoachingScores) -> String {
        let overall = scores.overall
        switch overall {
        case ..<45: return "High priority"
        case ..<70: return "Medium priority"
        default: return "Low priority"
        }
    }

    private func timestampString(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func transcriptWithPauseMarkers(from response: SpeechAnalysisResponse) -> String {
        let transcript = response.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else { return "No transcript available." }

        let words = transcript.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return transcript }

        let totalDuration = max(response.metrics.durationS, 0.1)
        var insertions: [Int: [String]] = [:]

        for pause in response.metrics.pauseExamples.prefix(5) {
            let ratio = min(max(pause.start / totalDuration, 0), 1)
            let rawIndex = Int((Double(words.count) * ratio).rounded())
            let insertionIndex = min(max(rawIndex, 1), words.count)
            let marker = "[⏸ \(String(format: "%.1f", pause.duration))s pause]"
            insertions[insertionIndex, default: []].append(marker)
        }

        var rendered: [String] = []
        for (index, word) in words.enumerated() {
            if let markers = insertions[index], !markers.isEmpty {
                rendered.append(contentsOf: markers)
            }
            rendered.append(word)
        }

        if let tailMarkers = insertions[words.count], !tailMarkers.isEmpty {
            rendered.append(contentsOf: tailMarkers)
        }

        return rendered.joined(separator: " ")
    }

    private func highlightedTranscript(from response: SpeechAnalysisResponse) -> NSAttributedString {
        let displayText = transcriptWithPauseMarkers(from: response)
        let attributed = NSMutableAttributedString(
            string: displayText,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: AppColors.textPrimary,
            ]
        )

        let fullRange = NSRange(location: 0, length: (displayText as NSString).length)
        let pausePattern = "\\[⏸\\s[0-9.]+s\\spause\\]"
        if let regex = try? NSRegularExpression(pattern: pausePattern, options: []) {
            regex.matches(in: displayText, options: [], range: fullRange).forEach { match in
                attributed.addAttributes([
                    .foregroundColor: UIColor.systemBlue,
                    .font: UIFont.preferredFont(forTextStyle: .callout),
                    .backgroundColor: UIColor.systemBlue.withAlphaComponent(0.14),
                ], range: match.range)
            }
        }

        let fillerWords = Set(response.metrics.fillerExamples.map { $0.word.lowercased() })
        for filler in fillerWords where !filler.isEmpty {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: filler))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            regex.matches(in: displayText, options: [], range: fullRange).forEach { match in
                attributed.addAttributes([
                    .foregroundColor: UIColor.systemOrange,
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .backgroundColor: UIColor.systemOrange.withAlphaComponent(0.2),
                ], range: match.range)
            }
        }

        let repetitionPattern = "\\b([A-Za-z']+)\\b(?:\\W+\\1\\b)+"
        if let regex = try? NSRegularExpression(pattern: repetitionPattern, options: [.caseInsensitive]) {
            regex.matches(in: displayText, options: [], range: fullRange).forEach { match in
                attributed.addAttributes([
                    .foregroundColor: UIColor.systemRed,
                    .backgroundColor: UIColor.systemRed.withAlphaComponent(0.14),
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ], range: match.range)
            }
        }

        let pronunciationWords = response.coaching.evidence
            .filter { $0.type == "phoneme" }
            .compactMap { phonemeObservedFragment(from: $0.text) }

        for word in Set(pronunciationWords) where !word.isEmpty {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            regex.matches(in: displayText, options: [], range: fullRange).forEach { match in
                attributed.addAttributes([
                    .foregroundColor: UIColor.systemGreen,
                    .backgroundColor: UIColor.systemGreen.withAlphaComponent(0.15),
                ], range: match.range)
            }
        }

        for range in paceRiskRanges(in: displayText, wpm: response.metrics.wpm) {
            attributed.addAttributes([
                .underlineStyle: NSUnderlineStyle.patternDot.union(.single).rawValue,
                .underlineColor: UIColor.systemPurple,
            ], range: range)
        }

        return attributed
    }

    private func paceRiskRanges(in transcript: String, wpm: Double) -> [NSRange] {
        guard wpm >= 170 else { return [] }

        let nsText = transcript as NSString
        let sentenceParts = transcript.split(whereSeparator: { ".!?".contains($0) })
        var ranges: [NSRange] = []

        for part in sentenceParts {
            let sentence = String(part).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sentence.isEmpty else { continue }

            let words = sentence.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            if words.count >= 22 {
                let range = nsText.range(of: sentence)
                if range.location != NSNotFound {
                    ranges.append(range)
                }
            }
        }

        return ranges
    }

    private func transcriptLegendEntries(from response: SpeechAnalysisResponse) -> [String] {
        var entries: [String] = []

        if response.metrics.fillers > 0 {
            entries.append("🟧 Filler word: highlighted phrase to reduce in next attempt.")
        }
        if response.metrics.pauses > 0 {
            entries.append("🔵 [⏸ xs pause]: inferred pause point and duration inside your transcript.")
        }
        if response.metrics.repetitions > 0 {
            entries.append("🔴 Underline + tint: repeated restart phrase.")
        }
        if response.metrics.wpm >= 170 {
            entries.append("🟣 Dotted underline: dense fast segment that may reduce clarity.")
        }

        if response.coaching.evidence.contains(where: { $0.type == "phoneme" }) {
            entries.append("🟩 Pronunciation cue: likely sound substitution on this word.")
        }

        if entries.isEmpty {
            entries.append("No major mistake markers detected in this transcript.")
        }

        return entries
    }

    private func transcriptMistakeTotals(from response: SpeechAnalysisResponse) -> String {
        let paceAlerts = paceRiskRanges(in: response.transcript, wpm: response.metrics.wpm).count
        let pronunciationAlerts = response.coaching.evidence.filter { $0.type == "phoneme" }.count
        let paceText = paceAlerts > 0 ? "⚡ Pace alerts: \(paceAlerts)" : "⚡ Pace alerts: 0"
        return [
            "🟧 Fillers: \(response.metrics.fillers)",
            "🔵 Pauses: \(response.metrics.pauses)",
            "🔴 Repetitions: \(response.metrics.repetitions)",
            "🟩 Pronunciation alerts: \(pronunciationAlerts)",
            paceText,
        ].joined(separator: "   •   ")
    }

    private func phonemeObservedFragment(from text: String) -> String? {
        guard let arrowRange = text.range(of: "->") else { return nil }
        let observed = text[..<arrowRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
        return observed.isEmpty ? nil : observed
    }

    private func scoreDescriptor(_ value: Double) -> String {
        switch value {
        case 85...: return "Strong"
        case 70..<85: return "Good"
        case 55..<70: return "Needs focus"
        default: return "Priority"
        }
    }

    private func metricLines(from feedback: Feedback, response: SpeechAnalysisResponse) -> [String] {
        let wpm = Int(feedback.wordsPerMinute.rounded())
        let wpmLabel: String
        if wpm < 110 {
            wpmLabel = "Slow"
        } else if wpm > 170 {
            wpmLabel = "Fast"
        } else {
            wpmLabel = "Steady"
        }

        let fillerLabel = response.metrics.fillers == 0 ? "Clean" : (response.metrics.fillers <= 3 ? "Manageable" : "High")
        let pauseLabel = response.metrics.pauses == 0 ? "Smooth" : (response.metrics.avgPauseS < 1.2 ? "Natural" : "Hesitant")
        let durationLabel = feedback.durationInSeconds >= 28 ? "Full run" : "Short run"

        return [
            "🗣  Pace: \(wpm) WPM · \(wpmLabel)",
            "😬  Fillers: \(feedback.fillerWordCount ?? 0) · \(fillerLabel)",
            "⏸  Pauses: \(feedback.pauseCount ?? 0) · \(pauseLabel)",
            "⏱  Duration: \(String(format: "%.0f", feedback.durationInSeconds))s · \(durationLabel)",
        ]
    }

    private func scoreCard(_ cell: UICollectionViewCell, title: String, value: Double) {
        makeCard(cell)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -14),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -8),
        ])

        let numLabel = UILabel()
        numLabel.text = String(format: "%.0f", value)
        numLabel.font = .systemFont(ofSize: 28, weight: .bold)
        numLabel.textColor = AppColors.primary

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center

        let progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.trackTintColor = AppColors.cardBorder
        progressBar.progressTintColor = AppColors.primary
        progressBar.progress = Float(max(0, min(100, value)) / 100.0)

        stack.addArrangedSubview(numLabel)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(progressBar)

        NSLayoutConstraint.activate([
            progressBar.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.8)
        ])
    }
}

// MARK: - UICollectionViewDataSource

extension FeedbackCollectionViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if isLoading || errorMessage != nil { return 1 }     // loading / error
        guard feedback != nil else { return 1 }
        return FeedbackSection.allCases.count - 1            // skip .loading section
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isLoading { return 1 }
        if errorMessage != nil { return 1 }

        // Map displayed section back (we skip .loading when data is ready)
        let mapped = FeedbackSection(rawValue: section + 1) ?? .scores
        guard let fb = feedback, let resp = analysisResponse else { return 0 }

        switch mapped {
        case .loading:       return 0
        case .scores:        return 4   // overall, fluency, confidence, clarity
        case .metrics:       return 4   // WPM, fillers, pauses, duration
        case .coaching:      return effectiveAIFeedbackEnabled ? 2 : 1
        case .transcript:    return 3   // transcript, legend, totals
        case .progress:      return 1   // deltas card
        }
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        // --- Loading / error state ---
        if isLoading {
            let cell = cv.dequeueReusableCell(withReuseIdentifier: loadingCellId, for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.startAnimating()
            spinner.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                spinner.heightAnchor.constraint(equalToConstant: 80),
            ])
            return cell
        }
        if let err = errorMessage {
            let cell = cv.dequeueReusableCell(withReuseIdentifier: loadingCellId, for: indexPath)
            makeCard(cell)
            addLabel(to: cell, text: "⚠️ \(err)", font: .systemFont(ofSize: 14), color: .systemRed)
            return cell
        }

        guard let fb = feedback, let resp = analysisResponse else {
            return cv.dequeueReusableCell(withReuseIdentifier: loadingCellId, for: indexPath)
        }

        let mapped = FeedbackSection(rawValue: indexPath.section + 1) ?? .scores

        switch mapped {

        // --- Scores (2×2 grid) ---
        case .scores:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: scoreCellId, for: indexPath)
            let titles = ["Overall", "Fluency", "Confidence", "Clarity"]
            let values: [Double] = [
                fb.coaching?.scores.overall ?? 0,
                fb.coaching?.scores.fluency ?? 0,
                fb.coaching?.scores.confidence ?? 0,
                fb.coaching?.scores.clarity ?? 0,
            ]
            scoreCard(cell, title: "\(titles[indexPath.item]) • \(scoreDescriptor(values[indexPath.item]))", value: values[indexPath.item])
            return cell

        // --- Metrics ---
        case .metrics:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: metricCellId, for: indexPath)
            makeCard(cell)
            let labels = metricLines(from: fb, response: resp)
            addLabel(to: cell, text: labels[indexPath.item], font: .systemFont(ofSize: 15, weight: .medium))
            return cell

        // --- Coaching ---
        case .coaching:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: coachingCellId, for: indexPath)
            makeCard(cell)
            if indexPath.item == 0 {
                let issue = coachingFocus(from: resp, feedback: fb)
                let strengths = resp.coaching.strengths.prefix(2).joined(separator: " ")
                let text = "🎯 Main focus\n\(issue)\n\n✅ What went well\n\(strengths)"
                addLabel(to: cell, text: text, font: .systemFont(ofSize: 15, weight: .semibold), color: AppColors.primary)
            } else {
                let suggestions = coachingSuggestions(from: resp, feedback: fb)
                let text = suggestions.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
                addLabel(to: cell, text: "🤖 AI Coach Suggestions\n\n\(text)", font: .systemFont(ofSize: 14, weight: .regular), color: AppColors.textPrimary)
            }
            return cell

        // --- Transcript ---
        case .transcript:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: coachingCellId, for: indexPath)
            makeCard(cell)
            if indexPath.item == 0 {
                let head = NSMutableAttributedString(
                    string: "Marked Transcript\n\n",
                    attributes: [
                        .font: UIFont.preferredFont(forTextStyle: .headline),
                        .foregroundColor: AppColors.textPrimary,
                    ]
                )
                head.append(highlightedTranscript(from: resp))
                addAttributedLabel(to: cell, attributedText: head)
            } else if indexPath.item == 1 {
                let legend = transcriptLegendEntries(from: resp).joined(separator: "\n")
                addLabel(
                    to: cell,
                    text: "Legend\n\n\(legend)",
                    font: .preferredFont(forTextStyle: .footnote),
                    color: .secondaryLabel
                )
            } else {
                addLabel(
                    to: cell,
                    text: "Mistake Totals\n\n\(transcriptMistakeTotals(from: resp))",
                    font: .preferredFont(forTextStyle: .subheadline),
                    color: AppColors.textPrimary
                )
            }
            return cell

        // --- Progress deltas ---
        case .progress:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: progressCellId, for: indexPath)
            makeCard(cell)
            let prog = resp.progress
            var parts: [String] = []
            if let w = prog.deltas.wpmDescription      { parts.append(w) }
            if let f = prog.deltas.fillersDescription   { parts.append(f) }
            let arrow = prog.directionArrow
            let summary = parts.isEmpty ? "First session — baseline set!" : parts.joined(separator: "\n")

            var tradeoff = ""
            if prog.deltas.wpm > 0, prog.deltas.fillers < 0 {
                tradeoff = "\n\nTradeoff: pace improved, but filler rate increased."
            }

            addLabel(to: cell, text: "\(arrow) \(prog.weeklySummary)\n\n\(summary)\(tradeoff)", font: .systemFont(ofSize: 14))
            return cell

        default:
            return cv.dequeueReusableCell(withReuseIdentifier: loadingCellId, for: indexPath)
        }
    }

    func collectionView(_ cv: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = cv.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: headerReuseId, for: indexPath
        )
        header.subviews.forEach { $0.removeFromSuperview() }

        if isLoading || errorMessage != nil {
            return header  // no header during loading
        }

        let mapped = FeedbackSection(rawValue: indexPath.section + 1) ?? .scores
        let titles: [FeedbackSection: String] = [
            .scores: "Performance Snapshot", .metrics: "Speaking Signals", .coaching: effectiveAIFeedbackEnabled ? "AI Action Plan" : "Action Plan",
            .transcript: "Marked Transcript",
            .progress: "Your Progress",
        ]

        let lbl = UILabel()
        lbl.text = titles[mapped] ?? ""
        lbl.font = .systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = .label
        lbl.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            lbl.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -4),
        ])

        return header
    }
}

// MARK: - UICollectionViewDelegate

extension FeedbackCollectionViewController: UICollectionViewDelegate {}

// MARK: - Safe subscript

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
