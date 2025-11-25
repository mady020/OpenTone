//
//  FeedbackMetricsCell.swift
//  OpenTone
//
//  Created by Harshdeep Singh on 25/11/25.
//


import UIKit

class FeedbackMetricsCell: UICollectionViewCell {

    
    // MARK: - Speech
    @IBOutlet weak var speechTitleLabel: UILabel!
    @IBOutlet weak var speechValueLabel: UILabel!
    @IBOutlet weak var speechProgressView: UIProgressView!

    // MARK: - Filler
    @IBOutlet weak var fillerTitleLabel: UILabel!
    @IBOutlet weak var fillerValueLabel: UILabel!
    @IBOutlet weak var fillerProgressView: UIProgressView!

    // MARK: - WPM
    @IBOutlet weak var wpmTitleLabel: UILabel!
    @IBOutlet weak var wpmValueLabel: UILabel!
    @IBOutlet weak var wpmProgressView: UIProgressView!

    // MARK: - Pauses
    @IBOutlet weak var pausesTitleLabel: UILabel!
    @IBOutlet weak var pausesValueLabel: UILabel!
    @IBOutlet weak var pausesProgressView: UIProgressView!

    override func awakeFromNib() {
        super.awakeFromNib()
        styleUI()
        print("FeedbackmetricCell called")
    }

    private func styleUI() {
        // All progress bars same style
        let allBars = [
            speechProgressView,
            fillerProgressView,
            wpmProgressView,
            pausesProgressView
        ]

        allBars.forEach {
            $0?.progressTintColor = .systemPurple
            $0?.trackTintColor = .systemGray5
            $0?.layer.cornerRadius = 3
            $0?.clipsToBounds = true
        }

        // All titles same style
        [
            speechTitleLabel,
            fillerTitleLabel,
            wpmTitleLabel,
            pausesTitleLabel
        ].forEach {
            $0?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        }

        // All value labels same style
        [
            speechValueLabel,
            fillerValueLabel,
            wpmValueLabel,
            pausesValueLabel
        ].forEach {
            $0?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        }
    }

    // MARK: - Configure the Cell
    func configure(
        speechValue: String,
        speechProgress: Float,
        fillerValue: String,
        fillerProgress: Float,
        wpmValue: String,
        wpmProgress: Float,
        pausesValue: String,
        pausesProgress: Float
    ) {
        // Speech
        speechTitleLabel.text = "Speech Length"
        speechValueLabel.text = speechValue
        speechProgressView.progress = speechProgress

        // Filler
        fillerTitleLabel.text = "Filler Words"
        fillerValueLabel.text = fillerValue
        fillerProgressView.progress = fillerProgress

        // WPM
        wpmTitleLabel.text = "Words Per Minute"
        wpmValueLabel.text = wpmValue
        wpmProgressView.progress = wpmProgress

        // Pauses
        pausesTitleLabel.text = "Pauses"
        pausesValueLabel.text = pausesValue
        pausesProgressView.progress = pausesProgress
    }
}
