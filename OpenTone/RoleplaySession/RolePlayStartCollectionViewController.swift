import UIKit

class RolePlayStartCollectionViewController: UIViewController {

    // MARK: - Data
    var currentScenario: RoleplayScenario?
    var currentSession: RoleplaySession?

    // MARK: - UI Elements
    private let heroImageView = UIImageView()
    private let heroGradient = CAGradientLayer()
    private let heroTitleLabel = UILabel()
    private let chipStack = UIStackView()
    private let infoCard = UIView()
    private let startButton = UIButton(type: .system)

    // MARK: - Constants
    private let cardInset: CGFloat = 20
    private let cardCorner: CGFloat = 16

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        guard currentScenario != nil else {
            fatalError("RolePlayStartVC: Scenario missing")
        }
        hidesBottomBarWhenPushed = true
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = AppColors.screenBackground
        buildUI()
        populate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradient.frame = heroImageView.bounds
    }

    // MARK: - Build UI

    private func buildUI() {
        buildHeroImage()
        buildChips()
        buildStartButton()
        buildInfoCard()
    }

    // MARK: - Hero Image (pinned to top, fixed height)

    private func buildHeroImage() {
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heroImageView)

        // Gradient overlay
        heroGradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.65).cgColor
        ]
        heroGradient.locations = [0.35, 1.0]
        heroImageView.layer.addSublayer(heroGradient)

        // Title on the hero
        heroTitleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        heroTitleLabel.textColor = .white
        heroTitleLabel.numberOfLines = 2
        heroTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heroTitleLabel)

        // Hero starts below the Dynamic Island
        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.30),

            heroTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: cardInset),
            heroTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -cardInset),
            heroTitleLabel.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Chips

    private func buildChips() {
        chipStack.axis = .horizontal
        chipStack.spacing = 8
        chipStack.distribution = .fill
        chipStack.alignment = .center
        chipStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chipStack)

        NSLayoutConstraint.activate([
            chipStack.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 14),
            chipStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: cardInset),
            chipStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -cardInset),
        ])
    }

    private func makeChip(icon: String, text: String, tintColor: UIColor, bgColor: UIColor) -> UIView {
        let pill = UIView()
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.backgroundColor = bgColor
        pill.layer.cornerRadius = 13
        pill.clipsToBounds = true

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 4
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(hStack)

        let iconImage = UIImageView()
        iconImage.image = UIImage(systemName: icon)
        iconImage.tintColor = tintColor
        iconImage.contentMode = .scaleAspectFit
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconImage.widthAnchor.constraint(equalToConstant: 13).isActive = true
        iconImage.heightAnchor.constraint(equalToConstant: 13).isActive = true

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = tintColor

        hStack.addArrangedSubview(iconImage)
        hStack.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 5),
            hStack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -5),
            hStack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 9),
            hStack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -9),
        ])

        return pill
    }

    // MARK: - Info Card (About + Key Phrases combined)

    private func buildInfoCard() {
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        infoCard.backgroundColor = AppColors.cardBackground
        infoCard.layer.cornerRadius = cardCorner
        infoCard.layer.borderWidth = 1
        infoCard.layer.borderColor = AppColors.cardBorder.cgColor
        view.addSubview(infoCard)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(stack)

        // "About" section title + description
        let aboutTitle = makeSectionTitle("About")
        stack.addArrangedSubview(aboutTitle)

        let descLabel = UILabel()
        descLabel.tag = 100
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = AppColors.textSecondary
        descLabel.numberOfLines = 0
        stack.addArrangedSubview(descLabel)

        // Mode row (compact)
        let modeRow = UIStackView()
        modeRow.axis = .horizontal
        modeRow.spacing = 8
        modeRow.alignment = .center

        let modeIcon = UIImageView(image: UIImage(systemName: "text.bubble.fill"))
        modeIcon.tintColor = AppColors.primary
        modeIcon.contentMode = .scaleAspectFit
        modeIcon.translatesAutoresizingMaskIntoConstraints = false
        modeIcon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        modeIcon.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let modeLabel = UILabel()
        modeLabel.text = "Guided Script — choose a response and practice"
        modeLabel.font = .systemFont(ofSize: 13, weight: .medium)
        modeLabel.textColor = AppColors.textSecondary
        modeLabel.numberOfLines = 0

        modeRow.addArrangedSubview(modeIcon)
        modeRow.addArrangedSubview(modeLabel)
        stack.addArrangedSubview(modeRow)

        // Divider
        let divider = makeDivider()
        stack.addArrangedSubview(divider)
        stack.setCustomSpacing(10, after: modeRow)

        // "What You'll Practice" title
        let practiceTitle = makeSectionTitle("What You'll Practice")
        stack.addArrangedSubview(practiceTitle)

        // Phrase rows placeholder (tag 200 on the stack)
        stack.tag = 200

        NSLayoutConstraint.activate([
            infoCard.topAnchor.constraint(equalTo: chipStack.bottomAnchor, constant: 12),
            infoCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: cardInset),
            infoCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -cardInset),
            infoCard.bottomAnchor.constraint(lessThanOrEqualTo: startButton.topAnchor, constant: -16),

            stack.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -16),
        ])
    }

    // MARK: - Start Button (pinned to bottom)

    private func buildStartButton() {
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = AppColors.primary
        startButton.setTitle("  Start Roleplay", for: .normal)
        startButton.setTitleColor(AppColors.textOnPrimary, for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        startButton.layer.cornerRadius = 27
        startButton.clipsToBounds = false

        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)
        let playIcon = UIImage(systemName: "play.fill", withConfiguration: config)
        startButton.setImage(playIcon, for: .normal)
        startButton.tintColor = AppColors.textOnPrimary

        startButton.layer.shadowColor = AppColors.primary.cgColor
        startButton.layer.shadowOpacity = 0.3
        startButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        startButton.layer.shadowRadius = 12

        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: cardInset),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -cardInset),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            startButton.heightAnchor.constraint(equalToConstant: 54),
        ])
    }

    // MARK: - Populate

    private func populate() {
        guard let scenario = currentScenario else { return }

        heroImageView.image = UIImage(named: scenario.imageURL)
        heroTitleLabel.text = scenario.title
        title = nil

        // Chips
        let diffChip = makeDifficultyChip(scenario.difficulty)
        let timeChip = makeChip(
            icon: "clock.fill",
            text: "\(scenario.estimatedTimeMinutes) min",
            tintColor: .systemBlue,
            bgColor: UIColor.systemBlue.withAlphaComponent(0.12)
        )
        let catChip = makeCategoryChip(scenario.category)
        chipStack.addArrangedSubview(diffChip)
        chipStack.addArrangedSubview(timeChip)
        chipStack.addArrangedSubview(catChip)

        // Description
        if let descLabel = infoCard.viewWithTag(100) as? UILabel {
            descLabel.text = scenario.description
        }

        // Key phrases
        if let phraseStack = infoCard.viewWithTag(200) as? UIStackView {
            let firstMessage = scenario.script.first
            let phrases = firstMessage?.replyOptions ?? []
            for (index, phrase) in phrases.enumerated() {
                let row = makePhraseRow(number: index + 1, text: phrase)
                phraseStack.addArrangedSubview(row)
            }
        }
    }

    // MARK: - Helpers

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = AppColors.textPrimary
        return label
    }

    private func makeDivider() -> UIView {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = AppColors.cardBorder
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    private func makePhraseRow(number: Int, text: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center

        let badge = UILabel()
        badge.text = "\(number)"
        badge.font = .systemFont(ofSize: 11, weight: .bold)
        badge.textColor = AppColors.primary
        badge.textAlignment = .center
        badge.backgroundColor = AppColors.primaryLight
        badge.layer.cornerRadius = 11
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.widthAnchor.constraint(equalToConstant: 22).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let phraseLabel = UILabel()
        phraseLabel.text = text
        phraseLabel.font = .systemFont(ofSize: 14, weight: .regular)
        phraseLabel.textColor = AppColors.textPrimary
        phraseLabel.numberOfLines = 2

        row.addArrangedSubview(badge)
        row.addArrangedSubview(phraseLabel)
        return row
    }

    private func makeDifficultyChip(_ difficulty: RoleplayDifficulty) -> UIView {
        let color: UIColor
        let icon: String
        switch difficulty {
        case .beginner:
            color = .systemGreen
            icon = "leaf.fill"
        case .intermediate:
            color = .systemOrange
            icon = "flame.fill"
        case .advanced:
            color = .systemRed
            icon = "bolt.fill"
        }
        return makeChip(
            icon: icon,
            text: difficulty.rawValue.capitalized,
            tintColor: color,
            bgColor: color.withAlphaComponent(0.12)
        )
    }

    private func makeCategoryChip(_ category: RoleplayCategory) -> UIView {
        let icon: String
        let text: String
        switch category {
        case .groceryShopping:
            icon = "cart.fill"
            text = "Shopping"
        case .restaurant:
            icon = "fork.knife"
            text = "Dining"
        case .interview:
            icon = "briefcase.fill"
            text = "Interview"
        case .travel:
            icon = "airplane"
            text = "Travel"
        case .custom:
            icon = "star.fill"
            text = "Custom"
        }
        return makeChip(
            icon: icon,
            text: text,
            tintColor: AppColors.primary,
            bgColor: AppColors.primaryLight
        )
    }

    // MARK: - Actions

    @objc private func startTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        guard let scenario = currentScenario else { return }
        guard let session = RoleplaySessionDataModel.shared.startSession(
            scenarioId: scenario.id
        ) else { return }

        self.currentSession = session
        performSegue(withIdentifier: "toRoleplayChat", sender: self)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toRoleplayChat",
           let chatVC = segue.destination as? RoleplayChatViewController {
            guard let scenario = currentScenario,
                  let session = currentSession else {
                assertionFailure("Scenario or Session missing before segue")
                return
            }
            chatVC.scenario = scenario
            chatVC.session = session
        }
    }

    @IBAction func unwindToRoleplaysVC(_ segue: UIStoryboardSegue) {
    }
}
