
import UIKit

final class PrepareJamViewController: UIViewController {

    var forceTimerReset: Bool = false

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bulbButton: UIButton!
    
    @IBOutlet var closeButton: UIButton!
    
    private var isRegenerating = false

    @IBAction func closeButtonTapped(_ sender: UIButton) {
        regenerateTopic()
    }
    
    private func regenerateTopic() {
        guard !isRegenerating else { return }
        isRegenerating = true

        if let timerCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? TimerCellCollectionViewCell {
            timerCell.pauseTimer()
        }

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = AppColors.primary
        spinner.startAnimating()
        closeButton.setImage(nil, for: .normal)
        closeButton.configuration?.image = nil
        closeButton.addSubview(spinner)
        spinner.center = CGPoint(x: closeButton.bounds.midX, y: closeButton.bounds.midY)

        JamSessionDataModel.shared.regenerateTopicWithAI { [weak self] session in
            guard let self = self, let session = session else { return }

            spinner.removeFromSuperview()
            self.closeButton.configuration?.image = UIImage(systemName: "arrow.triangle.2.circlepath")
            self.isRegenerating = false

            self.selectedTopic = session.topic
            self.allSuggestions = session.suggestions
            self.remainingSeconds = session.secondsLeft
            self.lastKnownSeconds = session.secondsLeft
            self.visibleCount = min(4, self.allSuggestions.count)
            self.bulbButton.isHidden = self.visibleCount >= self.allSuggestions.count
            self.collectionView.reloadData()
        }
    }
    
    private var selectedTopic: String = ""
    private var allSuggestions: [String] = []

    private var remainingSeconds: Int = 30
    private var lastKnownSeconds: Int = 30

    private var visibleCount = 4
    private var visibleSuggestions: [String] {
        Array(allSuggestions.prefix(visibleCount))
    }
    
    private var didTransitionToCountdown = false
    
    private func showSessionAlert() {

        let alert = UIAlertController(
            title: "Exit Session",
            message: "Would you like to save this session for later or exit without saving?",
            preferredStyle: .alert
        )

        if let timerCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? TimerCellCollectionViewCell {
            timerCell.pauseTimer()
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            if let timerCell = self.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? TimerCellCollectionViewCell {
                timerCell.resumeTimer()
            }
        })


        alert.addAction(UIAlertAction(title: "Save & Exit", style: .default) { _ in
            if var session = JamSessionDataModel.shared.getActiveSession() {
                session.secondsLeft = self.lastKnownSeconds
                JamSessionDataModel.shared.updateActiveSession(session)
            }
            JamSessionDataModel.shared.saveSessionForLater()
            self.navigateBackToRoot()
        })

        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
            JamSessionDataModel.shared.cancelJamSession()
            self.navigateBackToRoot()
        })

        present(alert, animated: true)
    }

    private func navigateBackToRoot() {
        navigationController?.popToRootViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self
        collectionView.delegate = self

        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        layout.minimumLineSpacing = 15
        layout.minimumInteritemSpacing = 12
        collectionView.collectionViewLayout = layout
        
        navigationItem.hidesBackButton = true

        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = AppColors.primary
        navigationItem.leftBarButtonItem = backButton

        applyDarkModeStyles()

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: PrepareJamViewController, _) in
            self.applyDarkModeStyles()
        }
    }

    @objc private func backButtonTapped() {
        showSessionAlert()
    }

    private func applyDarkModeStyles() {
        view.backgroundColor = AppColors.screenBackground
        collectionView.backgroundColor = AppColors.screenBackground

        let isDark = traitCollection.userInterfaceStyle == .dark
        let buttonBg = isDark
            ? UIColor.tertiarySystemGroupedBackground
            : AppColors.primaryLight

        for button in [bulbButton, closeButton] {
            guard let btn = button, var config = btn.configuration else { continue }
            config.background.backgroundColor = buttonBg
            btn.configuration = config
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true

        guard let session = JamSessionDataModel.shared.getActiveSession() else { return }

        selectedTopic = session.topic
        allSuggestions = session.suggestions

        if forceTimerReset {
            remainingSeconds = 30
            forceTimerReset = false
        } else {
            remainingSeconds = session.secondsLeft
        }

        lastKnownSeconds = remainingSeconds

        visibleCount = min(4, allSuggestions.count)
        bulbButton.isHidden = visibleCount >= allSuggestions.count

        didTransitionToCountdown = false
        collectionView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard var session = JamSessionDataModel.shared.getActiveSession() else { return }
        session.secondsLeft = lastKnownSeconds
        JamSessionDataModel.shared.updateActiveSession(session)
    }

    @IBAction func bulbTapped(_ sender: UIButton) {
        guard visibleCount < allSuggestions.count else { return }

        let start = visibleCount
        visibleCount = allSuggestions.count

        let indexPaths = (start..<visibleCount).map {
            IndexPath(item: $0, section: 2)
        }

        collectionView.performBatchUpdates {
            collectionView.insertItems(at: indexPaths)
        }

        bulbButton.isHidden = true
    }

    @IBAction func startJamTapped(_ sender: UIButton) {
        goToCountdown()
    }

    private func goToCountdown() {
        guard !didTransitionToCountdown else { return }
        didTransitionToCountdown = true

        if let timerCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? TimerCellCollectionViewCell {
            timerCell.pauseTimer()
        }

        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "CountdownViewController"
        ) as? CountdownViewController else { return }

        vc.isSpeechCountdown = true

        navigationController?.pushViewController(vc, animated: true)
    }
}

extension PrepareJamViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        if section == 1 { return 1 }
        return visibleSuggestions.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TimerCellCollectionViewCell.reuseId,
                for: indexPath
            ) as! TimerCellCollectionViewCell

            cell.delegate = self
            cell.setupTimer(
                secondsLeft: remainingSeconds,
                reset: false
            )
            return cell
        }

        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TopicCell",
                for: indexPath
            ) as! TopicCell

            cell.tileLabel.text = selectedTopic
            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "JamSuggestionCell",
            for: indexPath
        ) as! JamSuggestionCell

        cell.configure(text: visibleSuggestions[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = collectionView.bounds.width

        if indexPath.section == 0 {
            return CGSize(width: width - 30, height: 260)
        }

        if indexPath.section == 1 {
            let horizontalPadding: CGFloat = 30
            let availableWidth = width - horizontalPadding
            let topicFont = UIFont.boldSystemFont(ofSize: 24)
            let topicHeight = selectedTopic.boundingRect(
                with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: topicFont],
                context: nil
            ).height
            let totalHeight: CGFloat = 8 + 24 + 8 + ceil(topicHeight) + 15 
            return CGSize(width: width, height: max(totalHeight, 80))
        }

        let available = width - 30 - 12
        return CGSize(width: available / 2, height: 50)
    }
}

extension PrepareJamViewController: TimerCellDelegate {

    func timerDidUpdate(secondsLeft: Int) {
        lastKnownSeconds = secondsLeft
    }

    func timerDidFinish() {
        goToCountdown()
    }
}

