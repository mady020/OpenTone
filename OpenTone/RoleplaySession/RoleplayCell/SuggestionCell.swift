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

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupButtons()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Reset buttons completely
        for button in buttons {
            button.setTitle(nil, for: .normal)
            button.isHidden = true
            button.isEnabled = true
            button.alpha = 1.0
        }
    }

    // MARK: - Setup
    private func setupButtons() {
        for button in buttons {
            button.isHidden = true
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
            button.layer.cornerRadius = 16

            // Remove old targets just in case
            button.removeTarget(nil, action: nil, for: .allEvents)

            // Add target
            button.addTarget(
                self,
                action: #selector(suggestionTapped(_:)),
                for: .touchUpInside
            )
        }
    }

    // MARK: - Configure
    func configure(_ suggestions: [String]) {

        // Hide all first
        for button in buttons {
            button.isHidden = true
        }

        // Show required buttons
        for (index, suggestion) in suggestions.enumerated() {
            guard index < buttons.count else { break }

            let button = buttons[index]
            button.setTitle(suggestion, for: .normal)
            button.isHidden = false
        }
    }

    // MARK: - Action
    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }

        // Optional UX: disable buttons after tap
        for button in buttons {
            button.isEnabled = false
            button.alpha = 0.6
        }

        delegate?.didTapSuggestion(text)
    }
}
