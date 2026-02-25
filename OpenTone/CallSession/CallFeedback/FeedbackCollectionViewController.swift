import UIKit

class FeedbackCollectionViewController: UICollectionViewController {

    /// Optional feedback data — populated after backend analysis.
    var feedback: Feedback?

    /// Raw transcript passed from the speaking session (fallback only).
    var transcript: String?
    /// Supabase Storage URL of the recorded audio (primary input for /analyze).
    var audioURL: String?
    /// Topic the user was speaking about.
    var topic: String?
    /// Duration the user was speaking (seconds).
    var speakingDuration: Double = 30.0
    /// Session UUID (used to persist results to Supabase).
    var sessionId: String = ""
    /// User UUID.
    var userId: String = ""

    /// Whether we are currently loading feedback from the backend.
    private var isLoadingFeedback = false

    @IBOutlet weak var exitButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.screenBackground
        collectionView.backgroundColor = AppColors.screenBackground
        collectionView.collectionViewLayout = createLayout()

        // Replace the storyboard nav button with a proper xmark button
        setupExitButton()

        // If we have no pre-computed feedback, call the backend
        if feedback == nil {
            fetchBackendFeedback()
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

    // MARK: - Backend Speech Coaching

    private func fetchBackendFeedback() {
        isLoadingFeedback = true
        collectionView.reloadData()

        let capturedAudioURL  = audioURL ?? ""
        let capturedUserId    = userId
        let capturedSessionId = sessionId
        let capturedTranscript = transcript ?? ""
        let capturedDuration  = speakingDuration

        Task {
            do {
                guard !capturedAudioURL.isEmpty else {
                    throw BackendSpeechService.BackendError.noAudioURL
                }
                let response = try await BackendSpeechService.shared.analyze(
                    audioURL:  capturedAudioURL,
                    userId:    capturedUserId,
                    sessionId: capturedSessionId
                )
                self.feedback = BackendSpeechService.toFeedback(response)
            } catch {
                print("⚠️ Backend analysis failed: \(error.localizedDescription)")
                // Graceful fallback: local metrics from transcript
                let t = capturedTranscript
                self.feedback = buildLocalFeedback(transcript: t, duration: capturedDuration)
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
                    pausesValue: "Analysing…",
                    pausesProgress: 0
                )
            } else if let fb = feedback {
                // --- Coaching-aware labels (never show raw numbers) ---
                let fluency    = fb.coaching?.scores.fluency    ?? 50.0
                let confidence = fb.coaching?.scores.confidence ?? 50.0
                let clarity    = fb.coaching?.scores.clarity    ?? 50.0

                let fluencyLabel    = "Fluency \(Int(fluency))%"
                let confidenceLabel: String = {
                    let wpm = Int(fb.wordsPerMinute)
                    if wpm > 0 { return "\(wpm) WPM — " + (wpm >= 130 && wpm <= 150 ? "great pace" : wpm < 130 ? "pick up pace" : "slow down") }
                    return "Confidence \(Int(confidence))%"
                }()
                let clarityLabel: String = {
                    if let delta = fb.progress?.deltas.fillersDescription { return delta }
                    return "Clarity \(Int(clarity))%"
                }()
                let progressLabel = fb.progress?.weeklySummary ?? fb.comments

                cell.configure(
                    speechValue: fluencyLabel,
                    speechProgress: Float(fluency / 100.0),
                    fillerValue: clarityLabel,
                    fillerProgress: Float(clarity / 100.0),
                    wpmValue: confidenceLabel,
                    wpmProgress: Float(confidence / 100.0),
                    pausesValue: progressLabel,
                    pausesProgress: min(Float(fb.pauseCount ?? 0) / 10.0, 1.0)
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
                cell.configure(
                    original: "Analysing your speech…",
                    correction: "",
                    explanation: "Please wait while we review your performance."
                )
            } else if let mistakes = feedback?.mistakes, !mistakes.isEmpty, indexPath.item < mistakes.count {
                let m = mistakes[indexPath.item]
                // original = issue title, correction = suggestion, explanation = strength
                cell.configure(original: m.original, correction: m.correction, explanation: m.explanation)
            } else if let summary = feedback?.aiFeedbackSummary, !summary.isEmpty {
                cell.configure(original: "✨ Great session!", correction: "Keep going.", explanation: summary)
            } else {
                let strength = feedback?.coaching?.strengths.first ?? "Keep practising to improve!"
                cell.configure(original: "✨ Good effort!", correction: "No major issues detected.", explanation: strength)
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

