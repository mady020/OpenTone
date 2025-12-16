import UIKit

enum CallSetupSection: Int, CaseIterable {
    case interests
    case gender
    case english
}

class CallSetupViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var confirmButton: UIButton!
    
    
    var matchedUser: User?
    var selectedSessionInterests: [Interest] = []




    private let interestsData: [Interest] = Interest.allCases
    private let gendersData: [Gender] = [.male, .female, .other]
    private let englishLevelsData: [EnglishLevel] = [.beginner , .intermediate , .advanced]


    private var selectedInterests: Set<Interest> = []
    private var selectedGender: Gender?
    private var selectedEnglishLevel: EnglishLevel?

    override func viewDidLoad() {
        super.viewDidLoad()

        confirmButton.layer.cornerRadius = 25
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = createLayout()
        

    }
    
   
}


extension CallSetupViewController {

    func createLayout() -> UICollectionViewLayout {

        UICollectionViewCompositionalLayout { sectionIndex, _ in

            guard let section = CallSetupSection(rawValue: sectionIndex) else { return nil }

            switch section {
            case .interests:
                return self.createInterestsSection()
            case .gender, .english:
                return self.createSingleRowSection()
            }
        }
    }

    func createInterestsSection() -> NSCollectionLayoutSection {

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1/3),
            heightDimension: .absolute(40)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(120)
            ),
            subitems: [item]
        )

        group.interItemSpacing = .fixed(8)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.boundarySupplementaryItems = [createHeader()]
        return section
    }

    func createSingleRowSection() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1/3),
            heightDimension: .absolute(40)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(40)
            ),
            subitems: [item]
        )

        group.interItemSpacing = .fixed(8)

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.boundarySupplementaryItems = [createHeader()]
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)

        return section
    }

    func createHeader() -> NSCollectionLayoutBoundarySupplementaryItem {

       NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(40)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top,
            
        )

    }
}


extension CallSetupViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        CallSetupSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        switch CallSetupSection(rawValue: section)! {
        case .interests: return interestsData.count
        case .gender: return gendersData.count
        case .english: return englishLevelsData.count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "SelectableCell",
            for: indexPath
        ) as! SelectableCell

        switch CallSetupSection(rawValue: indexPath.section)! {

        case .interests:
            let interest = interestsData[indexPath.item]
            cell.configure(
                title: interest.rawValue.capitalized,
                isSelected: selectedInterests.contains(interest)
            )

        case .gender:
            let gender = gendersData[indexPath.item]
            cell.configure(
                title: gender.rawValue.capitalized,
                isSelected: selectedGender == gender
            )

        case .english:
            let level = englishLevelsData[indexPath.item]
            cell.configure(
                title: level.rawValue.capitalized,
                isSelected: selectedEnglishLevel == level
            )
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "SectionHeaderView",
            for: indexPath
        ) as! SectionHeaderView

        switch CallSetupSection(rawValue: indexPath.section)! {
        case .interests: header.titleLabel.text = "Interests"
        case .gender: header.titleLabel.text = "Gender"
        case .english: header.titleLabel.text = "English Level"
        }

        return header
    }
}

extension CallSetupViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        switch CallSetupSection(rawValue: indexPath.section)! {

        case .interests:
            let interest = interestsData[indexPath.item]
            if selectedInterests.contains(interest) {
                selectedInterests.remove(interest)
            } else {
                selectedInterests.insert(interest)
            }

        case .gender:
            selectedGender = gendersData[indexPath.item]

        case .english:
            selectedEnglishLevel = englishLevelsData[indexPath.item]
        }

        collectionView.reloadSections(IndexSet(integer: indexPath.section))
    }
    
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {

        print("✅ Confirm tapped")

        guard let gender = selectedGender,
              let englishLevel = selectedEnglishLevel else {
            print("❌ Missing gender or level")
            return
        }

        let interests = Array(selectedInterests)
        selectedSessionInterests = interests

        let session = CallSession(
            participantOneID: UserDataModel.shared.getCurrentUser()!.id,
            interests: interests,
            gender: gender,
            englishLevel: englishLevel
        )

        CallSessionDataModel.shared.startSession(session)

        print("""
        ✅ SESSION CREATED
        Gender: \(gender.rawValue)
        English: \(englishLevel.rawValue)
        Interests: \(interests.map { $0.rawValue })
        """)

        findPeerAndNavigate()
    }

    
    func findPeerAndNavigate() {

        guard let session = CallSessionDataModel.shared.getActiveSession() else { return }

        guard let matches = CallSessionDataModel.shared.getMatches(
            interests: session.interests,
            gender: session.gender,
            englishLevel: session.englishLevel
        ),
        let matchID = matches.first,
        let user = UserDataModel.shared.getUser(by: matchID)
        else {
            print("❌ No peer found")
            return
        }

        matchedUser = user
        selectedSessionInterests = session.interests

        goToUserProfile()
    }
    
    func goToUserProfile(){
        let storyboard = UIStoryboard(name: "UserProfile", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "UserProfile") as! ProfileStoryboardCollectionViewController
        vc.isComingFromCall = true
        vc.titleText = "🎉 Peer Found!"
        navigationController?.pushViewController(vc, animated: true)
    }


    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "goToMatch",
           let vc = segue.destination as? CallMatchViewController {

            vc.matchedUser = matchedUser
            vc.sharedInterests = selectedSessionInterests
        }
    }




    
}
