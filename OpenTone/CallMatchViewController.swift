import UIKit

class CallMatchViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var sharedInterestsCollectionView: UICollectionView!
    @IBOutlet weak var startCallButton: UIButton!
    @IBOutlet weak var searchAgainButton: UIButton!

    // ✅ DATA PASSED FROM SETUP SCREEN
    var matchedUser: User?
    var sharedInterests: [Interest] = []
    var generatedQuestions : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        configureData()
    }
}

// MARK: - UI Setup
extension CallMatchViewController {

    func setupUI() {
        cardView.layer.cornerRadius = 25
        cardView.layer.masksToBounds = true

        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill

        startCallButton.layer.cornerRadius = 25
        searchAgainButton.layer.cornerRadius = 25
        addShadow(to: cardView)
    }

    func addShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 10
    }

    func configureData() {
        guard let user = matchedUser else { return }
        let userData = CallSessionDataModel.shared.getParticipantDetails(from: user)
        nameLabel.text = userData.name
        bioLabel.text = userData.bio
        

        if let image = userData.image {
            profileImageView.image = UIImage(named: image)
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }

        sharedInterestsCollectionView.reloadData()
    }
}

// MARK: - CollectionView
extension CallMatchViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func setupCollectionView() {
        sharedInterestsCollectionView.delegate = self
        sharedInterestsCollectionView.dataSource = self
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)

        sharedInterestsCollectionView.collectionViewLayout = layout


        sharedInterestsCollectionView.collectionViewLayout = layout
        sharedInterestsCollectionView.backgroundColor = .clear
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        sharedInterests.count < 5 ? sharedInterests.count : 5
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "InterestChipCell",
            for: indexPath
        ) as! InterestChipCell

        cell.configure(sharedInterests[indexPath.item].rawValue.capitalized)
        return cell
    }
}

// MARK: - Buttons
extension CallMatchViewController {

    @IBAction func startCallTapped(_ sender: UIButton) {

        guard matchedUser != nil else {
            print("❌ matchedUser not found")
            return
        }

        // ✅ Generate questions from shared interests
        generatedQuestions = CallSessionDataModel.shared
            .generateSuggestedQuestions(from: sharedInterests)

        print("✅ Questions Generated:")
        generatedQuestions.forEach { print($0) }

        performSegue(withIdentifier: "goToCallInProgress", sender: self)
    }

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "goToCallInProgress",
           let vc = segue.destination as? CallInProgressViewController {

            vc.matchedUser = matchedUser
            vc.questions = generatedQuestions
        }
    }




    @IBAction func searchAgainTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
