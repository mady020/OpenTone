import UIKit
import AVFoundation

/// Full-screen pronunciation practice view controller.
/// Shows target phrase → records user → shows per-word scored results.
final class PronunciationPracticeViewController: UIViewController {

    // MARK: - Properties

    private let sessionController = PronunciationSessionController()
    private let difficultWordsStore = DifficultWordsStore.shared
    private let progressStore = PronunciationPracticeProgressStore.shared
    private var collectionView: UICollectionView!
    private var currentPhrase: String = ""
    private var activeDrillRootPhrase: String?
    private var pendingDrillPhrases: [String] = []
    private var difficultWords: [DifficultWordEntry] = []
    private var progress = PronunciationPracticeProgress.empty
    private var lastProgressUpdate: PronunciationPracticeProgressStore.ProgressUpdate?
    private var lastFeedbackOutput: PronunciationFeedbackEngine.FeedbackOutput?
    private var showDetailedBreakdown = false
    private var latestRecognizedTranscript: String = ""
    private var recordingPlayer: AVAudioPlayer?
    private let phraseSynthesizer = AVSpeechSynthesizer()
    private var refreshPhraseItem: UIBarButtonItem!
    private var detailsToggleItem: UIBarButtonItem!

    // Section model
    private enum Section: Int, CaseIterable {
        case phrase = 0
        case controls
        case score
        case momentum
        case priorityIssues
        case wordResults
        case prosody
        case feedback
        case difficultWords
    }

    private var visibleSections: [Section] {
        if hasResults {
            var sections: [Section] = [.phrase, .controls, .score, .momentum, .priorityIssues, .feedback]
            if showDetailedBreakdown {
                sections.append(contentsOf: [.wordResults, .prosody])
            }
            sections.append(.difficultWords)
            return sections
        }
        return [.phrase, .controls, .difficultWords]
    }

