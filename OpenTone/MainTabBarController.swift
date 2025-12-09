//
//  MainTabBarController.swift
//  OpenTone
//
//  Created by M S on 09/12/25.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        print(user ?? "")
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
