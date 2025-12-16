import UIKit

final class StatsCell: UICollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet private weak var callsStackView: UIStackView!
    @IBOutlet private weak var callsValueLabel: UILabel!
    @IBOutlet private weak var callsTitleLabel: UILabel!

    @IBOutlet private weak var roleplaysStackView: UIStackView!
    @IBOutlet private weak var roleplaysValueLabel: UILabel!
    @IBOutlet private weak var roleplaysTitleLabel: UILabel!

    @IBOutlet private weak var jamsStackView: UIStackView!
    @IBOutlet private weak var jamsValueLabel: UILabel!
    @IBOutlet private weak var jamsTitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = UIColor(hex: "#FBF8FF")
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 8

        styleValueLabel(callsValueLabel)
        styleValueLabel(roleplaysValueLabel)
        styleValueLabel(jamsValueLabel)

        styleTitleLabel(callsTitleLabel)
        styleTitleLabel(roleplaysTitleLabel)
        styleTitleLabel(jamsTitleLabel)
    }

    private func styleValueLabel(_ label: UILabel) {
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor(hex: "#333333")
        label.textAlignment = .center
    }

    private func styleTitleLabel(_ label: UILabel) {
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
    }
    
    func configure(calls: Int, roleplays: Int, jams: Int) {
        callsValueLabel.text = "\(calls)"
        callsTitleLabel.text = "Calls"

        roleplaysValueLabel.text = "\(roleplays)"
        roleplaysTitleLabel.text = "Roleplays"

        jamsValueLabel.text = "\(jams)"
        jamsTitleLabel.text = "Jam Sessions"
    }
}

