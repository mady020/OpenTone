//
//  DashboardViewController.swift
//  OpenTone
//
//  Created by M S on 03/12/25.
//


import UIKit

// MARK: - DashboardViewController

final class DashboardViewController: UIViewController {

    // MARK: Sections

    private enum Section: Int, CaseIterable {
        case hero
        case quickActions
        case recommended
        case scenarios
    }

    // MARK: Models

    struct QuickAction {
        let title: String
        let subtitle: String
        let systemImageName: String
    }

    struct ScenarioItem {
        let title: String
        let subtitle: String
        let imageName: String
    }

    // MARK: Data

    private let quickActions: [QuickAction] = [
        QuickAction(title: "Find a Peer",
                    subtitle: "1-to-1 practice call",
                    systemImageName: "person.2.fill"),
        QuickAction(title: "2-Min JAM",
                    subtitle: "Quick warm-up",
                    systemImageName: "timer"),
        QuickAction(title: "Random Roleplay",
                    subtitle: "Surprise scenario",
                    systemImageName: "sparkles")
    ]

    // In a real app these would come from your interests / backend.
    private let recommendedItems: [ScenarioItem] = [
        ScenarioItem(title: "Grocery Shopping",
                     subtitle: "Asking for items & prices",
                     imageName: "GroceryShopping"),
        ScenarioItem(title: "Making Friends",
                     subtitle: "Small talk & follow-ups",
                     imageName: "MakingFriends"),
        ScenarioItem(title: "Job Interview",
                     subtitle: "Answering common questions",
                     imageName: "JobInterview")
    ]

    private let allScenarios: [ScenarioItem] = [
        ScenarioItem(title: "Airport Check-in",
                     subtitle: "Check-in & boarding",
                     imageName: "AirportCheckin"),
        ScenarioItem(title: "Ordering Food",
                     subtitle: "Restaurant conversation",
                     imageName: "OrderingFood"),
        ScenarioItem(title: "Birthday Celebration",
                     subtitle: "Social small talk",
                     imageName: "BirthdayCelebration"),
        ScenarioItem(title: "Hotel Booking",
                     subtitle: "Reservations & questions",
                     imageName: "HotelBooking"),
        ScenarioItem(title: "First Date",
                     subtitle: "Confident introductions",
                     imageName: "FirstDate")
    ]

    // MARK: UI

    private var collectionView: UICollectionView!

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "OpenTone"
        view.backgroundColor = .systemBackground

        configureCollectionView()
    }

    // MARK: Setup

    private func configureCollectionView() {
        let layout = createLayout()

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true

        collectionView.dataSource = self
        collectionView.delegate   = self

        // Cells
        collectionView.register(HeroCardCell.self,
                                forCellWithReuseIdentifier: HeroCardCell.reuseIdentifier)
        collectionView.register(QuickActionCell.self,
                                forCellWithReuseIdentifier: QuickActionCell.reuseIdentifier)
        collectionView.register(ScenarioCardCell.self,
                                forCellWithReuseIdentifier: ScenarioCardCell.reuseIdentifier)

        // Headers
        collectionView.register(DashboardSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: DashboardSectionHeaderView.reuseIdentifier)

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Layout

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }

            switch section {
            case .hero:
                return Self.makeHeroSection()
            case .quickActions:
                return Self.makeQuickActionsSection()
            case .recommended:
                return Self.makeHorizontalScenarioSection()
            case .scenarios:
                return Self.makeHorizontalScenarioSection()
            }
        }
        return layout
    }

    private static func makeHeroSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(200)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
        return section
    }

    private static func makeQuickActionsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / 3.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item, item, item]
        )

        let section = NSCollectionLayoutSection(group: group)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(40)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        section.boundarySupplementaryItems = [header]
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
        return section
    }

    private static func makeHorizontalScenarioSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(220),
            heightDimension: .absolute(160)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 12)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(220),
            heightDimension: .absolute(160)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(40)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        section.boundarySupplementaryItems = [header]
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
        return section
    }
}

// MARK: - UICollectionViewDataSource

