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
       
        keyPhrases: [RoleplayMessage]
    ) {
        guidedDescriptionLabel.text = guidedText
        keyphrases.font = UIFont.systemFont(ofSize: 15)
        keyphrases.numberOfLines = 0
        keyphrases.textColor = .label
        keyphrases.text? = ""

        for message in keyPhrases {

            let label  = "• \(message.text)\n"
            
            keyphrases.text?.append(label)
        }
        
    }

}

