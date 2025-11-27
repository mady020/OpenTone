//
//  PrepareSessionViewController.swift
//  OpenTone
//
//  Created by Student on 26/11/25.
//
//
// PrepareSessionViewController.swift
//

//
// PrepareSessionViewController.swift
//

import UIKit

final class PrepareSessionViewController: UIViewController {

    // MARK: - Data
    private var hotTopic: String = "THE FUTURE OF REMOTE WORK"
    private var suggestions: [String] = [
        "Increased Flexibility",
        "Global Collaboration",
        "Work-Life Balance",
        "Productivity Trends"
    ]
    private var extraSuggestionsShown = false
    private var didStartTimerOnAppear = false

    // MARK: - UI
    private var collectionView: UICollectionView!

    // Floating glass bulb
    private let floatingBulb: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemMaterialLight)
        let v = UIVisualEffectView(effect: blur)
        v.layer.cornerRadius = 26
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let bulbImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "lightbulb"))
        iv.tintColor = UIColor(hex: "#8F78EA")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Start button
    private let startButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Start The Jam", for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 20)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(hex: "#8F78EA")
        b.layer.cornerRadius = 18
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupCollectionView()
        setupStartButton()
        setupFloatingBulb()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !didStartTimerOnAppear else { return }
        didStartTimerOnAppear = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let index = IndexPath(item: 0, section: 0)
            guard let cell = self.collectionView.cellForItem(at: index) as? TimerContainerCell else { return }

            cell.topLabel.text = "Your preparation time is 2 minutes"
            cell.timerView.totalSeconds = 120

            cell.timerView.onTimerStarted = { [weak cell] in
                cell?.topLabel.text = "Your preparation time has STARTED"
            }

            cell.timerView.runReadySequenceThenStart()
        }
    }

    // MARK: - Setup Collection View
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 12

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsVerticalScrollIndicator = false

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(TimerContainerCell.self,
                                forCellWithReuseIdentifier: TimerContainerCell.reuseID)
        collectionView.register(TopicCell.self,
                                forCellWithReuseIdentifier: TopicCell.reuseID)
        collectionView.register(TagCell.self,
                                forCellWithReuseIdentifier: TagCell.reuseID)

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Start Button
    private func setupStartButton() {
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            startButton.heightAnchor.constraint(equalToConstant: 56),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18)
        ])

        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
    }

    // MARK: - Floating Bulb
    private func setupFloatingBulb() {
        view.addSubview(floatingBulb)
        floatingBulb.contentView.addSubview(bulbImageView)

        NSLayoutConstraint.activate([
            floatingBulb.widthAnchor.constraint(equalToConstant: 52),
            floatingBulb.heightAnchor.constraint(equalToConstant: 52),
            floatingBulb.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            floatingBulb.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -10),

            bulbImageView.centerXAnchor.constraint(equalTo: floatingBulb.centerXAnchor),
            bulbImageView.centerYAnchor.constraint(equalTo: floatingBulb.centerYAnchor),
            bulbImageView.widthAnchor.constraint(equalToConstant: 26),
            bulbImageView.heightAnchor.constraint(equalToConstant: 26)
        ])

        floatingBulb.isUserInteractionEnabled = true
        floatingBulb.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(bulbTapped))
        )
    }

    // MARK: - Actions
    @objc private func bulbTapped() {
        guard !extraSuggestionsShown else { return }
        extraSuggestionsShown = true

        let extras = ["Remote Onboarding", "Async Communication"]
        let startIndex = suggestions.count
        suggestions.append(contentsOf: extras)

        UIView.animate(withDuration: 0.25, animations: {
            self.floatingBulb.alpha = 0
        }, completion: { _ in
            self.floatingBulb.isHidden = true

            let newIndexPaths = [
                IndexPath(item: startIndex, section: 2),
                IndexPath(item: startIndex + 1, section: 2)
            ]

            self.collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: newIndexPaths)
            })
        })
    }

    @objc private func startTapped() {
        let vc = SpeakJamViewController()
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
}

// MARK: - CollectionView
extension PrepareSessionViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {

        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return suggestions.count
        default: return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch indexPath.section {
        case 0:
            let c = collectionView.dequeueReusableCell(
                withReuseIdentifier: TimerContainerCell.reuseID, for: indexPath
            ) as! TimerContainerCell
            c.topLabel.text = "Your preparation time is 2 minutes"
            return c

        case 1:
            let c = collectionView.dequeueReusableCell(
                withReuseIdentifier: TopicCell.reuseID, for: indexPath
            ) as! TopicCell
            c.configure(topic: hotTopic)
            return c

        case 2:
            let c = collectionView.dequeueReusableCell(
                withReuseIdentifier: TagCell.reuseID, for: indexPath
            ) as! TagCell
            c.configure(text: suggestions[indexPath.item])
            return c

        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(_ col: UICollectionView,
                        layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let full = view.bounds.width
        let contentWidth = full - 32

        switch indexPath.section {

        case 0: // timer
            let circle: CGFloat = 240
            let topH: CGFloat = 24
            let spacing: CGFloat = 18
            return CGSize(width: contentWidth, height: topH + spacing + circle + 10)

        case 1: // topic
            return CGSize(width: contentWidth, height: 70)

        case 2: // chips
            let chip = (contentWidth - 12)/2
            return CGSize(width: chip, height: 46)

        default:
            return CGSize(width: contentWidth, height: 44)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {

        switch section {
        case 0:
            return UIEdgeInsets(top: 12, left: 16, bottom: 6, right: 16)

        case 1:
            return UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)

        case 2:
            return UIEdgeInsets(top: 10, left: 16, bottom: 120, right: 16)

        default:
            return .zero
        }
    }
}

// MARK: - Cells

final class TimerContainerCell: UICollectionViewCell {
    static let reuseID = "TimerContainerCell"

    let timerView = TimerView()
    let topLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textAlignment = .left
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        contentView.addSubview(topLabel)
        contentView.addSubview(timerView)

        timerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            topLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            topLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            timerView.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 18),
            timerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            timerView.widthAnchor.constraint(equalToConstant: 240),
            timerView.heightAnchor.constraint(equalToConstant: 240),
            timerView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -6)
        ])
    }
}

final class TopicCell: UICollectionViewCell {
    static let reuseID = "TopicCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Your Hot Topic"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textAlignment = .left
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let topicLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textAlignment = .left
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        contentView.addSubview(topicLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            topicLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            topicLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            topicLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            topicLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(topic: String) {
        topicLabel.text = topic
    }
}

final class TagCell: UICollectionViewCell {
    static let reuseID = "TagCell"

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth = 1.4
        contentView.layer.borderColor = UIColor(hex: "#8F78EA").cgColor

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String) {
        label.text = text
    }
}
