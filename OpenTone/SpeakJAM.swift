//
//  SpeakJAM.swift
//  OpenTone
//
//  Created by Student on 27/11/25.
//

import Foundation

import UIKit

final class SpeakJamViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Temporary label so you can see the page is working
        let label = UILabel()
        label.text = "SpeakJam Screen"
        label.font = .boldSystemFont(ofSize: 28)
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
