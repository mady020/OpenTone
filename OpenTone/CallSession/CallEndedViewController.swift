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
        
        
        setupUI()
        
        navigationItem.hidesBackButton = true

    }
}

extension CallEndedViewController {

    func setupUI() {
        cardView.layer.cornerRadius = 24
        cardView.addShadow()
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppColors.cardBorder.cgColor
        cardView.layer.backgroundColor =  AppColors.cardBackground.cgColor
        iconImageView.image = UIImage(systemName: "hand.wave.fill")
        iconImageView.tintColor = AppColors.primary
        titleLabel.text = "Call Ended"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textAlignment = .center
        messageLabel.text = "Great job practicing! Keep up the good work."
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = .darkGray
        styleButton(newCallButton)
        styleButton(reportButton)
        styleMainButton(feedbackButton)
    }

    func styleButton(_ button: UIButton) {
        button.layer.cornerRadius = 18
        button.backgroundColor = AppColors.primary
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
    }

    func styleMainButton(_ button: UIButton) {
        button.layer.cornerRadius = 22
        button.backgroundColor = UIColor(named: "#4A148C")
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
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
        print("Report Pressed")
    }

    @IBAction func feedbackTapped(_ sender: UIButton) {
        print("Feedback Pressed")
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
