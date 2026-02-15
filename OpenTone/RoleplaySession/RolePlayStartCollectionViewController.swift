import UIKit

class RolePlayStartCollectionViewController: UICollectionViewController,
                                             UICollectionViewDelegateFlowLayout {
    var currentScenario: RoleplayScenario?
    var currentSession: RoleplaySession?
    

    private var shouldStartRoleplay = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard currentScenario != nil else {
            fatalError("RolePlayStartVC: Scenario")
        }

        title = currentScenario?.title
        view.backgroundColor = AppColors.screenBackground
        collectionView.backgroundColor = AppColors.screenBackground
        collectionView.collectionViewLayout = createLayout()
    }
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
            default:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "ButtonCell",
                    for: indexPath
                ) as! ButtonCell

                cell.onStartTapped = { [weak self] in
                    self?.startRoleplay()
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
extension RolePlayStartCollectionViewController {

    private  func startRoleplay() {
        
        guard let scenario = currentScenario else { return }
        guard let session = RoleplaySessionDataModel.shared.startSession(
            scenarioId: scenario.id
        ) else { return }

        self.currentSession = session
        performSegue(withIdentifier: "toRoleplayChat", sender: self)
    }
}
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
    
    @IBAction func unwindToRoleplaysVC(_ segue: UIStoryboardSegue) {
    }
}
