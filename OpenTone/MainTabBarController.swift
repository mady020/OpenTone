import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    var user: User?

    var isRoleplayInProgress = false
    private var pendingTab: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        print(user ?? "")
        self.delegate = self
    }

    // Intercept Tab Bar Tap
//    func tabBarController(_ tabBarController: UITabBarController,
//                          shouldSelect viewController: UIViewController) -> Bool {
//        
//        // Only block switching if roleplay is active & user taps a **different tab**
//        if isRoleplayInProgress && viewController != tabBarController.selectedViewController {
//            pendingTab = viewController
//            //showProgressAlert()  // Show Alert Instead of UI Screen
//            return false
//        }
//        
//        return true
//    }

//    func showProgressAlert() {
//        guard let currentVC = selectedViewController else { return }
//
//        let alert = UIAlertController(
//            title: "Save Progress?",
//            message: "Your progress will be lost if you exit this role-play.",
//            preferredStyle: .alert
//        )
//
//        alert.addAction(UIAlertAction(title: "Continue Here", style: .cancel))
//
//        alert.addAction(UIAlertAction(title: "Exit", style: .destructive, handler: { _ in
//            self.isRoleplayInProgress = false
//            if let tab = self.pendingTab {
//                self.selectedViewController = tab
//            }
//            self.pendingTab = nil
//        }))
//
//        currentVC.present(alert, animated: true)
//    }

}
