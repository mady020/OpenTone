import UIKit

class RolePlayStartCollectionViewController: UIViewController {

    // MARK: - Data
    var currentScenario: RoleplayScenario?
    var currentSession: RoleplaySession?

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroImageView = UIImageView()
    private let heroGradient = CAGradientLayer()
    private let heroTitleLabel = UILabel()
    private let chipStack = UIStackView()
    private let descriptionCard = UIView()
    private let practiceCard = UIView()
    private let startButton = UIButton(type: .system)

    // MARK: - Constants
    private let heroHeight: CGFloat = 260
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
        buildScrollView()
        buildHeroImage()
        buildChips()
        buildDescriptionCard()
        buildPracticeCard()
        buildStartButton()
    }

    // MARK: - Scroll View

    private func buildScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    // MARK: - Hero Image

    private func buildHeroImage() {
        let heroContainer = UIView()
        heroContainer.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.clipsToBounds = true

        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.addSubview(heroImageView)

        // Gradient overlay
        heroGradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        heroGradient.locations = [0.3, 1.0]
        heroImageView.layer.addSublayer(heroGradient)

        // Title on the hero
        heroTitleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        heroTitleLabel.textColor = .white
        heroTitleLabel.numberOfLines = 2
        heroTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.addSubview(heroTitleLabel)

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor),

            heroContainer.heightAnchor.constraint(equalToConstant: heroHeight),

            heroTitleLabel.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor, constant: cardInset),
            heroTitleLabel.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor, constant: -cardInset),
            heroTitleLabel.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor, constant: -20),
        ])

        contentStack.addArrangedSubview(heroContainer)
    }

    // MARK: - Chips

    private func buildChips() {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false

        chipStack.axis = .horizontal
        chipStack.spacing = 10
        chipStack.distribution = .fill
        chipStack.alignment = .center
        chipStack.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(chipStack)

        NSLayoutConstraint.activate([
            chipStack.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 18),
            chipStack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: cardInset),
            chipStack.trailingAnchor.constraint(lessThanOrEqualTo: wrapper.trailingAnchor, constant: -cardInset),
            chipStack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -6),
        ])

        contentStack.addArrangedSubview(wrapper)
    }

    private func makeChip(icon: String, text: String, tintColor: UIColor, bgColor: UIColor) -> UIView {
        let pill = UIView()
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.backgroundColor = bgColor
        pill.layer.cornerRadius = 14
        pill.clipsToBounds = true

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 5
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(hStack)

        let iconImage = UIImageView()
        iconImage.image = UIImage(systemName: icon)
        iconImage.tintColor = tintColor
        iconImage.contentMode = .scaleAspectFit
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconImage.widthAnchor.constraint(equalToConstant: 14).isActive = true
        iconImage.heightAnchor.constraint(equalToConstant: 14).isActive = true

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = tintColor

        hStack.addArrangedSubview(iconImage)
        hStack.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 6),
            hStack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -6),
            hStack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 10),
            hStack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -10),
        ])

        return pill
    }

    // MARK: - Description Card

    private func buildDescriptionCard() {
        let cardWrapper = UIView()
        cardWrapper.translatesAutoresizingMaskIntoConstraints = false

        descriptionCard.translatesAutoresizingMaskIntoConstraints = false
        descriptionCard.backgroundColor = AppColors.cardBackground
        descriptionCard.layer.cornerRadius = cardCorner
        descriptionCard.layer.borderWidth = 1
        descriptionCard.layer.borderColor = AppColors.cardBorder.cgColor
        cardWrapper.addSubview(descriptionCard)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        descriptionCard.addSubview(stack)

        // Section title
        let sectionTitle = makeSectionTitle("About")
        stack.addArrangedSubview(sectionTitle)

        // Description label
        let descLabel = UILabel()
        descLabel.tag = 100
        descLabel.font = .systemFont(ofSize: 16, weight: .regular)
        descLabel.textColor = AppColors.textSecondary
        descLabel.numberOfLines = 0
        stack.addArrangedSubview(descLabel)

        // Divider
        let divider = makeDivider()
        stack.addArrangedSubview(divider)
        stack.setCustomSpacing(14, after: descLabel)
        stack.setCustomSpacing(14, after: divider)

        // Mode row
        let modeRow = UIStackView()
        modeRow.axis = .horizontal
        modeRow.spacing = 10
        modeRow.alignment = .top
        modeRow.translatesAutoresizingMaskIntoConstraints = false

        let modeIcon = UIImageView(image: UIImage(systemName: "text.bubble.fill"))
        modeIcon.tintColor = AppColors.primary
        modeIcon.contentMode = .scaleAspectFit
        modeIcon.translatesAutoresizingMaskIntoConstraints = false
        modeIcon.widthAnchor.constraint(equalToConstant: 22).isActive = true
        modeIcon.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let modeVStack = UIStackView()
        modeVStack.axis = .vertical
        modeVStack.spacing = 2

        let modeLabel = UILabel()
        modeLabel.text = "Guided Script"
        modeLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        modeLabel.textColor = AppColors.textPrimary

        let modeSubLabel = UILabel()
        modeSubLabel.text = "Choose a response and practice speaking naturally"
        modeSubLabel.font = .systemFont(ofSize: 13, weight: .regular)
        modeSubLabel.textColor = AppColors.textSecondary
        modeSubLabel.numberOfLines = 0

        modeVStack.addArrangedSubview(modeLabel)
        modeVStack.addArrangedSubview(modeSubLabel)

        modeRow.addArrangedSubview(modeIcon)
        modeRow.addArrangedSubview(modeVStack)
        stack.addArrangedSubview(modeRow)

        NSLayoutConstraint.activate([
            descriptionCard.topAnchor.constraint(equalTo: cardWrapper.topAnchor, constant: 12),
            descriptionCard.leadingAnchor.constraint(equalTo: cardWrapper.leadingAnchor, constant: cardInset),
            descriptionCard.trailingAnchor.constraint(equalTo: cardWrapper.trailingAnchor, constant: -cardInset),
            descriptionCard.bottomAnchor.constraint(equalTo: cardWrapper.bottomAnchor),

            stack.topAnchor.constraint(equalTo: descriptionCard.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: descriptionCard.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: descriptionCard.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: descriptionCard.bottomAnchor, constant: -18),
        ])

        contentStack.addArrangedSubview(cardWrapper)
    }

    // MARK: - Practice Card

    private func buildPracticeCard() {
        let cardWrapper = UIView()
        cardWrapper.translatesAutoresizingMaskIntoConstraints = false

        practiceCard.translatesAutoresizingMaskIntoConstraints = false
        practiceCard.backgroundColor = AppColors.cardBackground
        practiceCard.layer.cornerRadius = cardCorner
        practiceCard.layer.borderWidth = 1
        practiceCard.layer.borderColor = AppColors.cardBorder.cgColor
        cardWrapper.addSubview(practiceCard)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        practiceCard.addSubview(stack)

        let sectionTitle = makeSectionTitle("What You'll Practice")
        stack.addArrangedSubview(sectionTitle)

        // Phrase rows will be added in populate()
        stack.tag = 200

        NSLayoutConstraint.activate([
            practiceCard.topAnchor.constraint(equalTo: cardWrapper.topAnchor, constant: 16),
            practiceCard.leadingAnchor.constraint(equalTo: cardWrapper.leadingAnchor, constant: cardInset),
            practiceCard.trailingAnchor.constraint(equalTo: cardWrapper.trailingAnchor, constant: -cardInset),
            practiceCard.bottomAnchor.constraint(equalTo: cardWrapper.bottomAnchor),

            stack.topAnchor.constraint(equalTo: practiceCard.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: practiceCard.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: practiceCard.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: practiceCard.bottomAnchor, constant: -18),
        ])

        contentStack.addArrangedSubview(cardWrapper)
    }

    // MARK: - Start Button (inline in scroll)

    private func buildStartButton() {
        let buttonWrapper = UIView()
        buttonWrapper.translatesAutoresizingMaskIntoConstraints = false

        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = AppColors.primary
        startButton.setTitle("  Start Roleplay", for: .normal)
        startButton.setTitleColor(AppColors.textOnPrimary, for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        startButton.layer.cornerRadius = 28
        startButton.clipsToBounds = false

        // Icon
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let playIcon = UIImage(systemName: "play.fill", withConfiguration: config)
        startButton.setImage(playIcon, for: .normal)
        startButton.tintColor = AppColors.textOnPrimary

        // Shadow
        startButton.layer.shadowColor = AppColors.primary.cgColor
        startButton.layer.shadowOpacity = 0.35
        startButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        startButton.layer.shadowRadius = 14

        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        buttonWrapper.addSubview(startButton)

        NSLayoutConstraint.activate([
            startButton.topAnchor.constraint(equalTo: buttonWrapper.topAnchor, constant: 24),
            startButton.leadingAnchor.constraint(equalTo: buttonWrapper.leadingAnchor, constant: cardInset),
            startButton.trailingAnchor.constraint(equalTo: buttonWrapper.trailingAnchor, constant: -cardInset),
            startButton.bottomAnchor.constraint(equalTo: buttonWrapper.bottomAnchor, constant: -32),
            startButton.heightAnchor.constraint(equalToConstant: 56),
        ])

        contentStack.addArrangedSubview(buttonWrapper)
    }

    // MARK: - Populate

    private func populate() {
        guard let scenario = currentScenario else { return }

        // Hero
        heroImageView.image = UIImage(named: scenario.imageURL)
        heroTitleLabel.text = scenario.title
        title = nil  // No nav bar title — title is on the hero

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
        if let descLabel = descriptionCard.viewWithTag(100) as? UILabel {
            descLabel.text = scenario.description
        }

        // Key phrases
        if let phraseStack = practiceCard.viewWithTag(200) as? UIStackView {
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
        label.font = .systemFont(ofSize: 18, weight: .bold)
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
        row.spacing = 12
        row.alignment = .top

        // Number badge
        let badge = UILabel()
        badge.text = "\(number)"
        badge.font = .systemFont(ofSize: 12, weight: .bold)
        badge.textColor = AppColors.primary
        badge.textAlignment = .center
        badge.backgroundColor = AppColors.primaryLight
        badge.layer.cornerRadius = 12
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.widthAnchor.constraint(equalToConstant: 24).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let phraseLabel = UILabel()
        phraseLabel.text = text
        phraseLabel.font = .systemFont(ofSize: 15, weight: .regular)
        phraseLabel.textColor = AppColors.textPrimary
        phraseLabel.numberOfLines = 0

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
