//
//  DashboardViewController.swift
//  OpenTone
//
//  Created by OpenTone Dashboard
//

import UIKit

final class DashboardViewController: UIViewController {

    // MARK: Theme
    private let bgColor      = UIColor(hex: "#F4F5F7")
    private let heroGradientTop  = UIColor(hex: "#EBDDFF")
    private let heroGradientBottom = UIColor(hex: "#CDB3FF")
    private let accentPurple = UIColor(hex: "#5B3CC4")
    private let softCard     = UIColor(hex: "#FBF8FF")
    private let labelPrimary = UIColor(hex: "#3C3644")
    private let labelSecondary = UIColor(hex: "#736A84")

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
        let systemImage: String
    }

    struct ScenarioItem {
        let title: String
        let subtitle: String
        let systemImage: String
        let background: UIColor
        let tint: UIColor
    }

    // MARK: Data
    private let quickActions: [QuickAction] = [
        .init(title: "Find a Peer", subtitle: "1-to-1 practice call", systemImage: "person.2.fill"),
        .init(title: "2-Min JAM", subtitle: "Quick warm-up", systemImage: "timer"),
        .init(title: "Random Roleplay", subtitle: "Surprise scenario", systemImage: "sparkles")
    ]

    private let recommendedItems: [ScenarioItem] = [
        .init(title: "Grocery Shopping", subtitle: "Asking for items & prices", systemImage: "cart.fill",
              background: UIColor(hex: "#FFD7A1"), tint: UIColor(hex: "#9C4A00")),
        .init(title: "Making Friends", subtitle: "Small talk & follow-ups", systemImage: "person.3.fill",
              background: UIColor(hex: "#CFE0FF"), tint: UIColor(hex: "#003F92")),
        .init(title: "Job Interview", subtitle: "Common HR questions", systemImage: "briefcase.fill",
              background: UIColor(hex: "#C3FFF2"), tint: UIColor(hex: "#005E54"))
    ]

    private let allScenarios: [ScenarioItem] = [
        .init(title: "Airport Check-in", subtitle: "Check-in & boarding", systemImage: "airplane",
              background: UIColor(hex: "#D9EFFF"), tint: UIColor(hex: "#004E89")),
        .init(title: "Ordering Food", subtitle: "Restaurant conversation", systemImage: "fork.knife",
              background: UIColor(hex: "#FFE4CC"), tint: UIColor(hex: "#A24C00")),
        .init(title: "Birthday Celebration", subtitle: "Group social chat", systemImage: "gift.fill",
              background: UIColor(hex: "#FFDAF0"), tint: UIColor(hex: "#9E005C")),
        .init(title: "Hotel Booking", subtitle: "Reservations & questions", systemImage: "bed.double.fill",
              background: UIColor(hex: "#E3F3FF"), tint: UIColor(hex: "#004E87")),
        .init(title: "First Date", subtitle: "Confident introductions", systemImage: "heart.fill",
              background: UIColor(hex: "#FFE2E5"), tint: UIColor(hex: "#B30024"))
    ]

    // MARK: CollectionView
    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "OpenTone"
        view.backgroundColor = bgColor
        configureCollectionView()
    }

    private func configureCollectionView() {
        let layout = createLayout()

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = bgColor
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true

        // Cells
        collectionView.register(HeroCardCell.self, forCellWithReuseIdentifier: HeroCardCell.reuseIdentifier)
        collectionView.register(QuickActionCell.self, forCellWithReuseIdentifier: QuickActionCell.reuseIdentifier)
        collectionView.register(ScenarioModuleCell.self, forCellWithReuseIdentifier: ScenarioModuleCell.reuseIdentifier)

        // Headers
        collectionView.register(DashboardSectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: DashboardSectionHeader.reuseIdentifier)

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Layout
    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { index, _ in
            guard let sec = Section(rawValue: index) else { return nil }

            switch sec {
            case .hero: return Self.heroSection()
            case .quickActions: return Self.quickSection()
            case .recommended, .scenarios: return Self.horizontalModules()
            }
        }
    }

    private static func heroSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                            heightDimension: .fractionalHeight(1)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                          heightDimension: .absolute(225)),
                                                       subitems: [item])
        let sec = NSCollectionLayoutSection(group: group)
        sec.contentInsets = .init(top: 18, leading: 18, bottom: 10, trailing: 18)
        return sec
    }

    private static func quickSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1/3),
                                                            heightDimension: .fractionalHeight(1)))
        item.contentInsets = .init(top: 0, leading: 6, bottom: 0, trailing: 6)

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                         heightDimension: .absolute(118)),
                                                       subitems: [item, item, item])
        let sec = NSCollectionLayoutSection(group: group)
        sec.boundarySupplementaryItems = [Self.header()]
        sec.contentInsets = .init(top: 4, leading: 12, bottom: 16, trailing: 12)
        return sec
    }

    private static func horizontalModules() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .estimated(245),
                                                            heightDimension: .absolute(150)))
        item.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 14)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .estimated(245),
                                                                         heightDimension: .absolute(150)),
                                                       subitems: [item])
        let sec = NSCollectionLayoutSection(group: group)
        sec.orthogonalScrollingBehavior = .continuous
        sec.boundarySupplementaryItems = [Self.header()]
        sec.contentInsets = .init(top: 4, leading: 18, bottom: 16, trailing: 18)
        return sec
    }

    private static func header() -> NSCollectionLayoutBoundarySupplementaryItem {
        .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                heightDimension: .absolute(42)),
              elementKind: UICollectionView.elementKindSectionHeader,
              alignment: .top)
    }
}

