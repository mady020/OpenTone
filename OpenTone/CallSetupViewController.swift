//
//  CallSetupViewController.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 16/11/25.
//

import UIKit

enum CallSetupSection: Int, CaseIterable {
    case interests
    case gender
    case english
}

class CallSetupViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var confirmButton: UIButton!

    // MARK: - Data
    var interests: [SelectableItem] = [
        .init(title: "Travel"), .init(title: "Food"), .init(title: "Fitness"),
        .init(title: "Art"), .init(title: "Music"), .init(title: "Movies"),
        .init(title: "Tech"), .init(title: "Reading")
    ]
    
    var genders: [SelectableItem] = [
        .init(title: "Male"), .init(title: "Female"), .init(title: "Other")
    ]
    
    var englishLevels: [SelectableItem] = [
        .init(title: "Beginner"), .init(title: "Intermediate"), .init(title: "Fluent")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmButton.layer.cornerRadius = 25
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.collectionViewLayout = createLayout()
    }
}

//
// MARK: - Compositional Layout
//
extension CallSetupViewController {
    
    func createLayout() -> UICollectionViewLayout {
        
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            
            guard let section = CallSetupSection(rawValue: sectionIndex) else { return nil }
            
            switch section {
                
            case .interests:
                return self.createInterestsSection()
                
            case .gender, .english:
                return self.createSingleRowSection()
            }
        }
    }
    
    // GRID – 3 per row
    func createInterestsSection() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / 3.0),
            heightDimension: .absolute(40)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = .fixed(10)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.boundarySupplementaryItems = [createHeader()]
        
        return section
    }
    
    // Gender & English — single row horizontal items
    func createSingleRowSection() -> NSCollectionLayoutSection {

        // ITEM
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(120),
            heightDimension: .absolute(40)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // GROUP
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(120),
            heightDimension: .absolute(40)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = .fixed(12)   // spacing BETWEEN items

        // SECTION
        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuous

        // ⭐ Spacing SAME as Interests section
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 4,
            bottom: 8,
            trailing: 4
        )

        section.interGroupSpacing = 12

        // Header
        section.boundarySupplementaryItems = [createHeader()]

        return section
    }


    
    // Header for each section
    func createHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(40)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
}

//
// MARK: - UICollectionView DataSource
//
extension CallSetupViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return CallSetupSection.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch CallSetupSection(rawValue: section)! {
        case .interests: return interests.count
        case .gender: return genders.count
        case .english: return englishLevels.count
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "SelectableCell",
            for: indexPath
        ) as! SelectableCell
        
        switch CallSetupSection(rawValue: indexPath.section)! {
        case .interests:
            cell.configure(with: interests[indexPath.item])
            
        case .gender:
            cell.configure(with: genders[indexPath.item])
            
        case .english:
            cell.configure(with: englishLevels[indexPath.item])
        }
        
        return cell
    }
    
    // SECTION HEADER
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "SectionHeaderView",
            for: indexPath
        ) as! SectionHeaderView
        
        switch CallSetupSection(rawValue: indexPath.section)! {
        case .interests: header.titleLabel.text = "Interests"
        case .gender: header.titleLabel.text = "Gender"
        case .english: header.titleLabel.text = "English Level"
        }
        
        return header
    }
}

//
// MARK: - UICollectionView Delegate
//
extension CallSetupViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch CallSetupSection(rawValue: indexPath.section)! {
            
        case .interests:
            interests[indexPath.item].isSelected.toggle()
            collectionView.reloadItems(at: [indexPath])
            
        case .gender:
            for i in 0..<genders.count { genders[i].isSelected = false }
            genders[indexPath.item].isSelected = true
            collectionView.reloadSections(IndexSet(integer: indexPath.section))
            
        case .english:
            for i in 0..<englishLevels.count { englishLevels[i].isSelected = false }
            englishLevels[indexPath.item].isSelected = true
            collectionView.reloadSections(IndexSet(integer: indexPath.section))
        }
    }
}

//
// MARK: - Confirm Button
//
extension CallSetupViewController {
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        
        let selectedInterests = interests.filter { $0.isSelected }.map { $0.title }
        let selectedGender = genders.first(where: { $0.isSelected })?.title
        let selectedEnglish = englishLevels.first(where: { $0.isSelected })?.title
        
        print("Interests:", selectedInterests)
        print("Gender:", selectedGender ?? "None")
        print("English Level:", selectedEnglish ?? "None")
        
        // TODO: Navigate to call screen
    }
}
