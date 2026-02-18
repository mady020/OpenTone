import UIKit

class FeedbackCollectionViewController: UICollectionViewController {

    /// Optional feedback data — populated after Gemini analysis.
    var feedback: Feedback?

    /// Raw transcript passed from the speaking session.
    var transcript: String?
    /// Topic the user was speaking about.
    var topic: String?
    /// Duration the user was speaking (seconds).
    var speakingDuration: Double = 30.0

    /// Whether we are currently loading feedback from Gemini.
    private var isLoadingFeedback = false

    @IBOutlet weak var exitButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.screenBackground
        collectionView.backgroundColor = AppColors.screenBackground
        collectionView.collectionViewLayout = createLayout()

        // Replace the storyboard nav button with a proper xmark button
        setupExitButton()

        // If we have a transcript but no feedback yet, fetch from Gemini
        if feedback == nil, let transcript = transcript {
            fetchGeminiFeedback(transcript: transcript)
        }
    }

    private func setupExitButton() {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold))
        config.cornerStyle = .capsule
        config.baseForegroundColor = AppColors.primary
        config.baseBackgroundColor = AppColors.cardBackground

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(exitButtonTapped(_:)), for: .touchUpInside)
        button.layer.borderWidth = 1.5
        button.layer.borderColor = AppColors.primary.withAlphaComponent(0.3).cgColor
        button.layer.cornerRadius = 20
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }

    
    @IBAction func exitButtonTapped(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Gemini Feedback

    private func fetchGeminiFeedback(transcript: String) {
        isLoadingFeedback = true
        collectionView.reloadData()

        let topicText = topic ?? "General Topic"
        let duration = speakingDuration

        Task {
            do {
                let result = try await GeminiService.shared.generateJamFeedback(
                    transcript: transcript,
                    topic: topicText,
                    durationSeconds: duration
                )
                self.feedback = result
                // Log the session once feedback is received
                let durationMinutes = Int(ceil(duration / 60.0))
                StreakDataModel.shared.logSession(
                    title: "Jam Session",
                    subtitle: "Speaking practice",
                    topic: topicText,
                    durationMinutes: max(1, durationMinutes),
                    xp: 20,
                    iconName: "waveform"
                )
            } catch {
                print("⚠️ Gemini feedback failed: \(error.localizedDescription)")
                // Build a basic local feedback if Gemini fails
                self.feedback = buildLocalFeedback(transcript: transcript, duration: duration)
                
                // Still log the session even if Gemini fails
                let durationMinutes = Int(ceil(duration / 60.0))
                StreakDataModel.shared.logSession(
                    title: "Jam Session",
                    subtitle: "Speaking practice",
                    topic: topicText,
                    durationMinutes: max(1, durationMinutes),
                    xp: 15, // Slightly less XP for failed analysis
                    iconName: "waveform"
                )
            }
            self.isLoadingFeedback = false
            self.collectionView.reloadData()
        }
    }

    /// Fallback: compute basic metrics locally if Gemini is unavailable.
    private func buildLocalFeedback(transcript: String, duration: Double) -> Feedback {
        let words = transcript.split(separator: " ")
        let totalWords = words.count
        let wpm = duration > 0 ? Double(totalWords) / (duration / 60.0) : 0

        let fillerPatterns = ["um", "uh", "like", "you know", "basically", "actually", "literally"]
        let lower = transcript.lowercased()
        let fillerCount = fillerPatterns.reduce(0) { count, filler in
            count + lower.components(separatedBy: filler).count - 1
        }

        let rating: SessionFeedbackRating
        if totalWords > 60 { rating = .excellent }
        else if totalWords > 30 { rating = .good }
        else if totalWords > 10 { rating = .average }
        else { rating = .poor }

        return Feedback(
            comments: totalWords < 5
                ? "Try to speak more next time! Practice makes perfect."
                : "Good effort! Keep practicing to improve fluency.",
            rating: rating,
            wordsPerMinute: wpm,
            durationInSeconds: duration,
            totalWords: totalWords,
            transcript: transcript,
            fillerWordCount: fillerCount,
            pauseCount: nil,
            mistakes: nil,
            aiFeedbackSummary: nil
        )
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2:
            // Show actual mistake count (or 0 while loading)
            if isLoadingFeedback { return 1 }
            let count = feedback?.mistakes?.count ?? 0
            return max(count, 1) // At least 1 to show "no mistakes" message
        case 3: return 1
        default: return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FeedbackHeaderCell",
                for: indexPath
            ) as! FeedbackHeaderCell
            return cell

        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FeedbackMetricsCell",
                for: indexPath
            ) as! FeedbackMetricsCell

            if isLoadingFeedback {
                cell.configure(
                    speechValue: "...",
                    speechProgress: 0,
                    fillerValue: "...",
                    fillerProgress: 0,
                    wpmValue: "...",
                    wpmProgress: 0,
                    pausesValue: "Analyzing...",
                    pausesProgress: 0
                )
            } else if let fb = feedback {
                let mins = Int(fb.durationInSeconds) / 60
                let secs = Int(fb.durationInSeconds) % 60
                cell.configure(
                    speechValue: String(format: "%d:%02d", mins, secs),
                    speechProgress: min(Float(fb.durationInSeconds) / 120.0, 1.0),
                    fillerValue: "\(fb.fillerWordCount ?? 0) fillers",
                    fillerProgress: min(Float(fb.fillerWordCount ?? 0) / 10.0, 1.0),
                    wpmValue: "\(Int(fb.wordsPerMinute)) WPM",
                    wpmProgress: min(Float(fb.wordsPerMinute) / 150.0, 1.0),
                    pausesValue: fb.pauseCount != nil ? "\(fb.pauseCount!) pauses" : fb.comments,
                    pausesProgress: min(Float(fb.pauseCount ?? 2) / 10.0, 1.0)
                )
            } else {
                cell.configure(
                    speechValue: "--",
                    speechProgress: 0,
                    fillerValue: "--",
                    fillerProgress: 0,
                    wpmValue: "--",
                    wpmProgress: 0,
                    pausesValue: "No data",
                    pausesProgress: 0
                )
            }
            return cell

        case 2:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FeedbackMistakeCell",
                for: indexPath
            ) as! FeedbackMistakeCell

            if isLoadingFeedback {
                cell.configure(original: "Analyzing your speech...", correction: "", explanation: "Please wait while we review your performance.")
            } else if let mistakes = feedback?.mistakes, !mistakes.isEmpty, indexPath.item < mistakes.count {
                let mistake = mistakes[indexPath.item]
                cell.configure(original: mistake.original, correction: mistake.correction, explanation: mistake.explanation)
            } else if let summary = feedback?.aiFeedbackSummary, !summary.isEmpty {
                cell.configure(original: "✨ Great job!", correction: "No major mistakes found.", explanation: summary)
            } else {
                cell.configure(original: "✨ Nice work!", correction: "No mistakes detected.", explanation: feedback?.comments ?? "Keep practicing to improve!")
            }
            return cell
            
        case 3:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FeedbackTranscriptCell",
                for: indexPath
            ) as! FeedbackTranscriptCell

            if isLoadingFeedback {
                cell.configure(transcript: transcript ?? "Transcribing...")
            } else {
                let displayTranscript = feedback?.transcript ?? transcript ?? "No transcript available."
                cell.configure(transcript: displayTranscript)
            }

            return cell

        default:
            fatalError("Unexpected section index")
        }
    }
}

extension FeedbackCollectionViewController {

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, env in

            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(200)
                )
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(200)
                ),
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)

            if sectionIndex == 0 {
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 16, leading: 16, bottom: 4, trailing: 16
                )
                section.interGroupSpacing = 4
            } else {
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 4, leading: 16, bottom: 16, trailing: 16
                )
                section.interGroupSpacing = 12
            }

            return section
        }
    }
}

