//
//  ReportViewController.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 21/11/25.
//

import UIKit
//
//  ReportViewController.swift
//  OpenTone
//

import UIKit

class ReportViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!


    @IBOutlet weak var otherReasonTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!

    // Reason Buttons
    @IBOutlet weak var reason1Button: UIButton!
    @IBOutlet weak var reason2Button: UIButton!
    @IBOutlet weak var reason3Button: UIButton!
    @IBOutlet weak var reason4Button: UIButton!
    @IBOutlet weak var reason5Button: UIButton!

    // MARK: - Properties
    var selectedReason: String?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    // MARK: - UI Setup
    func setupUI() {
        
        titleLabel.text = "You are Leaving call Early!"
        subtitleLabel.text = "Still want to end? Please tell us why"

        // Round input field
        otherReasonTextField.layer.cornerRadius = 14
        otherReasonTextField.layer.masksToBounds = true
        otherReasonTextField.backgroundColor = .systemGray6

        styleReasonButtons()

        submitButton.layer.cornerRadius = 22
    }

    func styleReasonButtons() {
        let buttons = [
            reason1Button,
            reason2Button,
            reason3Button,
            reason4Button,
            reason5Button
        ]

        buttons.forEach { button in
            button?.layer.cornerRadius = 30
            button?.setTitleColor(.white, for: .normal)
        }
    }

    // MARK: - Reason Selection
    @IBAction func reasonTapped(_ sender: UIButton) {

        resetButtons()

        sender.alpha = 0.7
        selectedReason = sender.titleLabel?.text
    }

    func resetButtons() {
        let buttons = [
            reason1Button,
            reason2Button,
            reason3Button,
            reason4Button,
            reason5Button
        ]

        buttons.forEach { btn in
            btn?.alpha = 1.0
        }
    }

    @IBAction func submitTapped(_ sender: UIButton) {

        var finalReason = selectedReason

        if selectedReason == "Other reason" {
            finalReason = otherReasonTextField.text
        }

        print("Reason submitted: \(finalReason ?? "None")")

 
    }


    

}
