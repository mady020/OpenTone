import UIKit

class CallEndedViewController: UIViewController {
    

    private let cardBorderColor   = AppColors.cardBorder

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    @IBOutlet weak var newCallButton: UIButton!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var feedbackButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.backgroundColor = AppColors.screenBackground
        setupUI()
        
        navigationItem.hidesBackButton = true

    }
}

extension CallEndedViewController {

    func setupUI() {
        UIHelper.styleCardView(cardView)

        iconImageView.image = UIImage(systemName: "hand.wave.fill")
        iconImageView.tintColor = AppColors.primary
        titleLabel.text = "Call Ended"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textAlignment = .center
        messageLabel.text = "Great job practicing! Keep up the good work."
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = .secondaryLabel
        
        UIHelper.stylePrimaryButton(newCallButton)
        UIHelper.styleSecondaryButton(reportButton)
        UIHelper.styleSecondaryButton(feedbackButton)
    }
}


extension CallEndedViewController {

    @IBAction func newCallTapped(_ sender: UIButton) {
        guard let navigationController = navigationController else { return }

           for vc in navigationController.viewControllers {
               if vc is CallSetupViewController {
                   navigationController.popToViewController(vc, animated: true)
                   return
               }
           }
    }

    @IBAction func reportTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "CallStoryBoard", bundle: nil)
        guard let reportVC = storyboard.instantiateViewController(withIdentifier: "ReportVC") as? ReportViewController else { return }
        reportVC.modalPresentationStyle = .pageSheet
        if let sheet = reportVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(reportVC, animated: true)
    }

    @IBAction func feedbackTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "CallStoryBoard", bundle: nil)
        guard let feedbackVC = storyboard.instantiateViewController(withIdentifier: "Feedback") as? FeedbackCollectionViewController else { return }
        navigationController?.pushViewController(feedbackVC, animated: true)
    }
}


extension UIView {
    func addShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 16
        layer.masksToBounds = false
    }
    
    
     func unwindToCallEnded(_ segue: UIStoryboardSegue) {

        print("Returned to Dashboard")
    }
    
    

}
