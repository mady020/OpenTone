import UIKit

class ButtonCell: UICollectionViewCell {

    @IBOutlet weak var startButton: UIButton!
    static let reuseId = "ButtonCell"

    var onStartTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        UIHelper.styleHeroPrimaryButton(
            startButton,
            title: startButton.title(for: .normal) ?? "Start",
            systemIcon: "play.fill"
        )
    }

    @IBAction func startTapped(_ sender: UIButton) {
        onStartTapped?()
    }
}
