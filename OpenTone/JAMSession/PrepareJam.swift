
import UIKit

final class PrepareJamViewController: UIViewController {

    var forceTimerReset: Bool = false

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bulbButton: UIButton!
    
    @IBOutlet var closeButton: UIButton!
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        
        showSessionAlert()
    }
    
    private var selectedTopic: String = ""
    private var allSuggestions: [String] = []

    private var remainingSeconds: Int = 10
    private var lastKnownSeconds: Int = 10

    private var visibleCount = 4
    private var visibleSuggestions: [String] {
        Array(allSuggestions.prefix(visibleCount))
    }
    
    private func navigateToPrepare(resetTimer: Bool) {

        guard let prepareVC = storyboard?
            .instantiateViewController(withIdentifier: "PrepareJamViewController")
                as? PrepareJamViewController else { return }

        prepareVC.forceTimerReset = resetTimer
        navigationController?.pushViewController(prepareVC, animated: true)
    }
    
    private func showSessionAlert() {

        let alert = UIAlertController(
            title: "Session Running",
            message: "Continue with current session or exit?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            JamSessionDataModel.shared.continueSession()
        })
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            JamSessionDataModel.shared.cancelJamSession()
        })
        alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
            JamSessionDataModel.shared.cancelJamSession()
//            self.startNewSession()
        })

        present(alert, animated: true)
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true

        guard let session = JamSessionDataModel.shared.getActiveSession() else { return }

        selectedTopic = session.topic
        allSuggestions = session.suggestions

        if forceTimerReset {
            remainingSeconds = 10
            forceTimerReset = false
        } else {
            remainingSeconds = session.secondsLeft
        }

        lastKnownSeconds = remainingSeconds

        visibleCount = min(4, allSuggestions.count)
        bulbButton.isHidden = visibleCount >= allSuggestions.count

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

        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "CountdownViewController"
        ) as? CountdownViewController else { return }

        vc.isSpeechCountdown = true   // ✅ REQUIRED FIX

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
            return CGSize(width: width, height: 105)
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

