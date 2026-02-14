import UIKit

protocol SuggestionCellDelegate: AnyObject {
    func didTapSuggestion(_ suggestion: String)
}

class SuggestionCell: UITableViewCell {

    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!

    weak var delegate: SuggestionCellDelegate?

    private var buttons: [UIButton] {
        [button1, button2, button3]
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none
        setupButtons()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        for button in buttons {
            button.setTitle(nil, for: .normal)
            button.isHidden = true
            button.isEnabled = true
            button.alpha = 1.0
        }
    }
    private func setupButtons() {
        for button in buttons {
            button.isHidden = true
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
            button.layer.cornerRadius = 16
            button.backgroundColor = AppColors.primary.withAlphaComponent(0.1)
            button.setTitleColor(AppColors.primary, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = AppColors.primary.cgColor
            button.removeTarget(nil, action: nil, for: .allEvents)
            button.addTarget(
                self,
                action: #selector(suggestionTapped(_:)),
                for: .touchUpInside
            )
        }
    }
    func configure(_ suggestions: [String]) {
        for button in buttons {
            button.isHidden = true
        }
        for (index, suggestion) in suggestions.enumerated() {
            guard index < buttons.count else { break }

            let button = buttons[index]
            button.setTitle(suggestion, for: .normal)
            button.isHidden = false
        }
    }
    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        for button in buttons {
            button.isEnabled = false
            button.alpha = 0.6
        }

        delegate?.didTapSuggestion(text)
    }
}
