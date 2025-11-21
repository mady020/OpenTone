//
//  CallInProgressViewController.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 19/11/25.
//
//
//  CallInProgressViewController.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 18/11/25.
//

import UIKit

class CallInProgressViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
  

    @IBOutlet weak var questionsContainerView: UIView!
    @IBOutlet weak var questionsCollectionView: UICollectionView!

    @IBOutlet weak var callStatusLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var endCallButton: UIButton!

    
    @IBOutlet weak var profileContainerView: UIView!
    
    // MARK: - Dynamic Data (pass from previous screen)
    var userName: String = "Harshdeep Singh"
//    var userProfileImage: UIImage? = UIImage(named: "Elon")
 

    var questions: [String] = [  "What technology trends excite you most?",
                                 "What's the last movie you really enjoyed?",
                                 "How do you like to spend your weekends?",
                                 "What's something new you learned recently?"
                                 ]   // <-- dynamically passed

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
                nameLabel.text = userName
                
                statusLabel.text = "Connected"
                timerLabel.text = "0:00"
//                profileImageView.image = userProfileImage
            }
        }
        extension CallInProgressViewController: UICollectionViewDelegate, UICollectionViewDataSource {
        
            func setupCollectionView() {
                questionsCollectionView.delegate = self
                questionsCollectionView.dataSource = self

                let layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .vertical
                layout.minimumLineSpacing = 8
                layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
                
                // FORCE FULL WIDTH CELLS
                layout.estimatedItemSize = CGSize(width: questionsCollectionView.frame.width, height: 10)
                layout.itemSize = UICollectionViewFlowLayout.automaticSize

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