extension DashboardViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        switch sectionType {
        case .hero:
            return 1
        case .quickActions:
            return quickActions.count
        case .recommended:
            return recommendedItems.count
        case .scenarios:
            return allScenarios.count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }

        switch sectionType {
        case .hero:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HeroCardCell.reuseIdentifier,
                for: indexPath
            ) as! HeroCardCell
            cell.configure(
                title: "Keep building your communication skills",
                subtitle: "Practice a quick session today to stay sharp.",
                buttonTitle: "Start Practice"
            )
            cell.onPrimaryAction = { [weak self] in
                // Later: push your “best next action” screen.
                print("Hero card tapped - start practice")
                self?.startBestNextPractice()
            }
            return cell

        case .quickActions:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: QuickActionCell.reuseIdentifier,
                for: indexPath
            ) as! QuickActionCell
            let action = quickActions[indexPath.item]
            cell.configure(with: action)
            return cell

        case .recommended:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ScenarioCardCell.reuseIdentifier,
                for: indexPath
            ) as! ScenarioCardCell
            let scenario = recommendedItems[indexPath.item]
            cell.configure(with: scenario)
            return cell

        case .scenarios:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ScenarioCardCell.reuseIdentifier,
                for: indexPath
            ) as! ScenarioCardCell
            let scenario = allScenarios[indexPath.item]
            cell.configure(with: scenario)
            return cell
        }
    }

    // Headers
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let sectionType = Section(rawValue: indexPath.section) else {
            return UICollectionReusableView()
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: DashboardSectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! DashboardSectionHeaderView

        switch sectionType {
        case .hero:
            header.titleLabel.text = nil // no header for hero
        case .quickActions:
            header.titleLabel.text = "Practice Modes"
        case .recommended:
            header.titleLabel.text = "Recommended for You"
        case .scenarios:
            header.titleLabel.text = "Explore Roleplays"
        }

        return header
    }
}

// MARK: - UICollectionViewDelegate

extension DashboardViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard let sectionType = Section(rawValue: indexPath.section) else { return }

        switch sectionType {
        case .hero:
            startBestNextPractice()

        case .quickActions:
            switch indexPath.item {
            case 0:
                print("QuickAction: Find a Peer tapped")
                // navigationController?.pushViewController(peerVC, animated: true)
            case 1:
                print("QuickAction: 2-Min JAM tapped")
                // navigationController?.pushViewController(jamVC, animated: true)
            case 2:
                print("QuickAction: Random Roleplay tapped")
                // navigationController?.pushViewController(randomRoleplayVC, animated: true)
            default:
                break
            }

        case .recommended:
            let item = recommendedItems[indexPath.item]
            print("Recommended scenario tapped:", item.title)
            // navigationController?.pushViewController(roleplayDetailVC(for: item), animated: true)

        case .scenarios:
            let item = allScenarios[indexPath.item]
            print("Scenario tapped:", item.title)
            // navigationController?.pushViewController(roleplayDetailVC(for: item), animated: true)
        }
    }

    private func startBestNextPractice() {
        print("Start best next practice flow")
        // Decide best next action based on interests / history and push that VC.
    }
}

// MARK: - HeroCardCell

final class HeroCardCell: UICollectionViewCell {

    static let reuseIdentifier = "HeroCardCell"

    var onPrimaryAction: (() -> Void)?

    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 20
        v.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        return v
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 22, weight: .bold)
        lbl.numberOfLines = 2
        lbl.textColor = .label
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 15, weight: .regular)
        lbl.numberOfLines = 2
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let primaryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Start", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemPurple
        btn.tintColor = .white
        btn.layer.cornerRadius = 16
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(primaryButton)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            primaryButton.topAnchor.constraint(greaterThanOrEqualTo: subtitleLabel.bottomAnchor, constant: 12),
            primaryButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            primaryButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])

        primaryButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, subtitle: String, buttonTitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        primaryButton.setTitle(buttonTitle, for: .normal)
    }

    @objc private func buttonTapped() {
        onPrimaryAction?()
    }
}

// MARK: - QuickActionCell

final class QuickActionCell: UICollectionViewCell {

    static let reuseIdentifier = "QuickActionCell"

    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 16
        v.backgroundColor = UIColor.secondarySystemBackground
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .systemPurple
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 15, weight: .semibold)
        lbl.textColor = .label
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12, weight: .regular)
        lbl.textColor = .secondaryLabel
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            iconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            iconView.widthAnchor.constraint(equalToConstant: 24),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with action: DashboardViewController.QuickAction) {
        titleLabel.text = action.title
        subtitleLabel.text = action.subtitle
        iconView.image = UIImage(systemName: action.systemImageName)
    }
}

// MARK: - ScenarioCardCell

final class ScenarioCardCell: UICollectionViewCell {

    static let reuseIdentifier = "ScenarioCardCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let gradientView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 15, weight: .semibold)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12, weight: .regular)
        lbl.textColor = UIColor.white.withAlphaComponent(0.8)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        contentView.addSubview(imageView)
        contentView.addSubview(gradientView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.45),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -2),

            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

        applyGradient()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: DashboardViewController.ScenarioItem) {
        imageView.image = UIImage(named: item.imageName)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }

    private func applyGradient() {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        layer.locations = [0.0, 1.0]
        layer.startPoint = CGPoint(x: 0.5, y: 0.0)
        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1)) // real frame set in layoutSubviews
        gradientView.layer.insertSublayer(layer, at: 0)

        gradientView.layer.masksToBounds = true
        gradientView.layer.cornerRadius = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientView.layer.sublayers?.forEach { $0.frame = gradientView.bounds }
    }
}

// MARK: - Section Header

final class DashboardSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "DashboardSectionHeaderView"

    let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 20, weight: .bold)
        lbl.textColor = .label
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
