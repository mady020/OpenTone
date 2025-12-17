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

    private var selectedTopic: String = ""
    private var allSuggestions: [String] = []

    private var visibleCount = 4
    private var visibleSuggestions: [String] {
        Array(allSuggestions.prefix(visibleCount))
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true

        guard let session = JamSessionDataModel.shared.getActiveSession() else { return }

        selectedTopic = session.topic
        allSuggestions = session.suggestions
        visibleCount = min(4, allSuggestions.count)

        bulbButton.isHidden = visibleCount >= allSuggestions.count
        collectionView.reloadData()
    }

    @IBAction func bulbTapped(_ sender: UIButton) {
        guard visibleCount < allSuggestions.count else {
            bulbButton.isHidden = true
            return
        }

        let startIndex = visibleCount
        visibleCount = allSuggestions.count

        var indexPaths: [IndexPath] = []
        for i in startIndex..<visibleCount {
            indexPaths.append(IndexPath(item: i, section: 2))
        }

        collectionView.performBatchUpdates {
            collectionView.insertItems(at: indexPaths)
        }

        bulbButton.isHidden = true
    }

    @IBAction func startJamTapped(_ sender: UIButton) {
        guard var session = JamSessionDataModel.shared.getActiveSession() else { return }
        session.phase = .speaking
        session.startedSpeakingAt = Date()
        JamSessionDataModel.shared.updateActiveSession(session)
        goToStartJam()
    }

    private func goToStartJam() {
        guard let startVC = storyboard?.instantiateViewController(
            withIdentifier: "StartJamViewController"
        ) as? StartJamViewController else { return }

        navigationController?.pushViewController(startVC, animated: true)
    }
}

extension PrepareJamViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        if section == 1 { return 1 }
        return visibleSuggestions.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        if indexPath.section == 0 {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: "TimerCell",
                for: indexPath
            )
        }

        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TopicCell",
                for: indexPath
            ) as! TopicCell
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

        if indexPath.section == 0 {
            return CGSize(width: width - 30, height: 260)
        }

        if indexPath.section == 1 {
            return CGSize(width: width, height: 105)
        }

        let available = width - 30 - 12
        return CGSize(width: available / 2, height: 50)
    }
}
