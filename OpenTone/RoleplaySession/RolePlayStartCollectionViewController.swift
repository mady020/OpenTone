import UIKit

class RolePlayStartCollectionViewController: UICollectionViewController,
                                             UICollectionViewDelegateFlowLayout {

    // MARK: - Passed Data
    var currentScenario: RoleplayScenario?
    var currentSession: RoleplaySession?
    private var shouldStartRoleplay = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        guard currentScenario != nil, currentSession != nil else {
            fatalError("RolePlayStartVC: Scenario or Session not passed")
        }

        title = currentScenario?.title
        collectionView.collectionViewLayout = createLayout()
    }

    // MARK: - Collection View Data Source
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return 3
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        switch indexPath.item {

        // MARK: - Cell 0 : Description
        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "DescriptionCell",
                for: indexPath
            ) as! DescriptionCell
            print("description")
            cell.configure(
                description: currentScenario?.description ?? "",
                time: "\(currentScenario?.estimatedTimeMinutes ?? 0) minutes"
            )

            return cell

        // MARK: - Cell 1 : Script Preview + Key Phrases
        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ScriptCell",
                for: indexPath
            ) as! ScriptCell

            let firstMessage = currentScenario?.script.first

            cell.configure(
                guidedText: "Choose a response and practice speaking naturally.",
                keyPhrases: firstMessage?.replyOptions ?? [],
                premiumText: "Speak freely and get real-time pronunciation feedback."
            )

            return cell

            // MARK: - Cell 2 : Start Button
            default:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "ButtonCell",
                    for: indexPath
                ) as! ButtonCell

                cell.onStartTapped = { [weak self] in
                    guard let self = self else { return }
                    self.performSegue(withIdentifier: "toRoleplayChat", sender: self)
                }

                return cell


        }
    }
    
    
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

}

// MARK: - Navigation
extension RolePlayStartCollectionViewController {

    private func startRoleplay() {

        guard let scenario = currentScenario,
              let session = currentSession else { return }

        let storyboard = UIStoryboard(name: "RolePlayStoryBoard", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "RoleplayChatViewController"
        ) as! RoleplayChatViewController

        vc.scenario = scenario
        vc.session = session

        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Layout
extension RolePlayStartCollectionViewController {

    func createLayout() -> UICollectionViewCompositionalLayout {

        UICollectionViewCompositionalLayout { _, _ in

            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(200)
                )
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(200)
                ),
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 16, leading: 16, bottom: 16, trailing: 16
            )
            section.interGroupSpacing = 16

            return section
        }
    }
    
    
}
