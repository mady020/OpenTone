import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    var user: User?

    var isRoleplayInProgress = false
    private var pendingTab: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        

        guard
            let nav = viewControllers?[3] as? UINavigationController,
            let userProfile = nav.viewControllers.first as? ProfileStoryboardCollectionViewController
        else { return }

        userProfile.user = user
        
        guard
            let nav = viewControllers?[0] as? UINavigationController,
            let home = nav.viewControllers.first as? HomeCollectionViewController
        else { return }

        home.currentProgress = user?.streak?.currentCount ?? 0
        home.commitment = user?.streak?.commitment ?? 0
        home.lastTask = nil
        home.isNewUser = true



    }

}
