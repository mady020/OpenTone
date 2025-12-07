
import UIKit

class WeekDayCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var letterLabel: UILabel!
    @IBOutlet weak var ringView: CircularProgressView!
    
    override func awakeFromNib() {
           super.awakeFromNib()

           // Round circle for ringView
           ringView.layer.cornerRadius = ringView.frame.size.width / 2
           ringView.clipsToBounds = true

           // Center text
           letterLabel.textAlignment = .center
       }

       // Configure Method
       func configure(with model: DayProgress) {
           letterLabel.text = model.weekdayShort

           // If you have a custom ring view with progress method, use this:
           // ringView.setProgress(model.progress)

           // For now, just change color on selection
           ringView.backgroundColor = model.isSelected ?
               UIColor.purple :
               UIColor.purple.withAlphaComponent(0.3)
       }
   }

