import UIKit

class InterestCell: UICollectionViewCell {
    @IBOutlet var interestLabel: UILabel!
    
    override func awakeFromNib() {
            super.awakeFromNib()
            layer.cornerRadius = 16
            layer.masksToBounds = true
    }
}