// MARK: Data Source
extension DashboardViewController: UICollectionViewDataSource {
    func numberOfSections(in cv: UICollectionView) -> Int { Section.allCases.count }

    func collectionView(_ cv: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .hero: return 1
        case .quickActions: return quickActions.count
        case .recommended: return recommendedItems.count
        case .scenarios: return allScenarios.count
        }
    }

    func collectionView(_ cv: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section)! {

        case .hero:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: HeroCardCell.reuseIdentifier,
                                              for: indexPath) as! HeroCardCell
            cell.configure(title: "Keep building your communication skills",
                           subtitle: "Practice a quick session today to stay sharp.",
                           button: "Start Practice")
            return cell

        case .quickActions:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: QuickActionCell.reuseIdentifier,
                                              for: indexPath) as! QuickActionCell
            cell.configure(quickActions[indexPath.item])
            return cell

        case .recommended:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: ScenarioModuleCell.reuseIdentifier,
                                              for: indexPath) as! ScenarioModuleCell
            cell.configure(recommendedItems[indexPath.item])
            return cell

        case .scenarios:
            let cell = cv.dequeueReusableCell(withReuseIdentifier: ScenarioModuleCell.reuseIdentifier,
                                              for: indexPath) as! ScenarioModuleCell
            cell.configure(allScenarios[indexPath.item])
            return cell
        }
    }

    // Headers
    func collectionView(_ cv: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = cv.dequeueReusableSupplementaryView(ofKind: kind,
                                                         withReuseIdentifier: DashboardSectionHeader.reuseIdentifier,
                                                         for: indexPath) as! DashboardSectionHeader

        switch Section(rawValue: indexPath.section)! {
        case .hero: header.titleLabel.text = nil
        case .quickActions: header.titleLabel.text = "Practice Modes"
        case .recommended: header.titleLabel.text = "Recommended for You"
        case .scenarios: header.titleLabel.text = "Explore Roleplays"
        }
        return header
    }
}

// MARK: Delegate
extension DashboardViewController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sec = Section(rawValue: indexPath.section)!
        switch sec {
        case .hero: print("Start best next practice")
        case .quickActions: print("Quick action tapped:", quickActions[indexPath.item].title)
        case .recommended: print("Recommended tapped:", recommendedItems[indexPath.item].title)
        case .scenarios: print("Scenario tapped:", allScenarios[indexPath.item].title)
        }
    }
}

//
//  Cells
//

