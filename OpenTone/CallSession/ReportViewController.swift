
import UIKit

class ReportViewController: UIViewController {


    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!


    @IBOutlet weak var otherReasonTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!


    @IBOutlet weak var reason1Button: UIButton!
    @IBOutlet weak var reason2Button: UIButton!
    @IBOutlet weak var reason3Button: UIButton!
    @IBOutlet weak var reason4Button: UIButton!


    var selectedReason: String?


    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }


    func setupUI() {
        
        titleLabel.text = "You are Leaving call Early!"
        subtitleLabel.text = "Still want to end? Please tell us why"
        
        otherReasonTextField.layer.cornerRadius = 22
        otherReasonTextField.layer.borderWidth = 1
        otherReasonTextField.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        otherReasonTextField.backgroundColor = UIColor(hex: "#FBF8FF")

        styleReasonButtons()

   
        submitButton.layer.cornerRadius = 22
        submitButton.layer.borderWidth = 1
        submitButton.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
        submitButton.backgroundColor = UIColor(hex: "#5B3CC4")
        submitButton.setTitleColor(.white, for: .normal)
    }

    func styleReasonButtons() {
        let buttons = [
            reason1Button,
            reason2Button,
            reason3Button,
            reason4Button
        ]

        buttons.forEach { button in
            button?.layer.cornerRadius = 30
            button?.layer.borderWidth = 1
            button?.layer.borderColor = UIColor(hex: "#E6E3EE").cgColor
            button?.backgroundColor = UIColor(hex: "#FBF8FF")
        }
    }



    
    

    func resetButtons() {
        let buttons = [
            reason1Button,
            reason2Button,
            reason3Button,
            reason4Button
        ]

        buttons.forEach { btn in
            btn?.alpha = 1.0
        }
    }

    @IBAction func submitTapped(_ sender: UIButton) {

        var finalReason = selectedReason

        if selectedReason == "Other reason" {
            finalReason = otherReasonTextField.text
        }

        print("Reason submitted: \(finalReason ?? "None")")

 
    }
    
    
    
    @IBAction func reasonTapped(_ sender: UIButton) {
        resetButtons()

        sender.alpha = 0.7
        selectedReason = sender.titleLabel?.text
        dismiss(animated: true)
    }
    
    


}