    private func sectionForIndex(_ index: Int) -> Section? {
        guard visibleSections.indices.contains(index) else { return nil }
        return visibleSections[index]
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pronunciation Practice"
        view.backgroundColor = AppColors.screenBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissTapped)
        )

        refreshPhraseItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(newPhraseTapped)
        )
        detailsToggleItem = UIBarButtonItem(
            title: "Show Details",
            style: .plain,
            target: self,
            action: #selector(toggleDetailsTapped)
        )
        updateNavigationItems()

        sessionController.delegate = self
        setupCollectionView()
        refreshProgress()
        refreshDifficultWords()
        loadNewPhrase()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        phraseSynthesizer.stopSpeaking(at: .immediate)
        if isMovingFromParent || isBeingDismissed {
            stopRecordedAudioPlayback()
        }
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = AppColors.screenBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "PhraseCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ControlCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ScoreCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MomentumCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "IssueCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "WordCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ProsodyCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "FeedbackCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "DifficultWordCell")
        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "Header"
        )
        view.addSubview(collectionView)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self,
                  let section = self.sectionForIndex(sectionIndex) else {
                return Self.listSection()
            }
            switch section {
            case .phrase:      return Self.phraseSection()
            case .controls:    return Self.controlsSection()
            case .score:       return Self.scoreSection()
            case .momentum:    return Self.listSection()
            case .priorityIssues: return Self.listSection()
            case .wordResults: return Self.wordGridSection()
            case .prosody:     return Self.listSection()
            case .feedback:    return Self.listSection()
            case .difficultWords: return Self.listSection()
            }
        }
    }

    private static func phraseSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(120)
        ))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(120)
        ), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 16, leading: 16, bottom: 8, trailing: 16)
        return section
    }

    private static func controlsSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(180)
        ))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(180)
        ), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 8, leading: 16, bottom: 16, trailing: 16)
        return section
    }

    private static func scoreSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(80)
        ))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(80)
        ), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        section.boundarySupplementaryItems = [headerItem()]
        return section
    }

    private static func wordGridSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .estimated(100),
            heightDimension: .estimated(50)
        ))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(50)
        ), subitems: [item])
        group.interItemSpacing = .fixed(8)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        section.interGroupSpacing = 8
        section.boundarySupplementaryItems = [headerItem()]
        return section
    }

    private static func listSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(60)
        ))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(60)
        ), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 8, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 8
        section.boundarySupplementaryItems = [headerItem()]
        return section
    }

    private static func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        .init(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(36)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    // MARK: - Phrase Management

    private func loadNewPhrase() {
        currentPhrase = PronunciationSessionController.randomPhrase()
        activeDrillRootPhrase = nil
        pendingDrillPhrases.removeAll()
        lastFeedbackOutput = nil
        latestRecognizedTranscript = ""
        showDetailedBreakdown = false
        sessionController.prepareSession(expectedText: currentPhrase)
        updateNavigationItems()
        collectionView.reloadData()
    }

    private func refreshDifficultWords() {
        difficultWords = difficultWordsStore.all()
    }

    private func refreshProgress() {
        progress = progressStore.load()
    }

    // MARK: - Actions

    @objc private func dismissTapped() {
        phraseSynthesizer.stopSpeaking(at: .immediate)
        stopRecordedAudioPlayback()
        sessionController.cancelRecording()
        if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func newPhraseTapped() {
        stopRecordedAudioPlayback()
        phraseSynthesizer.stopSpeaking(at: .immediate)
        sessionController.reset()
        loadNewPhrase()
    }

    @objc private func toggleDetailsTapped() {
        guard hasResults else { return }
        showDetailedBreakdown.toggle()
        updateNavigationItems()
        collectionView.reloadData()
    }

    private func updateNavigationItems() {
        detailsToggleItem.title = showDetailedBreakdown ? "Hide Details" : "Show Details"
        detailsToggleItem.isEnabled = hasResults
        navigationItem.rightBarButtonItems = [refreshPhraseItem, detailsToggleItem]
    }

    @objc private func recordTapped() {
        stopRecordedAudioPlayback()
        switch sessionController.state {
        case .idle, .results, .error:
            sessionController.startRecording()
        case .recording:
            sessionController.stopRecordingAndAnalyze()
        case .analyzing:
            break
        }
        collectionView.reloadData()
    }

    @objc private func hearSentenceTapped() {
        hearPhrase(currentPhrase)
    }

    @objc private func playMyRecordingTapped() {
        guard sessionController.state != .recording,
              sessionController.state != .analyzing else {
            return
        }

        if let player = recordingPlayer, player.isPlaying {
            stopRecordedAudioPlayback()
            collectionView.reloadData()
            return
        }

        guard let url = AudioManager.shared.lastRecordingURL else {
            let alert = UIAlertController(
                title: "No Recording Yet",
                message: "Record once and you can replay your own audio here.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            recordingPlayer = player
            collectionView.reloadData()
        } catch {
            let alert = UIAlertController(
                title: "Playback Error",
                message: "Could not play your recording. Please record again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    private func stopRecordedAudioPlayback() {
        recordingPlayer?.stop()
        recordingPlayer = nil
    }

    private func startDrill(for phrase: String) {
        let cleaned = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        activeDrillRootPhrase = cleaned
        pendingDrillPhrases.removeAll()
        beginDrillPhrase(cleaned)
    }

    private func startFocusedDrillSeries(for phrase: String) {
        let cleaned = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        activeDrillRootPhrase = cleaned
        pendingDrillPhrases = focusedDrillPhrases(for: cleaned)
        advanceFocusedDrillIfNeeded()
    }

    private func focusedDrillPhrases(for phrase: String) -> [String] {
        [
            phrase,
            "I can say \(phrase) clearly.",
            "Today I practiced \(phrase) with confidence."
        ]
    }

    private func advanceFocusedDrillIfNeeded() {
        guard !pendingDrillPhrases.isEmpty else {
            activeDrillRootPhrase = nil
            return
        }

        let nextPhrase = pendingDrillPhrases.removeFirst()
        beginDrillPhrase(nextPhrase)
    }

    private func beginDrillPhrase(_ phrase: String) {
        currentPhrase = phrase
        lastFeedbackOutput = nil
        latestRecognizedTranscript = ""
        showDetailedBreakdown = false
        updateNavigationItems()

        sessionController.reset()
        sessionController.prepareSession(expectedText: phrase)
        collectionView.setContentOffset(.zero, animated: true)
        collectionView.reloadData()
    }

    // MARK: - Cell Configuration

    private func configurePhrase(_ cell: UICollectionViewCell) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 16
        cell.contentView.clipsToBounds = true

        let icon = UILabel()
        icon.text = "🎯"
        icon.font = .systemFont(ofSize: 28)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = currentPhrase
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let hint = UILabel()
        hint.text = "Round goal: say it once clearly"
        hint.font = .systemFont(ofSize: 13, weight: .medium)
        hint.textColor = .secondaryLabel
        hint.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [icon, label, hint])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -20)
        ])
    }

    private func configureControls(_ cell: UICollectionViewCell) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = .clear

        let recordButton = UIButton(type: .system)
        recordButton.translatesAutoresizingMaskIntoConstraints = false

        var recordConfig = UIButton.Configuration.filled()
        recordConfig.cornerStyle = .capsule

        switch sessionController.state {
        case .idle, .error, .results:
            recordConfig.title = "  Start Round"
            recordConfig.image = UIImage(systemName: "mic.fill")
            recordConfig.baseBackgroundColor = AppColors.primary
            recordConfig.baseForegroundColor = .white
            recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)

        case .recording:
            recordConfig.title = "  Finish Round"
            recordConfig.image = UIImage(systemName: "stop.fill")
            recordConfig.baseBackgroundColor = .systemRed
            recordConfig.baseForegroundColor = .white
            recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)

        case .analyzing:
            recordConfig.title = "  Scoring Your Round..."
            recordConfig.image = UIImage(systemName: "waveform")
            recordConfig.baseBackgroundColor = .systemGray3
            recordConfig.baseForegroundColor = .white
            recordButton.isEnabled = false
        }

        recordButton.configuration = recordConfig

        let hearButton = UIButton(type: .system)
        hearButton.translatesAutoresizingMaskIntoConstraints = false
        var hearConfig = UIButton.Configuration.tinted()
        hearConfig.title = "Hear Correct Sentence"
        hearConfig.image = UIImage(systemName: "speaker.wave.2.fill")
        hearConfig.baseBackgroundColor = AppColors.primary.withAlphaComponent(0.12)
        hearConfig.baseForegroundColor = AppColors.primary
        hearConfig.cornerStyle = .capsule
        hearButton.configuration = hearConfig
        hearButton.addTarget(self, action: #selector(hearSentenceTapped), for: .touchUpInside)

        let myRecordingButton = UIButton(type: .system)
        myRecordingButton.translatesAutoresizingMaskIntoConstraints = false
        var myRecordingConfig = UIButton.Configuration.tinted()
        let isPlaying = recordingPlayer?.isPlaying == true
        myRecordingConfig.title = isPlaying ? "Stop My Recording" : "Play My Recording"
        myRecordingConfig.image = UIImage(systemName: isPlaying ? "stop.fill" : "play.circle.fill")
        myRecordingConfig.baseBackgroundColor = AppColors.primary.withAlphaComponent(0.12)
        myRecordingConfig.baseForegroundColor = AppColors.primary
        myRecordingConfig.cornerStyle = .capsule
        myRecordingButton.configuration = myRecordingConfig
        myRecordingButton.isEnabled = AudioManager.shared.lastRecordingURL != nil
            && sessionController.state != .recording
            && sessionController.state != .analyzing
        myRecordingButton.addTarget(self, action: #selector(playMyRecordingTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [recordButton, hearButton, myRecordingButton])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),

            recordButton.heightAnchor.constraint(equalToConstant: 52),
            recordButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),

            hearButton.heightAnchor.constraint(equalToConstant: 40),
            hearButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),

            myRecordingButton.heightAnchor.constraint(equalToConstant: 40),
            myRecordingButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 220)
        ])
    }

    private func configureScoreCell(_ cell: UICollectionViewCell) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 14
        cell.contentView.clipsToBounds = true

        guard let result = sessionController.lastResult else { return }

        let score = Int(result.overallScore.rounded())
        let color = scoreColor(for: result.overallScore)

        let statusLabel = UILabel()
        statusLabel.text = progressStateTitle(for: result.overallScore)
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textColor = color
        statusLabel.textAlignment = .center

        let scoreLabel = UILabel()
        scoreLabel.text = "\(score)"
        scoreLabel.font = .systemFont(ofSize: 48, weight: .bold)
        scoreLabel.textColor = color
        scoreLabel.textAlignment = .center

        let descLabel = UILabel()
        descLabel.text = encouragementLine(for: result.overallScore)
        descLabel.font = .systemFont(ofSize: 15, weight: .medium)
        descLabel.textColor = AppColors.textPrimary
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .center

        let modelLabel = UILabel()
        let modelName = result.diagnostics.acousticModelUsed.lowercased()
        let isEstimateOnly = modelName.contains("estimate-only") || modelName.contains("placeholder") || modelName.contains("heuristic")
        modelLabel.text = isEstimateOnly ? "Estimate mode: focused word coaching only" : nil
        modelLabel.font = .systemFont(ofSize: 12, weight: .medium)
        modelLabel.textColor = .secondaryLabel
        modelLabel.numberOfLines = 0
        modelLabel.textAlignment = .center
        modelLabel.isHidden = modelLabel.text == nil

        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = result.overallScore / 100
        progress.progressTintColor = color
        progress.trackTintColor = AppColors.cardBackground

        let transcriptLabel = UILabel()
        let cleanedTranscript = latestRecognizedTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        transcriptLabel.text = cleanedTranscript.isEmpty
            ? "You said: (speech not detected clearly)"
            : "You said: \"\(cleanedTranscript)\""
        transcriptLabel.font = .systemFont(ofSize: 13)
        transcriptLabel.textColor = .tertiaryLabel
        transcriptLabel.numberOfLines = 2
        transcriptLabel.textAlignment = .center

        let arranged: [UIView] = [statusLabel, scoreLabel, descLabel, modelLabel, progress, transcriptLabel]

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -16),
            progress.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.6)
        ])
    }

    private func configureMomentumCell(_ cell: UICollectionViewCell) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.clipsToBounds = true

        let streakText = "🔥 Streak: \(progress.currentStreak)d"
        let xpText = "⭐ XP: \(progress.totalXP)"
        let badgeText = latestBadgeLine(from: progress)

        let topLabel = UILabel()
        topLabel.text = "\(streakText)   •   \(xpText)"
        topLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        topLabel.textColor = AppColors.textPrimary

        let midLabel = UILabel()
        if !pendingDrillPhrases.isEmpty {
            midLabel.text = "Drill chain active: \(pendingDrillPhrases.count + 1) rounds left. Keep going!"
        } else if let update = lastProgressUpdate {
            midLabel.text = "\(update.xpEarned) XP earned this try. Keep the streak going!"
        } else {
            midLabel.text = "Practice daily to build streak and unlock badges."
        }
        midLabel.font = .systemFont(ofSize: 13, weight: .medium)
        midLabel.textColor = .secondaryLabel
        midLabel.numberOfLines = 0

        let bottomLabel = UILabel()
        bottomLabel.text = badgeText
        bottomLabel.font = .systemFont(ofSize: 12)
        bottomLabel.textColor = AppColors.primary
        bottomLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [topLabel, midLabel, bottomLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
        ])
    }

    private func configurePriorityIssuesCell(_ cell: UICollectionViewCell) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.clipsToBounds = true

        guard let result = sessionController.lastResult else { return }
        let topIssues = importantIssueLines(from: result)

        let titleLabel = UILabel()
        titleLabel.text = "Top 1-2 Wins"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = AppColors.textPrimary

        let bodyLabel = UILabel()
        bodyLabel.text = topIssues.joined(separator: "\n")
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = AppColors.textPrimary
        bodyLabel.numberOfLines = 0

        let helper = UILabel()
        helper.text = "Fixing these first gives the biggest score jump."
        helper.font = .systemFont(ofSize: 12)
        helper.textColor = .secondaryLabel
        helper.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, helper])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
        ])
    }

    private func configureWordCell(_ cell: UICollectionViewCell, at index: Int) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        guard let result = sessionController.lastResult,
              index < result.wordScores.count else { return }

        let wordScore = result.wordScores[index]
        let color = scoreColor(for: wordScore.score)

        cell.contentView.backgroundColor = color.withAlphaComponent(0.15)
        cell.contentView.layer.cornerRadius = 10
        cell.contentView.layer.borderWidth = 1.5
        cell.contentView.layer.borderColor = color.withAlphaComponent(0.5).cgColor
        cell.contentView.clipsToBounds = true

        let wordLabel = UILabel()
        wordLabel.text = wordScore.word
        wordLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        wordLabel.textColor = AppColors.textPrimary
        wordLabel.textAlignment = .center

        let scoreLabel = UILabel()
        scoreLabel.text = "\(Int(wordScore.score.rounded()))"
        scoreLabel.font = .systemFont(ofSize: 11, weight: .bold)
        scoreLabel.textColor = color
        scoreLabel.textAlignment = .center

        let hintLabel = UILabel()
        hintLabel.text = "Tap for quick practice"
        hintLabel.font = .systemFont(ofSize: 10, weight: .medium)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [wordLabel, scoreLabel, hintLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
        ])
    }

    private func configureProsodyCell(_ cell: UICollectionViewCell) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 14
        cell.contentView.clipsToBounds = true

        guard let result = sessionController.lastResult else { return }

        let prosody = result.prosody
        let scoreText = "Speech flow: \(Int(prosody.overallScore.rounded()))/100"
        let coaching: String
        if prosody.overallScore >= 80 {
            coaching = "Nice rhythm and pacing."
        } else if prosody.overallScore >= 65 {
            coaching = "Almost there. Keep a steady pace and clear stress."
        } else {
            coaching = "Try slower pacing with stronger word beats."
        }
        let confText = prosody.confidence == .low ? " (quick estimate)" : ""

        let label = UILabel()
        label.text = "\(scoreText)\(confText)\n\(coaching)"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -14),
            label.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
        ])
    }

    private func configureDifficultWordCell(_ cell: UICollectionViewCell, at index: Int) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.clipsToBounds = true

        if difficultWords.isEmpty {
            let label = UILabel()
            label.text = "No difficult words saved yet. Save one from a word card or from session feedback."
            label.font = .systemFont(ofSize: 14)
            label.textColor = .secondaryLabel
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
                label.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
                label.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
            ])
            return
        }

        guard index < difficultWords.count else { return }
        let entry = difficultWords[index]

        let title = UILabel()
        title.text = entry.phrase
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = AppColors.textPrimary
        title.numberOfLines = 0

        let reason = UILabel()
        reason.text = entry.plainReason
        reason.font = .systemFont(ofSize: 13)
        reason.textColor = .secondaryLabel
        reason.numberOfLines = 0

        let progress = UILabel()
        progress.font = .systemFont(ofSize: 12, weight: .medium)
        progress.textColor = AppColors.primary
        progress.text = progressLine(for: entry)
        progress.numberOfLines = 0

        let status = UILabel()
        status.font = .systemFont(ofSize: 12, weight: .regular)
        status.textColor = .secondaryLabel
        if let delta = entry.trendDelta {
            status.text = delta >= 0 ? "Nice momentum. Keep the same rhythm next drill." : "No stress. Slow down and focus on one clean repeat."
        } else {
            status.text = "Start with a 3-step drill to build consistency."
        }
        status.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [title, reason, progress, status])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
        ])
    }

    private func configureFeedbackCell(_ cell: UICollectionViewCell, at index: Int) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.clipsToBounds = true

        guard index == 0,
              let result = sessionController.lastResult else { return }
          let focusWords = prioritizedFocusWords(from: result)
          let coachingLines = topCoachingLines()

        let titleLabel = UILabel()
        titleLabel.text = "Focus Card"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = AppColors.textPrimary

        let messageLabel = UILabel()
        if focusWords.isEmpty {
            messageLabel.text = "Nice job. No major blockers right now. Keep this pace."
        } else {
            let lines: [String]
            if !coachingLines.isEmpty {
                lines = coachingLines.enumerated().map { idx, line in
                    "\(idx + 1). \(line)"
                }
            } else {
                lines = focusWords.enumerated().map { idx, word in
                    "\(idx + 1). \(plainIssue(for: word))"
                }
            }
            messageLabel.text = lines.joined(separator: "\n")
        }
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = AppColors.textPrimary
        messageLabel.numberOfLines = 0

        let microcopy = UILabel()
        microcopy.text = "One focused repeat now gives your biggest score jump."
        microcopy.font = .systemFont(ofSize: 12, weight: .medium)
        microcopy.textColor = .secondaryLabel
        microcopy.numberOfLines = 0

        let actions = UIStackView()
        actions.axis = .vertical
        actions.spacing = 8
        actions.alignment = .leading
        actions.translatesAutoresizingMaskIntoConstraints = false

        if let primary = focusWords.first {
            let practiceButton = UIButton(type: .system)
            var practiceConfig = UIButton.Configuration.filled()
            practiceConfig.title = "Practice \(primary.word)"
            practiceConfig.cornerStyle = .capsule
            practiceConfig.baseBackgroundColor = AppColors.primary
            practiceConfig.baseForegroundColor = .white
            practiceButton.configuration = practiceConfig
            practiceButton.addTarget(self, action: #selector(practicePrimaryFocusTapped), for: .touchUpInside)
            actions.addArrangedSubview(practiceButton)

            let saveButton = UIButton(type: .system)
            var saveConfig = UIButton.Configuration.tinted()
            saveConfig.title = "Save \(primary.word)"
            saveConfig.cornerStyle = .capsule
            saveConfig.baseBackgroundColor = AppColors.primary.withAlphaComponent(0.12)
            saveConfig.baseForegroundColor = AppColors.primary
            saveButton.configuration = saveConfig
            saveButton.addTarget(self, action: #selector(savePrimaryFocusTapped), for: .touchUpInside)
            actions.addArrangedSubview(saveButton)
        }

        let replayButton = UIButton(type: .system)
        var replayConfig = UIButton.Configuration.tinted()
        replayConfig.title = "Replay Sentence"
        replayConfig.cornerStyle = .capsule
        replayConfig.baseBackgroundColor = AppColors.primary.withAlphaComponent(0.12)
        replayConfig.baseForegroundColor = AppColors.primary
        replayButton.configuration = replayConfig
        replayButton.addTarget(self, action: #selector(replaySentenceFromFocusTapped), for: .touchUpInside)
        actions.addArrangedSubview(replayButton)

        if !focusWords.isEmpty {
            let wordsLabel = UILabel()
            wordsLabel.text = "Tap word for quick actions"
            wordsLabel.font = .systemFont(ofSize: 12, weight: .medium)
            wordsLabel.textColor = .secondaryLabel
            actions.addArrangedSubview(wordsLabel)

            let chips = UIStackView()
            chips.axis = .horizontal
            chips.spacing = 6
            chips.alignment = .center
            chips.distribution = .fillProportionally

            for (idx, word) in focusWords.enumerated() {
                let chip = UIButton(type: .system)
                var chipConfig = UIButton.Configuration.tinted()
                chipConfig.title = word.word
                chipConfig.cornerStyle = .capsule
                chipConfig.baseBackgroundColor = scoreColor(for: word.score).withAlphaComponent(0.15)
                chipConfig.baseForegroundColor = AppColors.textPrimary
                chip.configuration = chipConfig
                chip.tag = idx
                chip.addTarget(self, action: #selector(focusWordChipTapped(_:)), for: .touchUpInside)
                chips.addArrangedSubview(chip)
            }

            actions.addArrangedSubview(chips)
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel, microcopy, actions])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10)
        ])
    }

    // MARK: - Helpers

    private func scoreColor(for score: Float) -> UIColor {
        switch score {
        case 80...: return .systemGreen
        case 60..<80: return .systemYellow
        case 40..<60: return .systemOrange
        default: return .systemRed
        }
    }

    private func sectionTitle(for section: Section) -> String? {
        switch section {
        case .phrase, .controls: return nil
        case .score: return "Score"
        case .momentum: return "Momentum"
        case .priorityIssues: return "Biggest Improvement"
        case .wordResults: return "Word Breakdown"
        case .prosody: return "Flow"
        case .feedback: return "Focus"
        case .difficultWords: return "Difficult Words Bucket"
        }
    }

    private func importantIssueLines(from result: PronunciationAssessmentResult) -> [String] {
        let coachingLines = topCoachingLines()
        if !coachingLines.isEmpty {
            return coachingLines.enumerated().map { index, line in
                "\(index + 1). \(line)"
            }
        }

        let top = prioritizedFocusWords(from: result)

        if top.isEmpty {
            return ["1. Nice job. No major pronunciation blockers right now."]
        }

        return top.enumerated().map { index, wordScore in
            "\(index + 1). \(plainIssue(for: wordScore))"
        }
    }

    private func prioritizedFocusWords(from result: PronunciationAssessmentResult) -> [WordPronunciationScore] {
        let fallback = result.wordScores
            .filter { $0.hasIssue }
            .sorted { $0.score < $1.score }
        var selected: [WordPronunciationScore] = []

        if let feedback = lastFeedbackOutput {
            for item in feedback.userFeedback {
                guard let feedbackWord = item.word?.lowercased() else { continue }
                guard let match = result.wordScores.first(where: { $0.word.lowercased() == feedbackWord }) else { continue }
                if selected.contains(where: { $0.word.caseInsensitiveCompare(match.word) == .orderedSame }) {
                    continue
                }
                selected.append(match)
                if selected.count >= 2 { break }
            }
        }

        if selected.count < 2 {
            for item in fallback {
                if selected.contains(where: { $0.word.caseInsensitiveCompare(item.word) == .orderedSame }) {
                    continue
                }
                selected.append(item)
                if selected.count >= 2 { break }
            }
        }

        return selected
    }

    private func topCoachingLines() -> [String] {
        guard let feedback = lastFeedbackOutput else { return [] }
        var seen: Set<String> = []
        var lines: [String] = []

        for item in feedback.userFeedback {
            let base = item.actionTip ?? item.message
            let cleaned = plainEnglish(base)
            let key = cleaned.lowercased()
            if cleaned.isEmpty || seen.contains(key) {
                continue
            }
            seen.insert(key)
            lines.append(cleaned)
            if lines.count >= 2 { break }
        }

        return lines
    }

    private func plainIssue(for wordScore: WordPronunciationScore) -> String {
        let substituted = wordScore.phoneScores.filter { $0.category == .substituted }.count
        let missing = wordScore.phoneScores.filter { $0.category == .missing }.count
        let weak = wordScore.phoneScores.filter { $0.category == .weak }.count

        if substituted > 0 {
            return "\"\(wordScore.word)\" had one sound swap. Slow it down once, then say it naturally."
        }
        if missing > 0 {
            return "\"\(wordScore.word)\" dropped a sound. Say every part clearly once."
        }
        if weak > 0 {
            return "\"\(wordScore.word)\" sounded soft. Hold the key vowel a little longer."
        }
        if let issue = wordScore.primaryIssue,
           !issue.isEmpty {
            return "\"\(wordScore.word)\": \(plainEnglish(issue))"
        }
        return "\"\(wordScore.word)\" needs one more clean repeat."
    }

    private func plainEnglish(_ text: String) -> String {
        var simplified = text
        simplified = simplified.replacingOccurrences(of: "/[^/]+/", with: "", options: .regularExpression)
        simplified = simplified.replacingOccurrences(of: "came through as", with: "sounded like")
        simplified = simplified.replacingOccurrences(of: "Substitution", with: "Sound swap")
        simplified = simplified.replacingOccurrences(of: "Primary stress", with: "Main beat")
        simplified = simplified.replacingOccurrences(of: "prosody", with: "speech flow")
        simplified = simplified.replacingOccurrences(of: "phoneme", with: "sound")
        simplified = simplified.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        simplified = simplified.replacingOccurrences(of: "sound sound", with: "sound")
        simplified = simplified.replacingOccurrences(of: "sound sounded", with: "sounded")
        simplified = simplified.trimmingCharacters(in: .whitespacesAndNewlines)
        if simplified.isEmpty { return "Focus on one sound at a time." }
        return simplified
    }

    private func currentFocusWords() -> [WordPronunciationScore] {
        guard let result = sessionController.lastResult else { return [] }
        return prioritizedFocusWords(from: result)
    }

    @objc private func practicePrimaryFocusTapped() {
        if let primary = currentFocusWords().first {
            startDrill(for: primary.word)
        } else {
            startDrill(for: currentPhrase)
        }
    }

    @objc private func savePrimaryFocusTapped() {
        guard let primary = currentFocusWords().first else { return }
        saveWordToBucket(primary)
    }

    @objc private func replaySentenceFromFocusTapped() {
        hearPhrase(currentPhrase)
    }

    @objc private func focusWordChipTapped(_ sender: UIButton) {
        let words = currentFocusWords()
        guard sender.tag >= 0, sender.tag < words.count else { return }
        showWordDetail(words[sender.tag])
    }

    private func progressStateTitle(for score: Float) -> String {
        switch score {
        case 85...: return "Nice job"
        case 70..<85: return "Almost there"
        default: return "Focus on this one sound"
        }
    }

    private func encouragementLine(for score: Float) -> String {
        switch score {
        case 85...:
            return "Great clarity. Keep this smooth pace."
        case 70..<85:
            return "You are close. Clean up one word and you jump up."
        case 55..<70:
            return "You are improving. Fix one top word first."
        default:
            return "You can do this. One clean word at a time."
        }
    }

    private func latestBadgeLine(from progress: PronunciationPracticeProgress) -> String {
        guard let latest = progress.unlockedBadges.last else {
            return "🏅 Badge: Keep practicing to unlock your first badge."
        }
        return "🏅 Badge unlocked: \(latest.icon) \(latest.title)"
    }

    private func exampleLine(for word: String) -> String {
        "Try this: 'I can say \(word) clearly.'"
    }

    private func showBadgeCelebration(_ badges: [PracticeBadge]) {
        guard !badges.isEmpty else { return }
        let message = badges
            .map { "\($0.icon) \($0.title)" }
            .joined(separator: "\n")

        let alert = UIAlertController(
            title: "Badge Unlocked!",
            message: "\(message)\n\nNice work. Keep your streak alive!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Awesome", style: .default))
        present(alert, animated: true)
    }

    private func progressLine(for entry: DifficultWordEntry) -> String {
        let attempts = "Attempts: \(entry.attempts)"
        let last = entry.lastScore.map { "Last: \(Int($0.rounded()))" } ?? "Last: -"
        let best = entry.bestScore.map { "Best: \(Int($0.rounded()))" } ?? "Best: -"
        let wins = "Wins: \(entry.improvements)"
        let trend: String
        if let delta = entry.trendDelta {
            trend = delta >= 0 ? "Trend: +\(Int(delta.rounded()))" : "Trend: \(Int(delta.rounded()))"
        } else {
            trend = "Trend: -"
        }
        return "\(attempts) • \(last) • \(best) • \(wins) • \(trend)"
    }

    private func saveWordToBucket(_ wordScore: WordPronunciationScore) {
        let technical = technicalDetailText(for: wordScore)
        let personalizedReason = lastFeedbackOutput?.userFeedback.first(where: {
            $0.word?.caseInsensitiveCompare(wordScore.word) == .orderedSame
        })?.actionTip

        difficultWordsStore.saveOrUpdate(
            phrase: wordScore.word,
            plainReason: personalizedReason ?? plainIssue(for: wordScore),
            technicalHint: technical,
            source: "pronunciation_practice"
        )
        refreshDifficultWords()
        collectionView.reloadData()
    }

    private func technicalDetailText(for wordScore: WordPronunciationScore) -> String {
        let phoneLines = wordScore.phoneScores.map { ps -> String in
            let note = ps.diagnosticNote ?? ps.category.rawValue
            return "/\(ps.phone.phone.ipaSymbol)/ • \(Int(ps.score.rounded())) • \(note)"
        }
        return phoneLines.joined(separator: "\n")
    }

    private func hearPhrase(_ phrase: String) {
        let cleaned = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        phraseSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.05
        phraseSynthesizer.speak(utterance)
    }

    private func recordDrillProgressIfNeeded(result: PronunciationAssessmentResult) {
        guard let drillRoot = activeDrillRootPhrase else { return }

        let matchingWordScore = result.wordScores.first {
            $0.word.compare(drillRoot, options: .caseInsensitive) == .orderedSame
        }
        let score = matchingWordScore?.score ?? result.overallScore
        let issueSummary = topCoachingLines().first ?? matchingWordScore.map(plainIssue(for:))

        difficultWordsStore.recordPractice(
            phrase: drillRoot,
            score: score,
            issueSummary: issueSummary
        )

        refreshDifficultWords()

        if pendingDrillPhrases.isEmpty {
            activeDrillRootPhrase = nil
        } else {
            promptForNextDrillStep()
        }
    }

    private func promptForNextDrillStep() {
        guard !pendingDrillPhrases.isEmpty else { return }

        let alert = UIAlertController(
            title: "Next Drill Ready",
            message: "Great effort. Continue your focused drill chain?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.advanceFocusedDrillIfNeeded()
        })
        alert.addAction(UIAlertAction(title: "Later", style: .cancel))
        present(alert, animated: true)
    }

    private var hasResults: Bool {
        sessionController.state == .results && sessionController.lastResult != nil
    }
}

