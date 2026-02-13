
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
        
        UIHelper.styleTextField(otherReasonTextField)

        styleReasonButtons()
        
        UIHelper.stylePrimaryButton(submitButton)
    }

    func styleReasonButtons() {
        let buttons = [
            reason1Button,
            reason2Button,
            reason3Button,
            reason4Button
        ]

        buttons.forEach { button in
            guard let button = button else { return }
            button.layer.cornerRadius = 20
            button.layer.borderWidth = 1
            button.layer.borderColor = AppColors.cardBorder.cgColor
            button.backgroundColor = AppColors.cardBackground
            button.setTitleColor(AppColors.textPrimary, for: .normal)
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
