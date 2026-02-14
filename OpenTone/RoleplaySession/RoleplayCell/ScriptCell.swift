import UIKit


class ScriptCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!


    @IBOutlet weak var guidedDescriptionLabel: UILabel!

 
    @IBOutlet var keyphrases: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.cornerRadius = 20
        containerView.backgroundColor = AppColors.cardBackground
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = AppColors.cardBorder.cgColor
        guidedDescriptionLabel.textColor = AppColors.textPrimary
        keyphrases.textColor = AppColors.textPrimary
    }

    func configure(
       
        guidedText: String,
       
        keyPhrases: [String],
       
        premiumText: String
    ) {
      
        guidedDescriptionLabel.text = guidedText

       

        keyphrases.font = UIFont.systemFont(ofSize: 15)
        keyphrases.numberOfLines = 0
        keyphrases.text? = ""

        for phrase in keyPhrases {

            let label  = "• \(phrase)\n"
            
            keyphrases.text?.append(label)
        }
    }
    
    
}