// MARK: - UICollectionViewDataSource

extension PronunciationPracticeViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        visibleSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sec = sectionForIndex(section) else { return 0 }
        switch sec {
        case .phrase: return 1
        case .controls: return 1
        case .score: return hasResults ? 1 : 0
        case .momentum: return hasResults ? 1 : 0
        case .priorityIssues: return hasResults ? 1 : 0
        case .wordResults: return sessionController.lastResult?.wordScores.count ?? 0
        case .prosody: return hasResults ? 1 : 0
        case .feedback: return hasResults ? 1 : 0
        case .difficultWords: return max(1, difficultWords.count)
        }
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = sectionForIndex(indexPath.section) else {
            return cv.dequeueReusableCell(withReuseIdentifier: "PhraseCell", for: indexPath)
        }

        switch section {
        case .phrase:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "PhraseCell", for: indexPath)
            configurePhrase(cell)
            return cell
        case .controls:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "ControlCell", for: indexPath)
            configureControls(cell)
            return cell
        case .score:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "ScoreCell", for: indexPath)
            configureScoreCell(cell)
            return cell
        case .momentum:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "MomentumCell", for: indexPath)
            configureMomentumCell(cell)
            return cell
        case .priorityIssues:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "IssueCell", for: indexPath)
            configurePriorityIssuesCell(cell)
            return cell
        case .wordResults:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "WordCell", for: indexPath)
            configureWordCell(cell, at: indexPath.item)
            return cell
        case .prosody:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "ProsodyCell", for: indexPath)
            configureProsodyCell(cell)
            return cell
        case .feedback:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "FeedbackCell", for: indexPath)
            configureFeedbackCell(cell, at: indexPath.item)
            return cell
        case .difficultWords:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "DifficultWordCell", for: indexPath)
            configureDifficultWordCell(cell, at: indexPath.item)
            return cell
        }
    }

    func collectionView(_ cv: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = cv.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "Header",
            for: indexPath
        )
        header.subviews.forEach { $0.removeFromSuperview() }

        if let section = sectionForIndex(indexPath.section),
           let title = sectionTitle(for: section) {
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 17, weight: .bold)
            label.textColor = AppColors.textPrimary
            label.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: header.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: header.centerYAnchor)
            ])
        }

        return header
    }
}

