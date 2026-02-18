
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

        view.backgroundColor = AppColors.screenBackground
        setupUI()
    }


    func setupUI() {
        
        titleLabel.text = "You are Leaving call Early!"
        titleLabel.textColor = AppColors.textPrimary
        subtitleLabel.text = "Still want to end? Please tell us why"
        subtitleLabel.textColor = AppColors.textSecondary
        
        UIHelper.styleTextField(otherReasonTextField)

        styleReasonButtons()
        
        UIHelper.styleLargeCTAButton(submitButton)
        submitButton.setTitle("Submit", for: .normal)

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: ReportViewController, _) in
            self.styleReasonButtons()
        }
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
            UIHelper.styleOptionButton(button)
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

        guard let reasonText = finalReason, !reasonText.isEmpty else { return }

        let reportReason: ReportReason
        switch reasonText {
        case ReportReason.inappropriateBehavior.rawValue:
            reportReason = .inappropriateBehavior
        case ReportReason.abusiveLanguage.rawValue:
            reportReason = .abusiveLanguage
        case ReportReason.spam.rawValue:
            reportReason = .spam
        case ReportReason.harassment.rawValue:
            reportReason = .harassment
        case ReportReason.fakeProfile.rawValue:
            reportReason = .fakeProfile
        default:
            reportReason = .other
        }

        guard let currentUser = UserDataModel.shared.getCurrentUser() else { return }

        let report = Report(
            id: UUID().uuidString,
            reporterUserID: currentUser.id.uuidString,
            reportedEntityID: "unknown",
            entityType: .callSession,
            reason: reportReason,
            reasonDetails: reportReason == .other ? reasonText : nil,
            message: nil,
            timestamp: Date()
        )

        ReportDataModel.shared.addReport(report)

        dismiss(animated: true)
    }
    
    
    
    @IBAction func reasonTapped(_ sender: UIButton) {
        resetButtons()

        sender.alpha = 0.7
        selectedReason = sender.titleLabel?.text
        dismiss(animated: true)
    }
    
    


}
