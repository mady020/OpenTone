import UIKit

/// 5-section Duolingo-style coaching feedback screen.
/// Driven entirely by SpeechAnalysisResponse from the backend.
class FeedbackCollectionViewController: UICollectionViewController {

    // MARK: - Input (set by StartJamViewController before push)
    var transcript: String?
    var audioURL: String?
    var topic: String?
    var speakingDuration: Double = 30.0
    var sessionId: String = ""
    var userId: String = "demo"

    // MARK: - State
    private var analysisResponse: SpeechAnalysisResponse?
    private var isLoading = true

    // MARK: - Section enum
    private enum Section: Int, CaseIterable {
        case score      = 0   // Big Result
        case deltas     = 1   // What Changed
        case issue      = 2   // Biggest Issue + Evidence
        case goal       = 3   // Next Goal + Practice Again
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Your Results"
        view.backgroundColor = AppColors.screenBackground
        collectionView.backgroundColor = AppColors.screenBackground
        collectionView.collectionViewLayout = createLayout()
        navigationItem.hidesBackButton = true

        // Register cells programmatically
        collectionView.register(FeedbackHeaderCell.self,    forCellWithReuseIdentifier: FeedbackHeaderCell.reuseID)
        collectionView.register(FeedbackMetricsCell.self,   forCellWithReuseIdentifier: FeedbackMetricsCell.reuseID)
        collectionView.register(FeedbackMistakeCell.self,   forCellWithReuseIdentifier: FeedbackMistakeCell.reuseID)
        collectionView.register(FeedbackTranscriptCell.self, forCellWithReuseIdentifier: FeedbackTranscriptCell.reuseID)

        setupExitButton()
        fetchAnalysis()
    }

    // MARK: - Exit button

    private func setupExitButton() {
        var cfg = UIButton.Configuration.filled()
        cfg.image = UIImage(systemName: "xmark",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold))
        cfg.cornerStyle = .capsule
        cfg.baseForegroundColor = AppColors.primary
        cfg.baseBackgroundColor = AppColors.cardBackground
        let button = UIButton(configuration: cfg)
        button.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
        button.layer.borderWidth = 1.5
        button.layer.borderColor = AppColors.primary.withAlphaComponent(0.3).cgColor
        button.layer.cornerRadius = 20
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }

    @objc private func exitTapped() {
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Backend analysis

    private func fetchAnalysis() {
        isLoading = true
        collectionView.reloadData()

        let capturedTranscript  = transcript ?? ""
        let capturedDuration    = speakingDuration
        let capturedUserId      = userId.isEmpty ? "demo" : userId
        let capturedSessionId   = sessionId.isEmpty ? UUID().uuidString : sessionId
        let capturedAudioURL    = audioURL

        Task {
            do {
                let response = try await BackendSpeechService.shared.analyze(
                    audioURL:   capturedAudioURL,
                    transcript: capturedTranscript,
                    durationS:  capturedDuration,
                    userId:     capturedUserId,
                    sessionId:  capturedSessionId
                )
                await MainActor.run {
                    self.analysisResponse = response
                    self.isLoading = false
                    self.collectionView.reloadData()
                }
            } catch {
                print("⚠️ Analysis failed: \(error.localizedDescription)")
                await MainActor.run {
                    // Use local fallback metrics
                    self.analysisResponse = nil
                    self.isLoading = false
                    self.collectionView.reloadData()
                }
            }
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    override func collectionView(_ collectionView: UICollectionView,
                                  cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section)! {

        // ── Section 0: Big Score ──────────────────────────────────────────
        case .score:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FeedbackHeaderCell.reuseID, for: indexPath) as! FeedbackHeaderCell
            if isLoading {
                cell.configure(score: 0, direction: "mixed", summary: "Analysing your speech…")
            } else if let r = analysisResponse {
                let overall = r.coaching.scores.overall
                cell.configure(score: overall, direction: r.progress.overallDirection, summary: r.progress.weeklySummary)
            } else {
                cell.configure(score: 0, direction: "mixed", summary: "Could not reach backend — check your connection.")
            }
            return cell

        // ── Section 1: Deltas ─────────────────────────────────────────────
        case .deltas:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FeedbackMetricsCell.reuseID, for: indexPath) as! FeedbackMetricsCell
            if isLoading {
                cell.configure(rows: [("hourglass", "Calculating changes…", true)])
            } else if let r = analysisResponse {
                var rows: [(icon: String, text: String, positive: Bool)] = []
                let d = r.progress.deltas
                // WPM delta
                if abs(d.wpm) >= 1 {
                    let pos = d.wpm > 0
                    rows.append(("speedometer", pos
                        ? "Speaking speed up \(Int(d.wpm)) WPM — closer to ideal pace"
                        : "Speaking speed dropped \(Int(abs(d.wpm))) WPM — keep practising", pos))
                }
                // Filler delta (positive = fewer fillers = better)
                if abs(d.fillers) >= 0.1 {
                    let pos = d.fillers > 0
                    rows.append(("waveform", pos
                        ? String(format: "%.1f fewer fillers per minute", d.fillers)
                        : String(format: "%.1f more fillers than last session", abs(d.fillers)), pos))
                }
                // Pauses (positive = shorter pauses = better)
                if abs(d.pauses) >= 0.05 {
                    let pos = d.pauses > 0
                    rows.append(("pause.circle", pos
                        ? String(format: "Pauses shortened by %.1fs on average", d.pauses)
                        : String(format: "Pauses grew %.1fs longer on average", abs(d.pauses)), pos))
                }

                // First session or no change yet
                if rows.isEmpty {
                    rows = [("checkmark.circle", "First session baseline recorded!", true)]
                }
                // Scores row
                let scores = r.coaching.scores
                rows.append(("chart.bar.fill",
                    String(format: "Fluency %.0f  ·  Confidence %.0f  ·  Clarity %.0f",
                           scores.fluency, scores.confidence, scores.clarity), true))
                cell.configure(rows: rows)
            } else {
                cell.configure(rows: [("wifi.slash", "Could not load coaching data", false)])
            }
            return cell

        // ── Section 2: Issue + Evidence ───────────────────────────────────
        case .issue:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FeedbackMistakeCell.reuseID, for: indexPath) as! FeedbackMistakeCell
            if isLoading {
                cell.configure(original: "Analysing your speech…", correction: "", explanation: "")
            } else if let r = analysisResponse {
                cell.configureCoaching(issueTitle: r.coaching.primaryIssueTitle, evidence: r.coaching.evidence)
            } else {
                cell.configure(original: "Good effort!", correction: "No data", explanation: "")
            }
            return cell

        // ── Section 3: Next Goal + Transcript ────────────────────────────
        case .goal:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FeedbackTranscriptCell.reuseID, for: indexPath) as! FeedbackTranscriptCell
            if isLoading {
                cell.configure(transcript: transcript ?? "")
            } else if let r = analysisResponse {
                let goal = r.coaching.suggestions.first ?? r.coaching.strengths.first ?? "Keep practising daily."
                cell.configureCoaching(
                    nextGoal:       goal,
                    transcript:     r.transcript,
                    fillerExamples: r.metrics.fillerExamples,
                    repetitions:    r.metrics.repetitions
                )
            } else {
                cell.configureCoaching(nextGoal: "Practise again to get your first coaching report.", transcript: transcript ?? "")
            }
            cell.onPracticeAgain = { [weak self] in
                self?.navigationController?.popToRootViewController(animated: true)
            }
            return cell
        }
    }

    // MARK: - Layout

    private func createLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(180)
            ))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(180)
            ), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
            return section
        }
    }
}