// MARK: - UICollectionViewDelegate

extension PronunciationPracticeViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = sectionForIndex(indexPath.section) else { return }

        switch section {
        case .wordResults:
            guard let result = sessionController.lastResult,
                  indexPath.item < result.wordScores.count else { return }
            showWordDetail(result.wordScores[indexPath.item])
        case .difficultWords:
            guard !difficultWords.isEmpty,
                  indexPath.item < difficultWords.count else { return }
            showDifficultWordActions(difficultWords[indexPath.item], sourceView: collectionView.cellForItem(at: indexPath))
        default:
            break
        }
    }

    private func showWordDetail(_ wordScore: WordPronunciationScore) {
        let summary = "\(plainIssue(for: wordScore))\n\nExample: \(exampleLine(for: wordScore.word))"
        let alert = UIAlertController(
            title: "\(wordScore.word) • \(Int(wordScore.score.rounded()))/100",
            message: summary,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Replay Word", style: .default) { [weak self] _ in
            self?.hearPhrase(wordScore.word)
        })
        alert.addAction(UIAlertAction(title: "Practice Now", style: .default) { [weak self] _ in
            self?.startDrill(for: wordScore.word)
        })
        alert.addAction(UIAlertAction(title: "Save to Difficult Words", style: .default) { [weak self] _ in
            self?.saveWordToBucket(wordScore)
        })
        if showDetailedBreakdown {
            let detail = technicalDetailText(for: wordScore)
            if !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                alert.addAction(UIAlertAction(title: "Show Details", style: .default) { [weak self] _ in
                    self?.presentTechnicalDetail(title: wordScore.word, detail: detail)
                })
            }
        }
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))

        present(alert, animated: true)
    }

    private func showDifficultWordActions(_ entry: DifficultWordEntry, sourceView: UIView?) {
        let alert = UIAlertController(
            title: entry.phrase,
            message: "\(entry.plainReason)\n\n\(progressLine(for: entry))",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "Hear Correct Pronunciation", style: .default) { [weak self] _ in
            self?.hearPhrase(entry.phrase)
        })
        alert.addAction(UIAlertAction(title: "Start 3-Step Drill", style: .default) { [weak self] _ in
            self?.startFocusedDrillSeries(for: entry.phrase)
        })
        if let technical = entry.technicalHint,
           !technical.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alert.addAction(UIAlertAction(title: "Show Details", style: .default) { [weak self] _ in
                self?.presentTechnicalDetail(title: entry.phrase, detail: technical)
            })
        }
        alert.addAction(UIAlertAction(title: "Practice Single Word", style: .default) { [weak self] _ in
            self?.startDrill(for: entry.phrase)
        })
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.difficultWordsStore.remove(id: entry.id)
            self?.refreshDifficultWords()
            self?.collectionView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController,
           let sourceView {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        present(alert, animated: true)
    }

    private func presentTechnicalDetail(title: String, detail: String) {
        let alert = UIAlertController(
            title: "\(title) Details",
            message: detail,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - PronunciationSessionController.Delegate

extension PronunciationPracticeViewController: PronunciationSessionController.Delegate {

    func sessionStateDidChange(_ state: PronunciationSessionController.SessionState) {
        updateNavigationItems()
        collectionView.reloadData()
    }

    func sessionDidReceiveTranscript(_ transcript: String, isFinal: Bool) {
        latestRecognizedTranscript = transcript
        if isFinal {
            collectionView.reloadData()
        }
    }

    func sessionDidCompleteAssessment(
        _ result: PronunciationAssessmentResult,
        feedback: PronunciationFeedbackEngine.FeedbackOutput
    ) {
        lastFeedbackOutput = feedback
        latestRecognizedTranscript = result.transcribedText
        recordDrillProgressIfNeeded(result: result)
        let update = progressStore.recordPractice(
            overallScore: result.overallScore,
            difficultWordsCount: prioritizedFocusWords(from: result).count
        )
        progress = update.progress
        lastProgressUpdate = update
        showBadgeCelebration(update.newlyUnlockedBadges)
        refreshDifficultWords()
        updateNavigationItems()
        collectionView.reloadData()
    }

    func sessionDidFail(_ error: Error) {
        let title: String
        if let pError = error as? PronunciationError {
            switch pError {
            case .noSpeechDetected:
                title = "We Could Not Hear You"
            case .offTargetSpeech:
                title = "Different Sentence Detected"
            case .microphoneAccessDenied:
                title = "Microphone Not Available"
            default:
                title = "Analysis Error"
            }
        } else {
            title = "Analysis Error"
        }

        let alert = UIAlertController(
            title: title,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AVAudioPlayerDelegate

extension PronunciationPracticeViewController: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if recordingPlayer === player {
            recordingPlayer = nil
            collectionView.reloadData()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if recordingPlayer === player {
            recordingPlayer = nil
            collectionView.reloadData()
        }
    }
}
