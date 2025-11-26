import UIKit

class CallInProgressViewController: UIViewController {

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
    
    
    

    var userProfileImage: UIImage? = nil
 
    var timer: Timer?
    var secondsElapsed: Int = 0


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

        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        

        questionsContainerView.layer.cornerRadius = 20

        profileContainerView.layer.cornerRadius = 20

        endCallButton.layer.cornerRadius = 25
            }
        
            func configureData() {

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

      
        if viewController == self.navigationController {
            return true
        }

        
        let alert = UIAlertController(title: "Are you sure?",
                                      message: "You are currently on a call.",
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Stay", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "End", style: .destructive, handler: { _ in
            
            
            self.navigationController?.popViewController(animated: true)
            tabBarController.selectedViewController = viewController
        }))

        present(alert, animated: true)
        
        return false
    }
}
