import UIKit

/// Full-screen pronunciation practice view controller.
/// Shows target phrase → records user → shows per-word scored results.
final class PronunciationPracticeViewController: UIViewController {

    // MARK: - Properties

    private let sessionController = PronunciationSessionController()
    private let difficultWordsStore = DifficultWordsStore.shared
    private var collectionView: UICollectionView!
    private var currentPhrase: String = ""
    private var showTechnicalDetails = false
    private var activeDrillPhrase: String?
    private var difficultWords: [DifficultWordEntry] = []

    // Section model
    private enum Section: Int, CaseIterable {
        case phrase = 0
        case controls
        case score
        case priorityIssues
        case wordResults
        case prosody
        case feedback
        case difficultWords
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

        let newPhraseItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(newPhraseTapped)
        )
        let detailsItem = UIBarButtonItem(
            title: "Show Details",
            style: .plain,
            target: self,
            action: #selector(toggleTechnicalDetailsTapped)
        )
        navigationItem.rightBarButtonItems = [newPhraseItem, detailsItem]

        sessionController.delegate = self
        setupCollectionView()
        refreshDifficultWords()
        loadNewPhrase()
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
            guard let section = Section(rawValue: sectionIndex) else {
                return Self.listSection()
            }
            switch section {
            case .phrase:      return Self.phraseSection()
            case .controls:    return Self.controlsSection()
            case .score:       return Self.scoreSection()
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
            heightDimension: .estimated(100)
        ))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(100)
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
        activeDrillPhrase = nil
        sessionController.prepareSession(expectedText: currentPhrase)
        collectionView.reloadData()
    }

    private func refreshDifficultWords() {
        difficultWords = difficultWordsStore.all()
    }

    // MARK: - Actions

    @objc private func dismissTapped() {
        sessionController.cancelRecording()
        if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func newPhraseTapped() {
        sessionController.reset()
        loadNewPhrase()
    }

    @objc private func toggleTechnicalDetailsTapped() {
        showTechnicalDetails.toggle()
        navigationItem.rightBarButtonItems?.last?.title = showTechnicalDetails ? "Hide Details" : "Show Details"
        collectionView.reloadData()
    }

    @objc private func recordTapped() {
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

    @objc private func retryTapped() {
        sessionController.reset()
        sessionController.prepareSession(expectedText: currentPhrase)
        collectionView.reloadData()
    }

    private func startDrill(for phrase: String) {
        let cleaned = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        activeDrillPhrase = cleaned
        currentPhrase = cleaned
        sessionController.reset()
        sessionController.prepareSession(expectedText: cleaned)
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
        hint.text = "Read this phrase aloud"
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

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule

        switch sessionController.state {
        case .idle, .error, .results:
            config.title = "  Start Recording"
            config.image = UIImage(systemName: "mic.fill")
            config.baseBackgroundColor = AppColors.primary
            config.baseForegroundColor = .white
            button.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)

        case .recording:
            config.title = "  Stop & Analyze"
            config.image = UIImage(systemName: "stop.fill")
            config.baseBackgroundColor = .systemRed
            config.baseForegroundColor = .white
            button.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)

        case .analyzing:
            config.title = "  Analyzing..."
            config.image = UIImage(systemName: "waveform")
            config.baseBackgroundColor = .systemGray3
            config.baseForegroundColor = .white
            button.isEnabled = false
        }

        button.configuration = config
        cell.contentView.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
            button.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            button.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
            button.heightAnchor.constraint(equalToConstant: 52),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])

        // Show retry button if we have results
        if sessionController.state == .results {
            let retry = UIButton(type: .system)
            retry.translatesAutoresizingMaskIntoConstraints = false
            var retryConfig = UIButton.Configuration.tinted()
            retryConfig.title = "Try Again"
            retryConfig.image = UIImage(systemName: "arrow.counterclockwise")
            retryConfig.baseBackgroundColor = AppColors.primary.withAlphaComponent(0.12)
            retryConfig.baseForegroundColor = AppColors.primary
            retryConfig.cornerStyle = .capsule
            retry.configuration = retryConfig
            retry.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
            cell.contentView.addSubview(retry)

            NSLayoutConstraint.activate([
                retry.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                retry.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 8),
                retry.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
    }

    private func configureScoreCell(_ cell: UICollectionViewCell) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 14
        cell.contentView.clipsToBounds = true

        guard let result = sessionController.lastResult else { return }

        let score = Int(result.overallScore.rounded())
        let color = scoreColor(for: result.overallScore)

        let scoreLabel = UILabel()
        scoreLabel.text = "\(score)"
        scoreLabel.font = .systemFont(ofSize: 48, weight: .bold)
        scoreLabel.textColor = color

        let descLabel = UILabel()
        descLabel.text = scoreDescriptor(result.overallScore)
        descLabel.font = .systemFont(ofSize: 15, weight: .medium)
        descLabel.textColor = .secondaryLabel

        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = result.overallScore / 100
        progress.progressTintColor = color
        progress.trackTintColor = AppColors.cardBackground

        let transcriptLabel = UILabel()
        transcriptLabel.text = "You said: \"\(result.transcribedText)\""
        transcriptLabel.font = .systemFont(ofSize: 13)
        transcriptLabel.textColor = .tertiaryLabel
        transcriptLabel.numberOfLines = 2

        var arranged: [UIView] = [scoreLabel, descLabel, progress, transcriptLabel]

        if showTechnicalDetails {
            let detail = UILabel()
            detail.font = .systemFont(ofSize: 12)
            detail.textColor = .secondaryLabel
            let model = result.diagnostics.acousticModelUsed
            if model.lowercased().contains("placeholder") {
                detail.text = "Details: fallback acoustic model in use (lower precision)."
            } else {
                detail.text = "Details: model \(model), \(result.diagnostics.processingTimeMs.rounded()) ms."
            }
            detail.numberOfLines = 0
            arranged.append(detail)
        }

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

    private func configurePriorityIssuesCell(_ cell: UICollectionViewCell) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.clipsToBounds = true

        guard let result = sessionController.lastResult else { return }
        let topIssues = importantIssueLines(from: result)

        let titleLabel = UILabel()
        titleLabel.text = "Top Focus Areas (1–3)"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = AppColors.textPrimary

        let bodyLabel = UILabel()
        bodyLabel.text = topIssues.joined(separator: "\n")
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = AppColors.textPrimary
        bodyLabel.numberOfLines = 0

        let helper = UILabel()
        helper.text = "Tap any word card below for examples and optional technical details."
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

        let stack = UIStackView(arrangedSubviews: [wordLabel, scoreLabel])
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
        let scoreText = "Prosody: \(Int(prosody.overallScore.rounded()))/100"
        let confText = prosody.confidence == .low ? " (tentative)" : ""

        let label = UILabel()
        label.text = "\(scoreText)\(confText)"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = AppColors.textPrimary
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

        let stack = UIStackView(arrangedSubviews: [title, reason, progress])
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

        let items = prioritizedFeedbackItems()
        guard index < items.count else { return }
        let item = items[index]

        let icon: String
        switch item.level {
        case .info: icon = "ℹ️"
        case .suggestion: icon = "💡"
        case .warning: icon = "⚠️"
        case .critical: icon = "🔴"
        }

        let messageLabel = UILabel()
        messageLabel.text = "\(icon) \(plainEnglish(item.message))"
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = AppColors.textPrimary
        messageLabel.numberOfLines = 0

        var arranged: [UIView] = [messageLabel]

        if let tip = item.actionTip {
            let tipLabel = UILabel()
            tipLabel.text = "→ \(plainEnglish(tip))"
            tipLabel.font = .systemFont(ofSize: 13, weight: .medium)
            tipLabel.textColor = AppColors.primary
            tipLabel.numberOfLines = 0
            arranged.append(tipLabel)
        }

        if showTechnicalDetails,
           let hint = item.phonemeHint,
           !hint.isEmpty {
            let detailLabel = UILabel()
            detailLabel.text = "Details: \(hint)"
            detailLabel.font = .systemFont(ofSize: 12)
            detailLabel.textColor = .secondaryLabel
            detailLabel.numberOfLines = 0
            arranged.append(detailLabel)
        }

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.spacing = 4
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

    private func scoreDescriptor(_ score: Float) -> String {
        switch score {
        case 85...: return "Excellent"
        case 70..<85: return "Good"
        case 55..<70: return "Needs Practice"
        default: return "Keep Trying"
        }
    }

    private func sectionTitle(for section: Section) -> String? {
        switch section {
        case .phrase, .controls: return nil
        case .score: return "Score"
        case .priorityIssues: return "Most Important Issues"
        case .wordResults: return "Word Breakdown"
        case .prosody: return "Rhythm & Stress"
        case .feedback: return "Actionable Tips"
        case .difficultWords: return "Difficult Words Bucket"
        }
    }

    private func importantIssueLines(from result: PronunciationAssessmentResult) -> [String] {
        let problematic = result.wordScores
            .filter { $0.hasIssue }
            .sorted { $0.score < $1.score }
        let top = Array(problematic.prefix(3))

        if top.isEmpty {
            return ["1. Nice work. Your main sounds were clear in this attempt."]
        }

        return top.enumerated().map { index, wordScore in
            "\(index + 1). \(plainIssue(for: wordScore))"
        }
    }

    private func plainIssue(for wordScore: WordPronunciationScore) -> String {
        let substituted = wordScore.phoneScores.filter { $0.category == .substituted }.count
        let missing = wordScore.phoneScores.filter { $0.category == .missing }.count
        let weak = wordScore.phoneScores.filter { $0.category == .weak }.count

        if substituted > 0 {
            return "In \"\(wordScore.word)\", one sound came out as a different sound. Try saying it slowly, then at normal speed."
        }
        if missing > 0 {
            return "In \"\(wordScore.word)\", one sound was dropped. Say each part clearly before speeding up."
        }
        if weak > 0 {
            return "In \"\(wordScore.word)\", a sound was soft or unclear. Hold the key vowel slightly longer."
        }
        if let issue = wordScore.primaryIssue,
           !issue.isEmpty {
            return "In \"\(wordScore.word)\": \(plainEnglish(issue))"
        }
        return "In \"\(wordScore.word)\", keep practicing for a cleaner sound."
    }

    private func plainEnglish(_ text: String) -> String {
        var simplified = text
        simplified = simplified.replacingOccurrences(of: "/[^/]+/", with: "sound", options: .regularExpression)
        simplified = simplified.replacingOccurrences(of: "came through as", with: "sounded like")
        simplified = simplified.replacingOccurrences(of: "Substitution", with: "Sound swap")
        simplified = simplified.replacingOccurrences(of: "Primary stress", with: "Main syllable stress")
        simplified = simplified.replacingOccurrences(of: "prosody", with: "rhythm")
        return simplified
    }

    private func prioritizedFeedbackItems() -> [PronunciationFeedbackEngine.UserFeedbackItem] {
        guard let feedback = sessionController.lastFeedback else { return [] }
        return Array(feedback.userFeedback.prefix(3))
    }

    private func progressLine(for entry: DifficultWordEntry) -> String {
        let attempts = "Attempts: \(entry.attempts)"
        let last = entry.lastScore.map { "Last: \(Int($0.rounded()))" } ?? "Last: -"
        let best = entry.bestScore.map { "Best: \(Int($0.rounded()))" } ?? "Best: -"
        let trend: String
        if let delta = entry.trendDelta {
            trend = delta >= 0 ? "Trend: +\(Int(delta.rounded()))" : "Trend: \(Int(delta.rounded()))"
        } else {
            trend = "Trend: -"
        }
        return "\(attempts) • \(last) • \(best) • \(trend)"
    }

    private func saveWordToBucket(_ wordScore: WordPronunciationScore) {
        let technical = technicalDetailText(for: wordScore)
        difficultWordsStore.saveOrUpdate(
            phrase: wordScore.word,
            plainReason: plainIssue(for: wordScore),
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
        Task {
            try? await OnDeviceTTSService.shared.speak(text: phrase, persona: .professional)
        }
    }

    private func recordDrillProgressIfNeeded(result: PronunciationAssessmentResult) {
        guard let activeDrillPhrase else { return }

        let matchingWordScore = result.wordScores.first {
            $0.word.compare(activeDrillPhrase, options: .caseInsensitive) == .orderedSame
        }
        let score = matchingWordScore?.score ?? result.overallScore
        let issueSummary = matchingWordScore.map(plainIssue(for:))

        difficultWordsStore.recordPractice(
            phrase: activeDrillPhrase,
            score: score,
            issueSummary: issueSummary
        )

        self.activeDrillPhrase = nil
        refreshDifficultWords()
    }

    private var hasResults: Bool {
        sessionController.state == .results && sessionController.lastResult != nil
    }
}

// MARK: - UICollectionViewDataSource

extension PronunciationPracticeViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        hasResults ? Section.allCases.count : 2  // phrase + controls only when no results
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .phrase: return 1
        case .controls: return 1
        case .score: return hasResults ? 1 : 0
        case .priorityIssues: return hasResults ? 1 : 0
        case .wordResults: return sessionController.lastResult?.wordScores.count ?? 0
        case .prosody: return hasResults ? 1 : 0
        case .feedback: return prioritizedFeedbackItems().count
        case .difficultWords: return hasResults ? max(1, difficultWords.count) : 0
        }
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
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

        if let section = Section(rawValue: indexPath.section),
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
        guard let section = Section(rawValue: indexPath.section) else { return }

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
        let summary = plainIssue(for: wordScore)
        let alert = UIAlertController(
            title: "\(wordScore.word) • \(Int(wordScore.score.rounded()))/100",
            message: summary,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Save to Difficult Words", style: .default) { [weak self] _ in
            self?.saveWordToBucket(wordScore)
        })
        alert.addAction(UIAlertAction(title: "Hear Correct Pronunciation", style: .default) { [weak self] _ in
            self?.hearPhrase(wordScore.word)
        })
        alert.addAction(UIAlertAction(title: "Practice This Word", style: .default) { [weak self] _ in
            self?.startDrill(for: wordScore.word)
        })
        alert.addAction(UIAlertAction(title: "Show Technical Details", style: .default) { [weak self] _ in
            self?.showTechnicalWordDetail(wordScore)
        })
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))

        present(alert, animated: true)
    }

    private func showTechnicalWordDetail(_ wordScore: WordPronunciationScore) {
        let alert = UIAlertController(
            title: "Technical Details • \(wordScore.word)",
            message: technicalDetailText(for: wordScore),
            preferredStyle: .alert
        )
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
        alert.addAction(UIAlertAction(title: "Practice Drill", style: .default) { [weak self] _ in
            self?.startDrill(for: entry.phrase)
        })
        if let technicalHint = entry.technicalHint,
           !technicalHint.isEmpty {
            alert.addAction(UIAlertAction(title: "Show Details", style: .default) { [weak self] _ in
                let detail = UIAlertController(title: "Technical Details", message: technicalHint, preferredStyle: .alert)
                detail.addAction(UIAlertAction(title: "Close", style: .cancel))
                self?.present(detail, animated: true)
            })
        }
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
}

// MARK: - PronunciationSessionController.Delegate

extension PronunciationPracticeViewController: PronunciationSessionController.Delegate {

    func sessionStateDidChange(_ state: PronunciationSessionController.SessionState) {
        collectionView.reloadData()
    }

    func sessionDidReceiveTranscript(_ transcript: String, isFinal: Bool) {
        // Could show live transcript in future
    }

    func sessionDidCompleteAssessment(
        _ result: PronunciationAssessmentResult,
        feedback: PronunciationFeedbackEngine.FeedbackOutput
    ) {
        recordDrillProgressIfNeeded(result: result)
        refreshDifficultWords()
        collectionView.reloadData()
    }

    func sessionDidFail(_ error: Error) {
        let alert = UIAlertController(
            title: "Analysis Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
