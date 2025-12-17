import UIKit


class ScriptCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!


    @IBOutlet weak var guidedDescriptionLabel: UILabel!

 
    @IBOutlet var keyphrases: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()

        // Card styling
        containerView.layer.cornerRadius = 20
        containerView.backgroundColor = .systemGray6
    }

    func configure(
       
        guidedText: String,
       
        keyPhrases: [String],
       
        premiumText: String
    ) {
        // Assign fixed texts
      
        guidedDescriptionLabel.text = guidedText

       

        keyphrases.font = UIFont.systemFont(ofSize: 15)
        keyphrases.numberOfLines = 0
//        keyphrases.textColor = .label
        keyphrases.text? = ""

        for phrase in keyPhrases {

            let label  = "• \(phrase)\n"
            
            keyphrases.text?.append(label)
        }
    }
    
    
}

