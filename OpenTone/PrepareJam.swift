//
//  PrepareJam.swift
//  OpenTone
//
//  Created by Student on 28/11/25.
//

import Foundation
import UIKit

class PrepareJamViewController: UIViewController{
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    

    override func viewDidLoad() {
           super.viewDidLoad()

           collectionView.delegate = self
           collectionView.dataSource = self
       }
   }

   extension PrepareJamViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

       func numberOfSections(in collectionView: UICollectionView) -> Int {
           return 1   // Timer, Topic, Suggestions
       }

       func collectionView(_ collectionView: UICollectionView,
                           numberOfItemsInSection section: Int) -> Int {

           if section == 0 { return 1 }   // TimerCell
           if section == 1 { return 1 }   // TopicCell
           return 6                      // Suggestions
       }

       func collectionView(_ collectionView: UICollectionView,
                           cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

           if indexPath.section == 0 {
               return collectionView.dequeueReusableCell(withReuseIdentifier: "TimerCell", for: indexPath)
           }

           if indexPath.section == 1 {
               return collectionView.dequeueReusableCell(withReuseIdentifier: "TopicCell", for: indexPath)
           }

           return collectionView.dequeueReusableCell(withReuseIdentifier: "SuggestionCell", for: indexPath)
       }

       // CELL SIZES
       func collectionView(_ collectionView: UICollectionView,
                           layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {

           let width = collectionView.bounds.width - 32

           if indexPath.section == 0 {
               return CGSize(width: width, height: 300)
           }

           if indexPath.section == 1 {
               return CGSize(width: width, height: 100)
           }

           let chipWidth = (width - 10) / 2
           return CGSize(width: chipWidth, height: 44)
       }
}
