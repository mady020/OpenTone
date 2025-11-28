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
        setupCollectionView()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
}


extension PrepareJamViewController: UICollectionViewDataSource, UICollectionViewDelegate
{
    // MARK: - Sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3   // Timer, Topic, Suggestions
    }

    // MARK: - Items Per Section
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {

        if section == 0 { return 1 }   // TimerCell
        if section == 1 { return 1 }   // TopicCell
        if section == 2 { return 6 }   // Suggestions (temporary static count)

        return 0
    }

    // MARK: - Create Each Cell
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "TimerCell", for: indexPath
            )
        }

        if indexPath.section == 1 {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "TopicCell", for: indexPath
            )
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "SuggestionCell", for: indexPath
        )
        return cell
    }

    // MARK: - Cell Sizes
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = collectionView.bounds.width - 32

        if indexPath.section == 0 {
            return CGSize(width: width, height: 300)  // TimerCell
        }

        if indexPath.section == 1 {
            return CGSize(width: width, height: 100)  // TopicCell
        }

        // Suggestion chips → 2 per row
        let chipWidth = (width - 10) / 2
        return CGSize(width: chipWidth, height: 44)
    }
}
