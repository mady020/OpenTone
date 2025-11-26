import UIKit

class CallInProgressViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
  
    @IBOutlet var isConnected: UIImageView!
    
    

    @IBOutlet weak var questionsContainerView: UIView!
    @IBOutlet weak var questionsCollectionView: UICollectionView!

    @IBOutlet weak var callStatusLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var endCallButton: UIButton!

    
    @IBOutlet weak var profileContainerView: UIView!
    
    
    var matchedUser: User?
    var questions: [String] = []
    
    
    
    
    
    // MARK: - Dynamic Data (pass from previous screen)
//    var userName: String = "Harshdeep Singh"
    var userProfileImage: UIImage? = nil
 

//    var questions: [String] = [  "What technology trends excite you most?",
//                                 "What's the last movie you really enjoyed? ",
//                                 "How do you like to spend your weekends?",
//                                 "What's something new you learned recently?"
//                                 ]   // <-- dynamically passed

    // Timer
    var timer: Timer?
    var secondsElapsed: Int = 0


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

       setupUI()
        configureData()
        setupCollectionView()
        questionsCollectionView.reloadData()
        self.tabBarController?.delegate = self
        addShadow(to: questionsContainerView)
        addShadow(to: profileContainerView)

        if let matchedUser = matchedUser
        {
            nameLabel.text = matchedUser.name
        }
  

     
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
        
    }
    
    func addShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 10
    }
    
    
    
}

extension CallInProgressViewController {
    
    func setupUI() {
        isConnected.tintColor = .systemGreen
        // Rounded profile image
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        
        
         //Purple question box
                questionsContainerView.layer.cornerRadius = 20
//                questionsContainerView.clipsToBounds = true
        
        //Purple question box
               profileContainerView.layer.cornerRadius = 20
//               profileContainerView.clipsToBounds = true
        
         //End call button
                endCallButton.layer.cornerRadius = 25
            }
        
            func configureData() {
//                nameLabel.text = userName
                
                statusLabel.text = "Connected"
                timerLabel.text = "0:00"
                if let matchedUser = matchedUser {
                    if let image = matchedUser.avatar {
                        profileImageView.image = UIImage(named: image)
                    }
                }
            }
        }
        extension CallInProgressViewController: UICollectionViewDelegate, UICollectionViewDataSource {
        
            func setupCollectionView() {
                questionsCollectionView.delegate = self
                questionsCollectionView.dataSource = self

//                let layout = UICollectionViewFlowLayout()
//                layout.scrollDirection = .vertical
//
//                layout.minimumLineSpacing = 10
//                layout.minimumInteritemSpacing = 0
//
//                // IMPORTANT: force full width so text aligns properly
//                layout.estimatedItemSize = CGSize(
//                    width: questionsCollectionView.bounds.width,
//                    height: 44
//                )
//
//                layout.sectionInset = UIEdgeInsets(
//                    top: 10,
//                    left: 16,
//                    bottom: 10,
//                    right: 16
//                )
//                
                let layout = LeftAlignedCollectionViewFlowLayout()
                layout.estimatedItemSize = CGSize(width: 1, height: 1)
                layout.minimumLineSpacing = 5
                layout.minimumInteritemSpacing = 10
                layout.sectionInset = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)

                questionsCollectionView.collectionViewLayout = layout
                questionsCollectionView.isScrollEnabled = false
                questionsCollectionView.backgroundColor = .clear
            }


        
            func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
        
            func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return questions.count
            }
        
            func collectionView(_ collectionView: UICollectionView,
                                cellForItemAt indexPath: IndexPath)
                -> UICollectionViewCell {
        
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "QuestionCell",
                    for: indexPath
                ) as! QuestionCell
        
                cell.configure(questions[indexPath.item])
             
                return cell
            }
    }
    
    
    

extension CallInProgressViewController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {

        // If tapping the SAME tab → allow
        if viewController == self.navigationController {
            return true
        }

        // Show confirmation popup
        let alert = UIAlertController(title: "Are you sure?",
                                      message: "You are currently on a call.",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Stay", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "End", style: .destructive, handler: { _ in
            
            // End call and switch tab
            self.navigationController?.popViewController(animated: true)
            tabBarController.selectedViewController = viewController
        }))

        present(alert, animated: true)
        
        return false  // Stop tab switching until user decides
    }
}
