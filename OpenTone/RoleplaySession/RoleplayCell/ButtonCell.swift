import UIKit

class ButtonCell: UICollectionViewCell {

    @IBOutlet weak var startButton: UIButton!
    static var reuseId = "ButtonCell";
    var scenarioId: UUID?

    override func awakeFromNib() {
        super.awakeFromNib()
        startButton.isUserInteractionEnabled = false

        startButton.layer.cornerRadius = 28
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
    }
    

}
