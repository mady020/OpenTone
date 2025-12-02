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
    
    
    @IBOutlet weak var bulbButton: UIButton!
    
    let allSuggestions: [String] = [
            "Increased Flexibility",
            "Global Collaboration",
            "Work-Life Balance",
            "Productivity Trends",
            "Employee Wellbeing",
            "Hybrid Work Challenges"
        ]

        // Start by showing only first 4 suggestions
        var visibleCount = 4

        // The suggestions actually shown in collection view
        var visibleSuggestions: [String] {
            return Array(allSuggestions.prefix(visibleCount))
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            collectionView.delegate = self
            collectionView.dataSource = self

            // Layout
            let layout = UICollectionViewFlowLayout()
            layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
            layout.minimumInteritemSpacing = 12
            layout.minimumLineSpacing = 15
            collectionView.collectionViewLayout = layout

            // Show or hide bulb
            bulbButton.isHidden = (visibleCount >= allSuggestions.count)
        }

        // MARK: - Bulb button reveals remaining suggestions
        @IBAction func bulbTapped(_ sender: UIButton) {

            // Already showing all? Hide the button
            if visibleCount >= allSuggestions.count {
                bulbButton.isHidden = true
                return
            }

            let startIndex = visibleCount
            visibleCount = allSuggestions.count   // reveal all suggestions

            // Build index paths for new items (2 items)
            var newIndexPaths: [IndexPath] = []
            for i in startIndex..<visibleCount {
                newIndexPaths.append(IndexPath(item: i, section: 2))
            }

            // Insert the new rows
            collectionView.performBatchUpdates({
                collectionView.insertItems(at: newIndexPaths)
            })

            // Hide bulb after showing remaining suggestions
            bulbButton.isHidden = true
        }
    }

    extension PrepareJamViewController:
        UICollectionViewDataSource,
        UICollectionViewDelegateFlowLayout
    {
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 3
        }

        func collectionView(_ collectionView: UICollectionView,
                            numberOfItemsInSection section: Int) -> Int {
            
            if section == 0 { return 1 }
            if section == 1 { return 1 }
            
            // show only visible suggestions
            return visibleSuggestions.count
        }

        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

            if indexPath.section == 0 {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "TimerCell", for: indexPath)
            }

            if indexPath.section == 1 {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "TopicCell", for: indexPath)
            }

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "SuggestionCell",
                for: indexPath
            ) as! SuggestionCell

            cell.configure(text: visibleSuggestions[indexPath.item])
            return cell
        }

        // Sizes
        func collectionView(_ collectionView: UICollectionView,
                            layout collectionViewLayout: UICollectionViewLayout,
                            sizeForItemAt indexPath: IndexPath) -> CGSize {

            let totalWidth = collectionView.bounds.width

            if indexPath.section == 0 {
                return CGSize(width: totalWidth - 30, height: 255)
            }

            if indexPath.section == 1 {
                return CGSize(width: totalWidth, height: 105)
            }

            let leftRightPadding: CGFloat = 15
            let columnSpacing: CGFloat = 12

            let availableWidth = totalWidth - (leftRightPadding * 2) - columnSpacing
            let itemWidth = availableWidth / 2

            return CGSize(width: itemWidth, height: 50)
        }

        func collectionView(_ collectionView: UICollectionView,
                            layout collectionViewLayout: UICollectionViewLayout,
                            minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 15
        }
    }