// MARK: Hero
final class HeroCardCell: UICollectionViewCell {
    static let reuseIdentifier = "HeroCardCell"

    private let container = UIView()
    private let title = UILabel()
    private let subtitle = UILabel()
    private let button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        // gradient
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(hex: "#EBDDFF").cgColor, UIColor(hex: "#CDB3FF").cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 24

        container.layer.insertSublayer(gradient, at: 0)
        container.layer.cornerRadius = 24
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        title.font = .systemFont(ofSize: 23, weight: .bold)
        title.textColor = UIColor(hex: "#3C3644")
        title.numberOfLines = 2

        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = UIColor(hex: "#6D6480")
        subtitle.numberOfLines = 2

        button.layer.cornerRadius = 16
        button.backgroundColor = UIColor(hex: "#5B3CC4")
        button.tintColor = .white

        [title, subtitle, button].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            title.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            subtitle.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            subtitle.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),

            button.topAnchor.constraint(greaterThanOrEqualTo: subtitle.bottomAnchor, constant: 14),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 44),
            button.widthAnchor.constraint(equalToConstant: 165)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        container.layer.sublayers?.first?.frame = container.bounds
    }

    func configure(title t: String, subtitle s: String, button bt: String) {
        title.text = t
        subtitle.text = s
        button.setTitle(bt, for: .normal)
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: Quick Action
final class QuickActionCell: UICollectionViewCell {
    static let reuseIdentifier = "QuickActionCell"

    private let container = UIView()
    private let icon = UIImageView()
    private let title = UILabel()
    private let subtitle = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        container.backgroundColor = UIColor(hex: "#FBF8FF")
        container.layer.cornerRadius = 18
        container.layer.shadowOpacity = 0.06
        container.layer.shadowRadius = 6
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        icon.tintColor = UIColor(hex: "#5B3CC4")
        icon.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = UIColor(hex: "#3C3644")
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = UIColor(hex: "#736A84")
        subtitle.numberOfLines = 2

        [icon, title, subtitle].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            icon.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            icon.heightAnchor.constraint(equalToConstant: 28),
            icon.widthAnchor.constraint(equalToConstant: 28),

            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 6),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),
            subtitle.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            subtitle.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            subtitle.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -10)
        ])
    }

    func configure(_ action: DashboardViewController.QuickAction) {
        icon.image = UIImage(systemName: action.systemImage)
        title.text = action.title
        subtitle.text = action.subtitle
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: Scenario Module (Workout-style)
final class ScenarioModuleCell: UICollectionViewCell {
    static let reuseIdentifier = "ScenarioModuleCell"

    private let container = UIView()
    private let icon = UIImageView()
    private let title = UILabel()
    private let subtitle = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        container.layer.cornerRadius = 20
        container.layer.shadowOpacity = 0.08
        container.layer.shadowRadius = 8
        container.layer.shadowOffset = CGSize(width: 0, height: 5)
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit

        title.font = .systemFont(ofSize: 18, weight: .semibold)
        title.numberOfLines = 1

        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = .white.withAlphaComponent(0.8)
        subtitle.numberOfLines = 1

        [icon, title, subtitle].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 38),
            icon.heightAnchor.constraint(equalToConstant: 38),

            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            title.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -18),
            title.topAnchor.constraint(equalTo: container.topAnchor, constant: 28),

            subtitle.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            subtitle.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -18),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2)
        ])
    }

    func configure(_ item: DashboardViewController.ScenarioItem) {
        container.backgroundColor = item.background
        icon.image = UIImage(systemName: item.systemImage)
        icon.tintColor = item.tint
        title.text = item.title
        title.textColor = item.tint
        subtitle.text = item.subtitle
        subtitle.textColor = item.tint.withAlphaComponent(0.8)
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: Header
final class DashboardSectionHeader: UICollectionReusableView {
    static let reuseIdentifier = "DashboardSectionHeader"

    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = UIColor(hex: "#3C3644")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

//
//  Utility
//
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255,
                  alpha: 1)
    }
}

