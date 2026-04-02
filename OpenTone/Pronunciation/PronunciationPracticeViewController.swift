import UIKit

/// Full-screen pronunciation practice view controller.
/// Shows target phrase → records user → shows per-word scored results.
final class PronunciationPracticeViewController: UIViewController {

    // MARK: - Properties

    private let sessionController = PronunciationSessionController()
    private var collectionView: UICollectionView!
    private var currentPhrase: String = ""

    // Section model
    private enum Section: Int, CaseIterable {
        case phrase = 0
        case controls
        case score
        case wordResults
        case prosody
        case feedback
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(newPhraseTapped)
        )

        sessionController.delegate = self
        setupCollectionView()
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
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "WordCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ProsodyCell")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "FeedbackCell")
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
            case .wordResults: return Self.wordGridSection()
            case .prosody:     return Self.listSection()
            case .feedback:    return Self.listSection()
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
        sessionController.prepareSession(expectedText: currentPhrase)
        collectionView.reloadData()
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

        let stack = UIStackView(arrangedSubviews: [scoreLabel, descLabel, progress, transcriptLabel])
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

    private func configureFeedbackCell(_ cell: UICollectionViewCell, at index: Int) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.contentView.backgroundColor = AppColors.cardBackground
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.clipsToBounds = true

        guard let feedback = sessionController.lastFeedback,
              index < feedback.userFeedback.count else { return }

        let item = feedback.userFeedback[index]

        let icon: String
        switch item.level {
        case .info: icon = "ℹ️"
        case .suggestion: icon = "💡"
        case .warning: icon = "⚠️"
        case .critical: icon = "🔴"
        }

        let messageLabel = UILabel()
        messageLabel.text = "\(icon) \(item.message)"
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = AppColors.textPrimary
        messageLabel.numberOfLines = 0

        var arranged: [UIView] = [messageLabel]

        if let tip = item.actionTip {
            let tipLabel = UILabel()
            tipLabel.text = "→ \(tip)"
            tipLabel.font = .systemFont(ofSize: 13, weight: .medium)
            tipLabel.textColor = AppColors.primary
            tipLabel.numberOfLines = 0
            arranged.append(tipLabel)
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
        case .wordResults: return "Word Breakdown"
        case .prosody: return "Rhythm & Stress"
        case .feedback: return "Tips"
        }
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
        case .wordResults: return sessionController.lastResult?.wordScores.count ?? 0
        case .prosody: return hasResults ? 1 : 0
        case .feedback: return sessionController.lastFeedback?.userFeedback.count ?? 0
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
        guard let section = Section(rawValue: indexPath.section),
              section == .wordResults,
              let result = sessionController.lastResult,
              indexPath.item < result.wordScores.count else { return }

        let wordScore = result.wordScores[indexPath.item]
        showWordDetail(wordScore)
    }

    private func showWordDetail(_ wordScore: WordPronunciationScore) {
        let phoneLines = wordScore.phoneScores.map { ps -> String in
            let icon: String
            switch ps.category {
            case .correct: icon = "✅"
            case .weak: icon = "🟡"
            case .substituted: icon = "🔴"
            case .missing: icon = "⬜️"
            case .inserted: icon = "🔵"
            case .acceptableVariation: icon = "✅"
            }
            let note = ps.diagnosticNote ?? ps.category.rawValue
            return "\(icon) /\(ps.phone.phone.ipaSymbol)/ — \(Int(ps.score))  \(note)"
        }

        let message = phoneLines.joined(separator: "\n")
        let alert = UIAlertController(
            title: "'\(wordScore.word)' — \(Int(wordScore.score.rounded()))/100",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
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
