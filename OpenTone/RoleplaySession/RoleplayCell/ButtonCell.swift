import UIKit

class ButtonCell: UICollectionViewCell {

    @IBOutlet weak var startButton: UIButton!
    static let reuseId = "ButtonCell"

    var onStartTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        startButton.layer.cornerRadius = 28
        startButton.backgroundColor = AppColors.primary
        startButton.setTitleColor(AppColors.textOnPrimary, for: .normal)
        startButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
    }

    @IBAction func startTapped(_ sender: UIButton) {
        onStartTapped?()
    }
}
