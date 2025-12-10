//
//  PrepareJamViewController.swift
//  OpenTone
//
//  Created by Student on 28/11/25.
//

import UIKit

class PrepareJamViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bulbButton: UIButton!

    // topic to pass forward (can be set from AI later)
    private(set) var selectedTopic: String = "THE FUTURE OF REMOTE WORK AND CHALLAGNES"

    private let allSuggestions: [String] = [
        "Increased Flexibility",
        "Global Collaboration",
        "Work-Life Balance",
        "Productivity Trends",
        "Employee Wellbeing",
        "Hybrid Work Challenges"
    ]

    private var visibleCount = 4
    private var visibleSuggestions: [String] {
        return Array(allSuggestions.prefix(visibleCount))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self

        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 15
        collectionView.collectionViewLayout = layout

        if selectedTopic.isEmpty {
            selectedTopic = "THE FUTURE OF REMOTE WORK"
        }

        bulbButton.isHidden = (visibleCount >= allSuggestions.count)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }



    @IBAction func bulbTapped(_ sender: UIButton) {
        guard visibleCount < allSuggestions.count else {
            bulbButton.isHidden = true
            return
        }

        let startIndex = visibleCount
        visibleCount = allSuggestions.count

        var newIndexPaths: [IndexPath] = []
        for i in startIndex..<visibleCount {
            newIndexPaths.append(IndexPath(item: i, section: 2))
        }

        collectionView.performBatchUpdates({
            collectionView.insertItems(at: newIndexPaths)
        }, completion: nil)

        bulbButton.isHidden = true
    }

    @IBAction func startJamTapped(_ sender: UIButton) {
        goToSpeechCountdown()
    }

    // NAVIGATION ENTRY FOR SPEECH COUNTDOWN
    private func goToSpeechCountdown() {

        // Ensure topic is selected
        if selectedTopic.isEmpty {
            if let topic = topicFromVisibleCell() { selectedTopic = topic }
        }

        guard let countdownVC = storyboard?.instantiateViewController(
            withIdentifier: "CountdownViewController"
        ) as? CountdownViewController else {
            return
        }

        // Set mode to SPEECH ROUND
        countdownVC.mode = .speech
        
        //  passing topic for start screen
        countdownVC.topicText = selectedTopic

        navigationController?.pushViewController(countdownVC, animated: true)
    }

    // For timer auto-start case
    func timerDidFinish() {
        goToSpeechCountdown()
    }

    // Helper: read topic label
    private func topicFromVisibleCell() -> String? {
        let indexPath = IndexPath(item: 0, section: 1)
        guard let cell = collectionView.cellForItem(at: indexPath) as? TopicCell else {
            return nil
        }
        let t = cell.tileLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (t?.isEmpty == false) ? t : nil
    }
}

extension PrepareJamViewController: TimerCellDelegate {
    // We already have an implementation with the correct signature above,
    // but we add the conformance here so `self` can be assigned to the cell's delegate.
}


extension PrepareJamViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 1 }     // timer
        if section == 1 { return 1 }     // topic
        return visibleSuggestions.count  // suggestions
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TimerCell",
                for: indexPath
            ) as! TimerCellCollectionViewCell

            cell.delegate = self
            return cell
        }

        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TopicCell",
                for: indexPath
            ) as! TopicCell

            if selectedTopic.isEmpty {
                selectedTopic = "THE FUTURE OF REMOTE WORK"
            }
            cell.tileLabel.text = selectedTopic
            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "JamSuggestionCell",
            for: indexPath
        ) as! JamSuggestionCell

        cell.configure(text: visibleSuggestions[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {

        let width = collectionView.bounds.width
        if indexPath.section == 0 { return CGSize(width: width - 30, height: 260) }
        if indexPath.section == 1 { return CGSize(width: width, height: 105) }

        let leftRight: CGFloat = 15
        let spacing: CGFloat = 12
        let available = width - (leftRight * 2) - spacing
        let itemWidth = available / 2
        return CGSize(width: itemWidth, height: 50)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 15
    }
}
